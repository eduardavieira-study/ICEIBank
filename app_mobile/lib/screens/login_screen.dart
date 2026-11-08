import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/marca.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  final void Function(Sessao) aoLogar;

  const LoginScreen({super.key, required this.auth, required this.aoLogar});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  int _agenciaId = 0;
  bool _admin = false;
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final agencia = agencias[_agenciaId];
      final sessao = _admin
          ? await widget.auth.loginAdmin(agencia, _nomeCtrl.text, _senhaCtrl.text)
          : await widget.auth.loginAluno(agencia, _nomeCtrl.text, _senhaCtrl.text);
      widget.aoLogar(sessao);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: IconeMarca()),
                    const SizedBox(height: 12),
                    const Center(child: LogoIceiBank(tamanho: 32)),
                    const SizedBox(height: 32),
                    Text('Agência', style: tema.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        for (final a in agencias)
                          ButtonSegment(value: a.id, label: Text('${a.id}')),
                      ],
                      selected: {_agenciaId},
                      onSelectionChanged: _carregando
                          ? null
                          : (s) => setState(() => _agenciaId = s.first),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: false,
                            icon: Icon(LucideIcons.user, size: 16),
                            label: Text('Aluno')),
                        ButtonSegment(
                            value: true,
                            icon: Icon(LucideIcons.shield, size: 16),
                            label: Text('Admin')),
                      ],
                      selected: {_admin},
                      onSelectionChanged: _carregando
                          ? null
                          : (s) => setState(() {
                                _admin = s.first;
                                _erro = null;
                              }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-nome'),
                      controller: _nomeCtrl,
                      enabled: !_carregando,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _admin ? 'Usuário' : 'Nome',
                        prefixIcon: const Icon(LucideIcons.user, size: 16),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (_admin ? 'Informe o usuário.' : 'Informe o nome.')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('campo-senha'),
                      controller: _senhaCtrl,
                      enabled: !_carregando,
                      obscureText: !_senhaVisivel,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(LucideIcons.lock, size: 16),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                          icon: Icon(_senhaVisivel
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                              size: 16),
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha.' : null,
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        key: const Key('mensagem-erro'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.triangleAlert,
                                size: 16,
                                color: tema.colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_erro!,
                                  style: TextStyle(
                                      color: tema.colorScheme.onErrorContainer)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
