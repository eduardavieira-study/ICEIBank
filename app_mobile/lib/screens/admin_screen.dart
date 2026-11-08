import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/contas_service.dart';
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
      setState(() => _sucesso = 'Conta ${conta['id']} criada para ${conta['nomeAluno']}.');
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

  Widget _caixa(String texto, IconData icone, Color fundo, Color frente, Key chave) {
    return Container(
      key: chave,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icone, color: frente, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: frente))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final agencia = agencias[widget.sessao.agenciaId];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            LogoIceiBank(),
            SizedBox(width: 8),
            Text('/ Administração'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(LucideIcons.logOut, size: 16),
            onPressed: widget.aoSair,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Criar conta · ${agencia.nome}', style: tema.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo-id'),
                controller: _idCtrl,
                enabled: !_carregando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Número da conta', border: OutlineInputBorder()),
                validator: _validarId,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-nome-conta'),
                controller: _nomeCtrl,
                enabled: !_carregando,
                decoration: const InputDecoration(
                    labelText: 'Nome do aluno', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-senha-conta'),
                controller: _senhaCtrl,
                enabled: !_carregando,
                decoration: const InputDecoration(
                    labelText: 'Senha da conta', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a senha.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-saldo'),
                controller: _saldoCtrl,
                enabled: !_carregando,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Saldo inicial', border: OutlineInputBorder()),
                validator: _validarSaldo,
              ),
              if (_erro != null)
                _caixa(_erro!, LucideIcons.triangleAlert, tema.colorScheme.errorContainer,
                    tema.colorScheme.onErrorContainer, const Key('mensagem-erro')),
              if (_sucesso != null)
                _caixa(_sucesso!, LucideIcons.circleCheck,
                    tema.colorScheme.tertiaryContainer,
                    tema.colorScheme.onTertiaryContainer, const Key('mensagem-sucesso')),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _carregando ? null : _criar,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
