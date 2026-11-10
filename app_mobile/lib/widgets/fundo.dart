import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/controlador_tema.dart';
import '../theme/cores.dart';

// Fundo do app: a cor de base do design system com manchas radiais suaves de
// rosa e roxo da marca. Fica atrás de todas as telas (as telas usam Scaffold
// transparente), então o visual é o mesmo em qualquer rota.
class FundoIceiBank extends StatelessWidget {
  final Widget child;

  const FundoIceiBank({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final t = context.tokens;

    // No claro as manchas são mais visíveis; no escuro, só um brilho.
    final rosa = Paleta.secondary[escuro ? 500 : 300]!;
    final roxo = Paleta.primary[escuro ? 500 : 300]!;
    final aRosa = escuro ? 0.12 : 0.24;
    final aRoxo = escuro ? 0.13 : 0.14;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.bg),
        // rosa: canto superior direito
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, -1.05),
              radius: 1.0,
              colors: [
                rosa.withValues(alpha: aRosa),
                rosa.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        // roxo: canto inferior esquerdo
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.0, 1.05),
              radius: 1.0,
              colors: [
                roxo.withValues(alpha: aRoxo),
                roxo.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        // rosa bem leve: lateral esquerda, para o meio da tela não ficar chapado
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.1, -0.15),
              radius: 0.8,
              colors: [
                rosa.withValues(alpha: aRosa * 0.3),
                rosa.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// Botão sol/lua da barra superior: alterna entre claro e escuro, como o
// ThemeToggle do web.
class AlternarTema extends StatelessWidget {
  const AlternarTema({super.key});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('alternar-tema'),
      tooltip: escuro ? 'Ativar modo claro' : 'Ativar modo escuro',
      onPressed: () => controladorTema.alternar(Theme.of(context).brightness),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (filho, anim) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: filho),
        ),
        child: Icon(
          escuro ? LucideIcons.sun : LucideIcons.moon,
          key: ValueKey(escuro),
          size: 18,
          color: escuro ? Paleta.secondary[400] : Paleta.primary[600],
        ),
      ),
    );
  }
}
