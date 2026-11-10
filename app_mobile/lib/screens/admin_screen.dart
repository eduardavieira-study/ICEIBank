import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/contas_service.dart';
import '../widgets/fundo.dart';
import '../theme/cores.dart';
import '../widgets/granulado.dart';
import '../widgets/marca.dart';

// Área do administrador: criação de contas na agência do login. Útil para
// montar a demonstração sem precisar de Invoke-RestMethod.
class AdminScreen extends StatefulWidget {
  final Sessao sessao;
  final ContasService contas;
  final VoidCallback aoSair;
  final VoidCallback aoSessaoExpirada;

  const AdminScreen({
    super.key,
    required this.sessao,
    required this.contas,
    required this.aoSair,
    required this.aoSessaoExpirada,
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
  String? _sucesso;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nomeCtrl.dispose();
    _senhaCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
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
      _sucesso = null;
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
      setState(
        () => _sucesso =
            'Conta ${conta['id']} criada para ${conta['nomeAluno']}.',
      );
      _idCtrl.clear();
      _nomeCtrl.clear();
      _senhaCtrl.clear();
      _saldoCtrl.text = '0';
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

  Widget _caixa(String texto, IconData icone, Color cor, Key chave) {
    return Container(
      key: chave,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(color: cor)),
          ),
        ],
      ),
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Banner(agencia: agencia.nome),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
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
                                  color: Paleta.primary[escuro ? 300 : 600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('campo-id'),
                            controller: _idCtrl,
                            enabled: !_carregando,
                            keyboardType: TextInputType.number,
                            decoration: _decoracao(
                              'Número da conta',
                              LucideIcons.hash,
                            ),
                            validator: _validarId,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('campo-nome-conta'),
                            controller: _nomeCtrl,
                            enabled: !_carregando,
                            decoration: _decoracao(
                              'Nome do aluno',
                              LucideIcons.user,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe o nome.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('campo-senha-conta'),
                            controller: _senhaCtrl,
                            enabled: !_carregando,
                            decoration: _decoracao(
                              'Senha da conta',
                              LucideIcons.lock,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe a senha.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('campo-saldo'),
                            controller: _saldoCtrl,
                            enabled: !_carregando,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decoracao(
                              'Saldo inicial',
                              LucideIcons.wallet,
                            ),
                            validator: _validarSaldo,
                          ),
                          if (_erro != null)
                            _caixa(
                              _erro!,
                              LucideIcons.triangleAlert,
                              tema.colorScheme.error,
                              const Key('mensagem-erro'),
                            ),
                          if (_sucesso != null)
                            _caixa(
                              _sucesso!,
                              LucideIcons.circleCheck,
                              Paleta.accent[escuro ? 400 : 600]!,
                              const Key('mensagem-sucesso'),
                            ),
                          const SizedBox(height: 22),
                          FilledButton(
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Faixa do painel: o mesmo gradiente da marca do cartão de saldo, com
// granulado, só que mais baixa e discreta.
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
                          'Aqui você pode criar a conta de um aluno nesta agência.',
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
