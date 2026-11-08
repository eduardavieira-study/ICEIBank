import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/cores.dart';

// Equivalente ao componente Logo.jsx do frontend: "ICEI" + "Bank" em
// destaque (roxo mais claro no modo escuro, como no `dark:text-primary-400`).
class LogoIceiBank extends StatelessWidget {
  final double tamanho;

  const LogoIceiBank({super.key, this.tamanho = 20});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final estilo = Theme.of(context).textTheme.titleLarge!.copyWith(
          fontSize: tamanho,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          letterSpacing: -0.5,
        );
    return Text.rich(
      TextSpan(
        text: 'ICEI',
        style: estilo,
        children: [
          TextSpan(
            text: 'Bank',
            style: TextStyle(color: Paleta.primary[escuro ? 400 : 600]),
          ),
        ],
      ),
    );
  }
}

// Ícone da marca sobre o gradiente roxo -> rosa (uso pontual, como no web).
class IconeMarca extends StatelessWidget {
  final double tamanho;

  const IconeMarca({super.key, this.tamanho = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        gradient: Paleta.gradienteMarca,
        borderRadius: BorderRadius.circular(tamanho * 0.25),
      ),
      child: Icon(LucideIcons.landmark, color: Colors.white, size: tamanho * 0.4),
    );
  }
}
