import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/conta.dart';
import '../models/operacao_pendente.dart';
import '../models/sincronizacao.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/conectividade.dart';
import '../services/contas_service.dart';
import '../services/lideranca_service.dart';
import '../theme/cores.dart';
import '../util/formato.dart';
import '../widgets/marca.dart';
import '../widgets/movimentacao_sheet.dart';
import '../widgets/painel_lideranca.dart';
import '../widgets/transferencia_sheet.dart';

// Tela principal do aluno: saldo da conta. Puxar para baixo atualiza.
//
// Funciona offline: depósitos e saques feitos sem conexão vão para uma fila no
// aparelho (com o saldo provisório já na tela) e são sincronizados sozinhos
// quando a agência volta a responder.
class HomeScreen extends StatefulWidget {
  final Sessao sessao;
  final ContasService contas;
  final VoidCallback aoSair;
  final VoidCallback aoSessaoExpirada;
  final LiderancaService? lideranca;
  final MonitorConectividade? conectividade;
  final Duration intervaloSincronizacao;

  const HomeScreen({
    super.key,
    required this.sessao,
    required this.contas,
    required this.aoSair,
    required this.aoSessaoExpirada,
    this.lideranca,
    this.conectividade,
    this.intervaloSincronizacao = intervaloPadraoSincronizacao,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// A rede do aparelho pode estar ligada com a agência fora do ar, e nesse caso o
// monitor de conectividade não avisa de nada. Por isso, enquanto houver algo
// pendente (ou o saldo estiver desatualizado), o app também tenta de tempos em
// tempos. O valor combina com o heartbeat de 3s das agências sem sobrecarregar.
const intervaloPadraoSincronizacao = Duration(seconds: 5);

class _HomeScreenState extends State<HomeScreen> {
  Conta? _conta;
  bool _carregando = true;
  String? _erro;
  // Quando a agência não responde, a tela mostra a última leitura guardada no
  // aparelho. Este campo guarda quando ela foi feita (null = dado ao vivo).
  DateTime? _desatualizadoDesde;
  // Operações feitas sem conexão, ainda não sincronizadas (UI otimista).
  List<OperacaoPendente> _pendentes = [];
  bool _registrouPendente = false; // a última movimentação foi para a fila?
  bool _tentativaSemConexao = false; // ...porque a agência não respondeu?

  bool _sincronizando = false;
  // A agência recusou uma operação por conflito: fica na tela até a pessoa
  // escolher entre reenviar e descartar. Enquanto isso a fila não anda.
  ConflitoSincronizacao? _conflito;
  List<OperacaoPendente> _confirmadas = []; // aviso "sincronizado"
  List<OperacaoRejeitada> _rejeitadas = []; // aviso "não foi possível aplicar"

  Timer? _timer;
  StreamSubscription<bool>? _redeSub;

  // Saldo conhecido + efeito das operações pendentes. É um valor provisório:
  // só vira definitivo quando a agência aceitar as operações.
  double? get _saldoProvisorio => _conta == null
      ? null
      : _pendentes.fold<double>(_conta!.saldo, (s, o) => s + o.efeitoNoSaldo);

  // Inicializado na declaração (e não no initState) para o hot reload não
  // deixar o campo sem valor em uma tela que já estava aberta.
  late final LiderancaService _lideranca =
      widget.lideranca ?? LiderancaService();

  @override
  void initState() {
    super.initState();
    _carregar();
    _timer = Timer.periodic(widget.intervaloSincronizacao, (_) => _aoTempo());
    // Ao a rede voltar, não espera o próximo ciclo; ao cair, mostra na hora.
    _redeSub = widget.conectividade?.aoMudar.listen(
      (temRede) => _carregar(silencioso: temRede),
      onError: (_) {}, // sem o plugin (ex.: testes) o app segue só com o timer
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _redeSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarPendentes() async {
    final pendentes = await widget.contas.listarPendentes(widget.sessao);
    if (mounted) setState(() => _pendentes = pendentes);
  }

  // [silencioso]: leitura em segundo plano (sem spinner nem botões travando),
  // usada pelas tentativas automáticas de reconexão.
  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      await _carregarPendentes();
      final conta = await widget.contas.consultarSaldo(widget.sessao);
      if (!mounted) return;
      setState(() {
        _conta = conta;
        _desatualizadoDesde = null;
      });
      // a agência respondeu: se sobrou algo na fila, manda agora
      if (_pendentes.isNotEmpty) unawaited(_sincronizar());
    } catch (erro) {
      final e = ApiException.de(erro);
      if (!mounted) return;
      if (e.naoAutorizado) {
        // Token expirado ou inválido: volta ao login.
        widget.aoSessaoExpirada();
        return;
      }
      if (erro is ApiException && e.indisponivel) {
        // sem conexão com a agência: usa o último saldo conhecido, se houver
        final emCache = await widget.contas.saldoEmCache(widget.sessao);
        if (!mounted) return;
        if (emCache != null) {
          setState(() {
            _conta = emCache.conta;
            _desatualizadoDesde = emCache.atualizadoEm;
          });
          return;
        }
      }
      if (!silencioso) setState(() => _erro = e.mensagem);
    } finally {
      if (!silencioso && mounted) setState(() => _carregando = false);
    }
  }

  // Tentativa automática periódica: manda a fila ou confere se a agência voltou.
  void _aoTempo() {
    if (_carregando || _sincronizando) return;
    if (_pendentes.isNotEmpty && _conflito == null) {
      unawaited(_sincronizar());
    } else if (_desatualizadoDesde != null) {
      unawaited(_carregar(silencioso: true));
    }
  }

  // Envia a fila à agência. [partirDoVetorAtual] retoma depois de um conflito.
  Future<void> _sincronizar({bool partirDoVetorAtual = false}) async {
    if (_sincronizando || _pendentes.isEmpty) return;
    if (_conflito != null && !partirDoVetorAtual) return;
    setState(() => _sincronizando = true);
    try {
      final r = await widget.contas.sincronizarPendentes(
        widget.sessao,
        partirDoVetorAtual: partirDoVetorAtual,
      );
      if (!mounted) return;
      if (r.naoAutorizado) {
        widget.aoSessaoExpirada();
        return;
      }
      final pendentes = await widget.contas.listarPendentes(widget.sessao);
      final emCache = await widget.contas.saldoEmCache(widget.sessao);
      if (!mounted) return;
      setState(() {
        _pendentes = pendentes;
        if (r.semConexao) {
          _desatualizadoDesde ??= emCache?.atualizadoEm ?? DateTime.now();
        } else {
          // a agência respondeu: o saldo guardado agora é o real dela
          _desatualizadoDesde = null;
          if (emCache != null) _conta = emCache.conta;
        }
        _conflito = r.conflito;
        if (r.sincronizadas.isNotEmpty) _confirmadas = r.sincronizadas;
        if (r.rejeitadas.isNotEmpty) {
          _rejeitadas = [..._rejeitadas, ...r.rejeitadas];
        }
      });
      // A agência respondeu sem conflito: relê o saldo para a tela mostrar o
      // valor real (por exemplo, depois de uma operação recusada, o saldo
      // guardado ainda seria o antigo).
      if (!r.semConexao && r.conflito == null) {
        final atual = await widget.contas.consultarSaldo(widget.sessao);
        if (mounted) setState(() => _conta = atual);
      }
    } catch (_) {
      // erro inesperado: a fila continua intacta e o próximo ciclo tenta de novo
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  Future<void> _reenviarConflito() =>
      _sincronizar(partirDoVetorAtual: true);

  Future<void> _descartarConflito() async {
    final conflito = _conflito;
    if (conflito == null) return;
    await widget.contas.descartarPendente(widget.sessao, conflito.operacao.id);
    final pendentes = await widget.contas.listarPendentes(widget.sessao);
    if (!mounted) return;
    setState(() {
      _pendentes = pendentes;
      _conflito = null;
    });
    // o que sobrou na fila segue, já com o vetor atual da agência
    await _sincronizar(partirDoVetorAtual: true);
  }

  // Tenta na agência; se ela não responder, a operação vai para a fila de
  // pendentes em vez de falhar. Qualquer outro erro (saldo insuficiente, token
  // expirado...) continua sendo mostrado normalmente. Se já há operações na
  // fila, a nova entra atrás delas: furar a fila faria o vetor avançar e
  // transformaria as pendentes em falsos conflitos.
  Future<Conta> _executar(TipoMovimentacao tipo, double valor) async {
    _registrouPendente = false;
    _tentativaSemConexao = false;
    if (_pendentes.isEmpty) {
      try {
        return tipo == TipoMovimentacao.deposito
            ? await widget.contas.depositar(widget.sessao, valor)
            : await widget.contas.sacar(widget.sessao, valor);
      } catch (erro) {
        if (erro is! ApiException || !erro.indisponivel || _conta == null) {
          rethrow;
        }
        _tentativaSemConexao = true;
      }
    }
    if (_conta == null) {
      throw const ApiException('Saldo ainda não carregado. Tente novamente.');
    }
    final pendentes = await widget.contas.registrarPendente(
      widget.sessao,
      tipo == TipoMovimentacao.deposito
          ? TipoOperacao.deposito
          : TipoOperacao.saque,
      valor,
      saldoProvisorio: _saldoProvisorio!,
    );
    _registrouPendente = true;
    if (mounted) setState(() => _pendentes = pendentes);
    return _conta!;
  }

  Future<void> _movimentar(TipoMovimentacao tipo) async {
    final resultado = await mostrarMovimentacao(
      context,
      tipo: tipo,
      executar: (valor) => _executar(tipo, valor),
      aoNaoAutorizado: widget.aoSessaoExpirada,
    );
    if (resultado == null || !mounted) return;
    final nome = tipo == TipoMovimentacao.deposito ? 'Depósito' : 'Saque';
    final valor = formatarReais(resultado.valor);

    if (_registrouPendente) {
      // a agência não respondeu à tentativa direta: a tela passa a mostrar o
      // último saldo conhecido (a conta provisória já está na tela)
      if (_tentativaSemConexao && _desatualizadoDesde == null) {
        final emCache = await widget.contas.saldoEmCache(widget.sessao);
        if (!mounted) return;
        setState(() => _desatualizadoDesde =
            emCache?.atualizadoEm ?? DateTime.now());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tentativaSemConexao || _desatualizadoDesde != null
              ? '$nome de $valor registrado sem conexão. '
                  'Será enviado quando a agência voltar.'
              : '$nome de $valor colocado na fila, atrás das operações '
                  'pendentes.'),
        ),
      );
      return;
    }

    setState(() {
      _conta = resultado.conta;
      _erro = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$nome de $valor realizado!')));
    // depósito e saque não devolvem o vetorAtual: relê o saldo em segundo
    // plano para manter a cópia local (e o vetor) em dia
    try {
      final atual = await widget.contas.consultarSaldo(widget.sessao);
      if (mounted) setState(() => _conta = atual);
    } catch (_) {
      // sem problema: a próxima leitura atualiza
    }
  }

  Future<void> _transferir() async {
    final mensagem = await mostrarTransferencia(
      context,
      sessao: widget.sessao,
      executar: (idDestino, valor) => widget.contas.transferir(
        widget.sessao,
        idDestino: idDestino,
        valor: valor,
      ),
      aoNaoAutorizado: widget.aoSessaoExpirada,
    );
    if (mensagem == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
    // o débito já foi feito na origem: recarrega o saldo
    await _carregar();
  }

  // Liga/desliga a simulação de "sem conexão" (só em builds de debug).
  void _alternarSimulacao(bool ligada) {
    SimulacaoRede.semConexao.value = ligada;
    setState(() {});
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final agencia = agencias[widget.sessao.agenciaId];
    // depósito e saque funcionam offline (vão para a fila); a transferência
    // precisa da agência e não pode furar a fila, então fica bloqueada sem
    // conexão ou com operações pendentes
    final podeMovimentar = _conta != null && !_carregando;
    final online = _desatualizadoDesde == null;

    return Scaffold(
      appBar: AppBar(
        title: const LogoIceiBank(),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(LucideIcons.logOut, size: 16),
            onPressed: widget.aoSair,
          ),
        ],
      ),
      body: Center(
        // limita a largura em telas largas (tablet), como no login
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Olá, ${widget.sessao.nomeAluno ?? 'aluno'}',
                  style: tema.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Conta ${widget.sessao.idConta} · ${agencia.nome}',
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (_erro != null) ...[
                  Container(
                    key: const Key('erro-saldo'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.triangleAlert,
                          size: 16,
                          color: tema.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: TextStyle(
                              color: tema.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _carregando ? null : _carregar,
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    label: const Text('Tentar de novo'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_desatualizadoDesde != null) ...[
                  _AvisoOffline(desde: _desatualizadoDesde!),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _carregando ? null : _carregar,
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    label: const Text('Tentar de novo'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_conflito != null) ...[
                  _CartaoConflito(
                    conflito: _conflito!,
                    ocupado: _sincronizando,
                    aoReenviar: _reenviarConflito,
                    aoDescartar: _descartarConflito,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_rejeitadas.isNotEmpty) ...[
                  _CartaoAviso(
                    chave: const Key('sync-rejeitadas'),
                    icone: LucideIcons.circleX,
                    titulo: 'Operação não aplicada',
                    linhas: [
                      for (final r in _rejeitadas)
                        '${r.operacao.tipo.rotulo} de '
                            '${formatarReais(r.operacao.valor)}: ${r.motivo}',
                    ],
                    erro: true,
                    aoFechar: () => setState(() => _rejeitadas = []),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_confirmadas.isNotEmpty) ...[
                  _CartaoAviso(
                    chave: const Key('sync-concluida'),
                    icone: LucideIcons.circleCheck,
                    titulo: 'Sincronizado com a agência',
                    linhas: [
                      for (final o in _confirmadas)
                        '${o.tipo.rotulo} de ${formatarReais(o.valor)} '
                            'confirmado.',
                    ],
                    aoFechar: () => setState(() => _confirmadas = []),
                  ),
                  const SizedBox(height: 16),
                ],
                _CartaoSaldo(
                  nome: widget.sessao.nomeAluno ?? '',
                  agencia: agencia.nome,
                  saldo: _saldoProvisorio,
                  provisorio: _pendentes.isNotEmpty,
                  carregando: _carregando,
                ),
                if (_pendentes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ListaPendentes(
                    pendentes: _pendentes,
                    sincronizando: _sincronizando,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('acao-depositar'),
                        onPressed: podeMovimentar
                            ? () => _movimentar(TipoMovimentacao.deposito)
                            : null,
                        icon: Icon(TipoMovimentacao.deposito.icone, size: 16),
                        label: const Text('Depositar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('acao-sacar'),
                        onPressed: podeMovimentar
                            ? () => _movimentar(TipoMovimentacao.saque)
                            : null,
                        icon: Icon(TipoMovimentacao.saque.icone, size: 16),
                        label: const Text('Sacar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('acao-transferir'),
                  onPressed: podeMovimentar && online && _pendentes.isEmpty
                      ? _transferir
                      : null,
                  icon: const Icon(LucideIcons.arrowRightLeft, size: 16),
                  label: const Text('Transferir'),
                ),
                const SizedBox(height: 24),
                PainelLideranca(servico: _lideranca),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      key: const Key('simular-offline'),
                      value: SimulacaoRede.semConexao.value,
                      onChanged: _alternarSimulacao,
                      title: Text('Simular sem conexão',
                          style: tema.textTheme.bodyMedium),
                      subtitle: Text(
                        'Só em builds de teste: faz o app agir como se as '
                        'agências estivessem inacessíveis, sem derrubá-las.',
                        style: tema.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Operações aguardando sincronização, cada uma marcada como pendente.
class _ListaPendentes extends StatelessWidget {
  final List<OperacaoPendente> pendentes;
  final bool sincronizando;

  const _ListaPendentes({required this.pendentes, required this.sincronizando});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final ambar = escuro ? const Color(0xFFFCD34D) : const Color(0xFFD97706);

    return Card(
      key: const Key('lista-pendentes'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: ambar),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Aguardando sincronização',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium),
                ),
                if (sincronizando)
                  const SizedBox(
                    key: Key('sincronizando'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Estas operações ainda não foram confirmadas pela agência.',
                style: tema.textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final o in pendentes)
              Padding(
                key: Key('pendente-${o.id}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${o.tipo.rotulo} de ${formatarReais(o.valor)}',
                        style: tema.textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ambar.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('pendente',
                          style: tema.textTheme.bodySmall
                              ?.copyWith(color: ambar)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Aviso simples e dispensável (sincronização concluída ou operação não aplicada).
class _CartaoAviso extends StatelessWidget {
  final Key chave;
  final IconData icone;
  final String titulo;
  final List<String> linhas;
  final bool erro;
  final VoidCallback aoFechar;

  const _CartaoAviso({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.linhas,
    required this.aoFechar,
    this.erro = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final cor = erro
        ? tema.colorScheme.error
        : Paleta.accent[escuro ? 400 : 600]!;

    return Container(
      key: chave,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icone, size: 16, color: cor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: tema.textTheme.titleSmall?.copyWith(color: cor)),
                for (final l in linhas) ...[
                  const SizedBox(height: 2),
                  Text(l, style: tema.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dispensar',
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.x, size: 14),
            onPressed: aoFechar,
          ),
        ],
      ),
    );
  }
}

// Conflito de sincronização (HTTP 409): a conta mudou enquanto o app estava sem
// conexão. Mostra o saldo real e deixa a pessoa decidir o que fazer.
class _CartaoConflito extends StatelessWidget {
  final ConflitoSincronizacao conflito;
  final bool ocupado;
  final VoidCallback aoReenviar;
  final VoidCallback aoDescartar;

  const _CartaoConflito({
    required this.conflito,
    required this.ocupado,
    required this.aoReenviar,
    required this.aoDescartar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final op = conflito.operacao;

    return Container(
      key: const Key('conflito-sync'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangleAlert,
                  size: 16, color: tema.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conflito de sincronização',
                  style: tema.textTheme.titleSmall
                      ?.copyWith(color: tema.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A conta mudou na agência enquanto você estava sem conexão, então '
            'esta operação não foi aplicada automaticamente:',
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 6),
          Text(
            '${op.tipo.rotulo} de ${formatarReais(op.valor)}',
            key: const Key('conflito-operacao'),
            style: tema.textTheme.titleSmall
                ?.copyWith(color: tema.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo real na agência: ${formatarReais(conflito.contaAtual.saldo)}',
            key: const Key('conflito-saldo-real'),
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('reenviar-conflito'),
                  onPressed: ocupado ? null : aoReenviar,
                  child: const Text('Reenviar com o saldo atual'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const Key('descartar-conflito'),
                onPressed: ocupado ? null : aoDescartar,
                child: Text('Descartar',
                    style: TextStyle(color: tema.colorScheme.onErrorContainer)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Aviso de que o saldo mostrado é a última leitura guardada no aparelho.
class _AvisoOffline extends StatelessWidget {
  final DateTime desde;

  const _AvisoOffline({required this.desde});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final ambar = escuro ? const Color(0xFFFCD34D) : const Color(0xFFD97706);

    return Container(
      key: const Key('aviso-offline'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ambar.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ambar.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.wifiOff, size: 16, color: ambar),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sem conexão com a agência. Mostrando o último saldo '
              'conhecido, de ${formatarDataHora(desde)}.',
              style: tema.textTheme.bodySmall?.copyWith(color: ambar),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão com o gradiente da marca, como o BankCard do frontend web.
class _CartaoSaldo extends StatelessWidget {
  final String nome;
  final String agencia;
  final double? saldo;
  final bool provisorio; // há operações pendentes somadas ao saldo
  final bool carregando;

  const _CartaoSaldo({
    required this.nome,
    required this.agencia,
    required this.saldo,
    required this.provisorio,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final branco = Colors.white;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: Paleta.gradienteMarca,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Paleta.primary[600]!.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ICEIBank',
                  style: tema.titleMedium?.copyWith(color: branco),
                ),
                Icon(
                  LucideIcons.landmark,
                  size: 18,
                  color: branco.withValues(alpha: 0.8),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provisorio ? 'Saldo provisório' : 'Saldo disponível',
                  style: tema.bodySmall?.copyWith(
                    color: branco.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                if (saldo != null)
                  Text(
                    formatarReais(saldo!),
                    key: const Key('saldo-valor'),
                    style: tema.headlineMedium?.copyWith(color: branco),
                  )
                else if (carregando)
                  const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Text(
                    '—',
                    style: tema.headlineMedium?.copyWith(color: branco),
                  ),
              ],
            ),
            Text(
              '$nome · $agencia',
              style: tema.bodySmall?.copyWith(
                color: branco.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
