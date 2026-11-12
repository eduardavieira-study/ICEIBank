import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/cores.dart';
import '../widgets/fundo.dart';
import '../widgets/marca.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  final void Function(Sessao) aoLogar;
  final String? aviso;

  const LoginScreen({
    super.key,
    required this.auth,
    required this.aoLogar,
    this.aviso,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _validadeCtrl = TextEditingController();

  bool _testeAberto = false;
  int _agenciaId = 0;
  bool _admin = false;
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _senhaCtrl.dispose();
    _validadeCtrl.dispose();
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
      // vazio = validade padrão do backend
      final validade = kDebugMode
          ? int.tryParse(_validadeCtrl.text.trim())
          : null;
      final sessao = _admin
          ? await widget.auth.loginAdmin(
              agencia,
              _nomeCtrl.text,
              _senhaCtrl.text,
              expiraEmSegundos: validade,
            )
          : await widget.auth.loginAluno(
              agencia,
              _nomeCtrl.text,
              _senhaCtrl.text,
              expiraEmSegundos: validade,
            );
      widget.aoLogar(sessao);
    } catch (erro) {
      final e = ApiException.de(erro);
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final t = context.tokens;

    Widget rotulo(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icone, size: 13, color: Paleta.primary[escuro ? 300 : 600]),
          const SizedBox(width: 6),
          Text(
            texto.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: t.textMuted,
              letterSpacing: 0.8,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // orbes decorativas que dão profundidade ao fundo
          Positioned(
            top: -90,
            left: -70,
            child: _Orbe(
              tamanho: 260,
              cor: Paleta.primary[500]!,
              alpha: escuro ? 0.12 : 0.10,
            ),
          ),
          Positioned(
            bottom: -110,
            right: -80,
            child: _Orbe(
              tamanho: 300,
              cor: Paleta.secondary[500]!,
              alpha: escuro ? 0.12 : 0.12,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Entrada(
                              atraso: 0,
                              child: Column(
                                children: [
                                  const IconeMarca(tamanho: 64),
                                  const SizedBox(height: 16),
                                  const LogoIceiBank(tamanho: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Seu banco, em qualquer agência.',
                                    textAlign: TextAlign.center,
                                    style: tema.textTheme.bodyMedium?.copyWith(
                                      color: t.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.aviso != null) ...[
                              const SizedBox(height: 20),
                              _AvisoAmbar(widget.aviso!),
                            ],
                            const SizedBox(height: 26),
                            _Entrada(
                              atraso: 120,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: t.surface.withValues(
                                    alpha: escuro ? 0.72 : 0.86,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: escuro
                                        ? Paleta.primary[400]!.withValues(
                                            alpha: 0.28,
                                          )
                                        : Colors.white.withValues(alpha: 0.9),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (escuro
                                                  ? Colors.black
                                                  : Paleta.primary[600]!)
                                              .withValues(
                                                alpha: escuro ? 0.5 : 0.16,
                                              ),
                                      blurRadius: 40,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Bem-vindo de volta',
                                      style: tema.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 20),
                                    rotulo(LucideIcons.building2, 'Agência'),
                                    SegmentedButton<int>(
                                      segments: [
                                        for (final a in agencias)
                                          ButtonSegment(
                                            value: a.id,
                                            label: Text('${a.id}'),
                                          ),
                                      ],
                                      selected: {_agenciaId},
                                      onSelectionChanged: _carregando
                                          ? null
                                          : (s) => setState(
                                              () => _agenciaId = s.first,
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    rotulo(
                                      LucideIcons.userRound,
                                      'Entrar como',
                                    ),
                                    SegmentedButton<bool>(
                                      showSelectedIcon: false,
                                      segments: const [
                                        ButtonSegment(
                                          value: false,
                                          icon: Icon(
                                            LucideIcons.user,
                                            size: 16,
                                          ),
                                          label: Text('Aluno'),
                                        ),
                                        ButtonSegment(
                                          value: true,
                                          icon: Icon(
                                            LucideIcons.shield,
                                            size: 16,
                                          ),
                                          label: Text('Admin'),
                                        ),
                                      ],
                                      selected: {_admin},
                                      onSelectionChanged: _carregando
                                          ? null
                                          : (s) => setState(() {
                                              _admin = s.first;
                                              _erro = null;
                                            }),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      key: const Key('campo-nome'),
                                      controller: _nomeCtrl,
                                      enabled: !_carregando,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: _admin ? 'Usuário' : 'Nome',
                                        prefixIcon: const Icon(
                                          LucideIcons.user,
                                          size: 17,
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? (_admin
                                                ? 'Informe o usuário.'
                                                : 'Informe o nome.')
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
                                        prefixIcon: const Icon(
                                          LucideIcons.lock,
                                          size: 17,
                                        ),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          tooltip: _senhaVisivel
                                              ? 'Ocultar senha'
                                              : 'Mostrar senha',
                                          icon: Icon(
                                            _senhaVisivel
                                                ? LucideIcons.eyeOff
                                                : LucideIcons.eye,
                                            size: 17,
                                          ),
                                          onPressed: () => setState(
                                            () =>
                                                _senhaVisivel = !_senhaVisivel,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Informe a senha.'
                                          : null,
                                    ),
                                    // Só em builds de desenvolvimento: em produção, a
                                    // pessoa não deve escolher a validade do token.
                                    if (kDebugMode) ...[
                                      const SizedBox(height: 12),
                                      _ConfigTeste(
                                        aberto: _testeAberto,
                                        aoAlternar: () => setState(
                                          () => _testeAberto = !_testeAberto,
                                        ),
                                        controller: _validadeCtrl,
                                        habilitado: !_carregando,
                                      ),
                                    ],
                                    if (_erro != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        key: const Key('mensagem-erro'),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              tema.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.triangleAlert,
                                              size: 16,
                                              color: tema
                                                  .colorScheme
                                                  .onErrorContainer,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _erro!,
                                                style: TextStyle(
                                                  color: tema
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 22),
                                    FilledButton(
                                      onPressed: _carregando ? null : _entrar,
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Entrar'),
                                                SizedBox(width: 8),
                                                Icon(
                                                  LucideIcons.arrowRight,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Entrada(
                              atraso: 240,
                              child: Text(
                                'ICEI · PUC Minas',
                                textAlign: TextAlign.center,
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: t.textMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // por último, para ficar por cima da área de rolagem e receber o toque
                const Positioned(top: 4, right: 8, child: AlternarTema()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mancha circular suave usada como decoração do fundo.
class _Orbe extends StatelessWidget {
  final double tamanho;
  final Color cor;
  final double alpha;

  const _Orbe({required this.tamanho, required this.cor, required this.alpha});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            cor.withValues(alpha: alpha),
            cor.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

// Entrada suave: aparece subindo levemente, com atraso opcional (ms).
class _Entrada extends StatelessWidget {
  final int atraso;
  final Widget child;

  const _Entrada({required this.atraso, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 500 + atraso;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(atraso / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, filho) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 18),
          child: filho,
        ),
      ),
      child: child,
    );
  }
}

// Aviso não-erro (ex.: sessão expirada). Mesmo estilo âmbar dos avisos do web:
// bg-amber-500/10, borda amber-500/30, texto amber-600 (amber-300 no escuro).
class _AvisoAmbar extends StatelessWidget {
  final String texto;

  const _AvisoAmbar(this.texto);

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final cor = escuro ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
    return Container(
      key: const Key('aviso-login'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, size: 16, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(color: cor)),
          ),
        ],
      ),
    );
  }
}

// Equivalente ao bloco "Configuração de Testes (Validade do Token)" do login
// web: permite gerar um token de poucos segundos para testar o 401. Fica
// recolhido por padrão para não poluir a tela.
class _ConfigTeste extends StatelessWidget {
  final bool aberto;
  final VoidCallback aoAlternar;
  final TextEditingController controller;
  final bool habilitado;

  const _ConfigTeste({
    required this.aberto,
    required this.aoAlternar,
    required this.controller,
    required this.habilitado,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final cor = escuro ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
    final ambar = const Color(0xFFF59E0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          key: const Key('alternar-config-teste'),
          onPressed: aoAlternar,
          icon: Icon(
            aberto ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 14,
          ),
          label: const Text('Configuração de testes'),
        ),
        if (aberto)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ambar.withValues(alpha: 0.1),
              border: Border.all(color: ambar.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.triangleAlert, size: 12, color: cor),
                    const SizedBox(width: 6),
                    Text(
                      'Validade do token',
                      style: tema.textTheme.labelSmall?.copyWith(color: cor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('campo-validade'),
                  controller: controller,
                  enabled: habilitado,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Segundos (vazio = 1800)',
                  ),
                  validator: (v) {
                    final texto = (v ?? '').trim();
                    if (texto.isEmpty) return null;
                    final segundos = int.tryParse(texto);
                    return (segundos == null || segundos <= 0)
                        ? 'Informe segundos maiores que zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Use um valor curto (ex.: 15) para testar a expiração da sessão.',
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
