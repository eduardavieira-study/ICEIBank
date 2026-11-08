import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/conta.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/contas_service.dart';
import '../theme/cores.dart';
import '../util/formato.dart';
import '../widgets/marca.dart';
import '../widgets/movimentacao_sheet.dart';

// Tela principal do aluno: saldo da conta. Puxar para baixo atualiza.
class HomeScreen extends StatefulWidget {
  final Sessao sessao;
  final ContasService contas;
  final VoidCallback aoSair;

  const HomeScreen({
    super.key,
    required this.sessao,
    required this.contas,
    required this.aoSair,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Conta? _conta;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final conta = await widget.contas.consultarSaldo(widget.sessao);
      if (!mounted) return;
      setState(() => _conta = conta);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.naoAutorizado) {
        // Token expirado ou inválido: volta ao login.
        widget.aoSair();
        return;
      }
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _movimentar(TipoMovimentacao tipo) async {
    final resultado = await mostrarMovimentacao(
      context,
      tipo: tipo,
      executar: (valor) => tipo == TipoMovimentacao.deposito
          ? widget.contas.depositar(widget.sessao, valor)
          : widget.contas.sacar(widget.sessao, valor),
      aoNaoAutorizado: widget.aoSair,
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _conta = resultado.conta;
      _erro = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tipo == TipoMovimentacao.deposito ? 'Depósito' : 'Saque'} de '
          '${formatarReais(resultado.valor)} realizado!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final agencia = agencias[widget.sessao.agenciaId];
    final podeMovimentar = _conta != null && !_carregando;

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
                _CartaoSaldo(
                  nome: widget.sessao.nomeAluno ?? '',
                  agencia: agencia.nome,
                  saldo: _conta?.saldo,
                  carregando: _carregando,
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Cartão com o gradiente da marca, como o BankCard do frontend web.
class _CartaoSaldo extends StatelessWidget {
  final String nome;
  final String agencia;
  final double? saldo;
  final bool carregando;

  const _CartaoSaldo({
    required this.nome,
    required this.agencia,
    required this.saldo,
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
                  'Saldo disponível',
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
