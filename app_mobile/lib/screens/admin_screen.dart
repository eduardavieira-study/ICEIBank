import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/conta.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/contas_service.dart';
import '../theme/cores.dart';
import '../widgets/animacoes.dart';
import '../widgets/aviso.dart';
import '../widgets/fundo.dart';
import '../widgets/granulado.dart';
import '../widgets/marca.dart';
import '../util/formato.dart';

// Área do administrador: escolhe a agência (sem precisar sair), vê as contas
// já criadas nela e cadastra novos alunos.
class AdminScreen extends StatefulWidget {
  final Sessao sessao;
  final ContasService contas;
  final VoidCallback aoSair;
  final VoidCallback aoSessaoExpirada;
  final ValueChanged<int>? aoTrocarAgencia;

  const AdminScreen({
    super.key,
    required this.sessao,
    required this.contas,
    required this.aoSair,
    required this.aoSessaoExpirada,
    this.aoTrocarAgencia,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController(text: '0');

  bool _carregando = false;
  String? _erro;

  List<Conta>? _lista;
  bool _carregandoLista = true;
  String? _erroLista;
  int _leitura = 0; // descarta respostas de uma agência que já ficou para trás

  @override
  void initState() {
    super.initState();
    _carregarLista();
  }

  @override
  void didUpdateWidget(AdminScreen antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.sessao.agenciaId != widget.sessao.agenciaId) {
      // outra agência: o formulário e a lista recomeçam do zero
      _idCtrl.clear();
      _erro = null;
      _formKey.currentState?.reset();
      _carregarLista();
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nomeCtrl.dispose();
    _senhaCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarLista() async {
    final leitura = ++_leitura;
    setState(() {
      _carregandoLista = true;
      _erroLista = null;
      _lista = null;
    });
    try {
      final lista = await widget.contas.listarContas(widget.sessao);
      if (!mounted || leitura != _leitura) return;
      setState(() => _lista = lista);
    } catch (erro) {
      final e = ApiException.de(erro);
      if (!mounted || leitura != _leitura) return;
      if (e.naoAutorizado) {
        widget.aoSessaoExpirada();
        return;
      }
      setState(() => _erroLista = e.mensagem);
    } finally {
      if (mounted && leitura == _leitura) {
        setState(() => _carregandoLista = false);
      }
    }
  }

  // Próximo número livre que pertence a esta agência (id % 3 == agência).
  String _dicaId() {
    final ag = widget.sessao.agenciaId;
    final usados = {for (final c in _lista ?? const <Conta>[]) c.id};
    var id = ag;
    while (usados.contains(id)) {
      id += numeroAgencias;
    }
    return 'Desta agência: $ag,${ag + numeroAgencias}, ${ag + 2 * numeroAgencias}… '
        '(sugestão livre: $id)';
  }

  String? _validarId(String? v) {
    final id = int.tryParse(v?.trim() ?? '');
    if (id == null || id < 0) return 'Informe um número de conta válido.';
    if (id % numeroAgencias != widget.sessao.agenciaId) {
      return 'Esta agência só aceita contas com id % $numeroAgencias == '
          '${widget.sessao.agenciaId}.';
    }
    return null;
  }

  String? _validarSaldo(String? v) {
    final saldo = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (saldo == null || saldo < 0) return 'Informe um saldo válido.';
    return null;
  }

  Future<void> _criar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final conta = await widget.contas.criarConta(
        widget.sessao,
        id: int.parse(_idCtrl.text.trim()),
        nomeAluno: _nomeCtrl.text,
        senha: _senhaCtrl.text,
        saldoInicial: double.parse(_saldoCtrl.text.trim().replaceAll(',', '.')),
      );
      if (!mounted) return;
      Aviso.mostrar(
        context,
        'Conta ${conta['id']} criada para ${conta['nomeAluno']}.',
      );
      _idCtrl.clear();
      _nomeCtrl.clear();
      _senhaCtrl.clear();
      _saldoCtrl.text = '0';
      _formKey.currentState?.reset();
      FocusScope.of(context).unfocus();
      _carregarLista();
    } catch (erro) {
      final e = ApiException.de(erro);
      if (!mounted) return;
      if (e.naoAutorizado) {
        // Token expirado ou inválido: volta ao login.
        widget.aoSessaoExpirada();
        return;
      }
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  InputDecoration _decoracao(String rotulo, IconData icone) => InputDecoration(
    labelText: rotulo,
    border: const OutlineInputBorder(),
    prefixIcon: Icon(icone, size: 17),
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final agencia = agencias[widget.sessao.agenciaId];
    final t = context.tokens;
    final destaque = Paleta.primary[escuro ? 300 : 600]!;

    return Scaffold(
      appBar: AppBar(
        title: const LogoIceiBank(),
        actions: [
          const AlternarTema(),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(LucideIcons.logOut, size: 18),
            onPressed: widget.aoSair,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: RefreshIndicator(
            onRefresh: _carregarLista,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Entrada(child: _Banner(agencia: agencia.nome)),
                const SizedBox(height: 16),
                Entrada(
                  ordem: 1,
                  child: _SeletorAgencia(
                    selecionada: agencia.id,
                    aoEscolher: widget.aoTrocarAgencia,
                  ),
                ),
                const SizedBox(height: 14),
                Entrada(
                  ordem: 2,
                  child: _Resumo(lista: _lista, carregando: _carregandoLista),
                ),
                const SizedBox(height: 14),
                Entrada(
                  ordem: 3,
                  child: Card(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: t.surfaceAlt,
                                    border: Border.all(color: t.border),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.userPlus,
                                    size: 19,
                                    color: destaque,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Criar conta · ${agencia.nome}',
                                        style: tema.textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Cadastre um novo aluno nesta agência.',
                                        style: tema.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _campos(tema, escuro),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Entrada(
                  ordem: 4,
                  child: Row(
                    children: [
                      Text('Contas', style: tema.textTheme.titleMedium),
                      const SizedBox(width: 8),
                      if (_lista != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: destaque.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_lista!.length}',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: destaque,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${agencia.id}-$_carregandoLista-$_erroLista',
                    ),
                    child: _listaContas(tema, t),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campos(ThemeData tema, bool escuro) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('campo-id'),
            controller: _idCtrl,
            enabled: !_carregando,
            keyboardType: TextInputType.number,
            decoration: _decoracao(
              'Número da conta',
              LucideIcons.hash,
            ).copyWith(helperText: _dicaId()),
            validator: _validarId,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo-nome-conta'),
            controller: _nomeCtrl,
            enabled: !_carregando,
            decoration: _decoracao('Nome do aluno', LucideIcons.user),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo-senha-conta'),
            controller: _senhaCtrl,
            enabled: !_carregando,
            decoration: _decoracao('Senha da conta', LucideIcons.lock),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe a senha.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo-saldo'),
            controller: _saldoCtrl,
            enabled: !_carregando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoracao('Saldo inicial', LucideIcons.wallet),
            validator: _validarSaldo,
          ),
          if (_erro != null)
            Container(
              key: const Key('mensagem-erro'),
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tema.colorScheme.error.withValues(alpha: 0.12),
                border: Border.all(
                  color: tema.colorScheme.error.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    color: tema.colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _erro!,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Pressionavel(
            child: FilledButton(
              onPressed: _carregando ? null : _criar,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.userPlus, size: 18),
                        SizedBox(width: 8),
                        Text('Criar conta'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaContas(ThemeData tema, TokensIceiBank t) {
    if (_carregandoLista) {
      return Column(
        key: const Key('lista-carregando'),
        children: [for (var i = 0; i < 3; i++) const _LinhaEsqueleto()],
      );
    }
    if (_erroLista != null) {
      return Column(
        key: const Key('lista-erro'),
        children: [
          Text(
            _erroLista!,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _carregarLista,
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('Tentar de novo'),
          ),
        ],
      );
    }
    final lista = _lista ?? const <Conta>[];
    if (lista.isEmpty) {
      return Padding(
        key: const Key('lista-vazia'),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(LucideIcons.users, size: 26, color: t.textMuted),
            const SizedBox(height: 10),
            Text(
              'Nenhuma conta nesta agência ainda.',
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    return Column(
      key: const Key('lista-contas'),
      children: [
        for (var i = 0; i < lista.length; i++)
          Entrada(
            key: ValueKey('${widget.sessao.agenciaId}-${lista[i].id}'),
            ordem: i,
            child: _LinhaConta(conta: lista[i]),
          ),
      ],
    );
  }
}

// Seletor de agência: rótulo claro e três opções sempre visíveis; a escolhida
// fica preenchida. Sem animações: o que está ativo salta aos olhos.
class _SeletorAgencia extends StatelessWidget {
  final int selecionada;
  final ValueChanged<int>? aoEscolher;

  const _SeletorAgencia({required this.selecionada, required this.aoEscolher});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trocar de agência', style: tema.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < numeroAgencias; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: i == selecionada
                    ? FilledButton(
                        key: Key('agencia-$i'),
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: Paleta.primary[600],
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text('Agência $i'),
                      )
                    : OutlinedButton(
                        key: Key('agencia-$i'),
                        onPressed: aoEscolher == null
                            ? null
                            : () => aoEscolher!(i),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: t.text,
                        ),
                        child: Text('Agência $i'),
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Dois números discretos: quantas contas e quanto dinheiro há na agência.
class _Resumo extends StatelessWidget {
  final List<Conta>? lista;
  final bool carregando;

  const _Resumo({required this.lista, required this.carregando});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final t = context.tokens;
    final total = lista?.fold<double>(0, (s, c) => s + c.saldo);

    Widget bloco(String rotulo, Widget valor) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: tema.textTheme.bodySmall),
            const SizedBox(height: 4),
            valor,
          ],
        ),
      ),
    );

    final estilo = tema.textTheme.titleLarge;
    return Row(
      children: [
        bloco(
          'Contas',
          lista == null
              ? Text('—', style: estilo)
              : Text(
                  '${lista!.length}',
                  key: const Key('total-contas'),
                  style: estilo,
                ),
        ),
        const SizedBox(width: 12),
        bloco(
          'Saldo total',
          total == null
              ? Text('—', style: estilo)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ReaisAnimado(valor: total, estilo: estilo),
                ),
        ),
      ],
    );
  }
}

class _LinhaConta extends StatelessWidget {
  final Conta conta;

  const _LinhaConta({required this.conta});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final t = context.tokens;
    final escuro = tema.brightness == Brightness.dark;
    final inicial = conta.nomeAluno.trim().isEmpty
        ? '?'
        : conta.nomeAluno.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        key: Key('conta-${conta.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Paleta.primary[escuro ? 300 : 600]!.withValues(
                  alpha: 0.12,
                ),
              ),
              child: Text(
                inicial,
                style: tema.textTheme.titleSmall?.copyWith(
                  color: Paleta.primary[escuro ? 300 : 600],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conta.nomeAluno,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleSmall,
                  ),
                  Text('Conta ${conta.id}', style: tema.textTheme.bodySmall),
                ],
              ),
            ),
            Text(formatarReais(conta.saldo), style: tema.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _LinhaEsqueleto extends StatelessWidget {
  const _LinhaEsqueleto();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 62,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// Faixa do painel: gradiente da marca com o título em destaque.
class _Banner extends StatelessWidget {
  final String agencia;

  const _Banner({required this.agencia});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: Paleta.gradienteMarca,
        boxShadow: [
          BoxShadow(
            color: Paleta.primary[600]!.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Granulado(),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agencia,
                          style: tema.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Painel do administrador',
                          style: tema.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Veja as contas desta agência e cadastre novos alunos.',
                          style: tema.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.shieldCheck,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 30,
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
