import 'package:flutter/material.dart';

import 'cores.dart';

// Tema do app, alinhado ao design system do frontend web: roxo de marca,
// Sora nos títulos e Inter no texto, cartões com borda e botões discretos.
// Segue o modo claro/escuro do sistema.
class TemaIceiBank {
  static ThemeData claro() => _construir(Brightness.light);
  static ThemeData escuro() => _construir(Brightness.dark);

  static TextStyle _sora(double tamanho, double peso, Color cor) => TextStyle(
        fontFamily: 'Sora',
        fontSize: tamanho,
        fontWeight: FontWeight.values[(peso ~/ 100) - 1],
        fontVariations: [FontVariation('wght', peso)],
        color: cor,
      );

  // As fontes são variáveis: o eixo de peso precisa ser definido de forma
  // explícita, além do FontWeight.
  static TextStyle? _variavel(TextStyle? s) {
    if (s == null) return null;
    final peso = (s.fontWeight ?? FontWeight.w400).value.toDouble();
    return s.copyWith(fontVariations: [FontVariation('wght', peso)]);
  }

  static TextTheme _textos(Brightness b, TokensIceiBank t) {
    final base = ThemeData(brightness: b)
        .textTheme
        .apply(fontFamily: 'Inter', bodyColor: t.text, displayColor: t.text);
    final comVariacoes = base.copyWith(
      // texto digitado nos campos (o web usa text-sm, 14px)
      bodyLarge: _variavel(base.bodyLarge?.copyWith(fontSize: 14)),
      bodyMedium: _variavel(base.bodyMedium),
      bodySmall: _variavel(base.bodySmall)?.copyWith(color: t.textMuted),
      labelLarge: _variavel(base.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: _variavel(base.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      labelSmall: _variavel(base.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
    );
    // Títulos em Sora, como o `font-display` do web.
    return comVariacoes.copyWith(
      displaySmall: _sora(36, 800, t.text),
      headlineLarge: _sora(32, 800, t.text),
      headlineMedium: _sora(28, 800, t.text),
      headlineSmall: _sora(24, 700, t.text),
      titleLarge: _sora(20, 700, t.text),
      titleMedium: _sora(16, 700, t.text),
      titleSmall: _sora(14, 700, t.text),
    );
  }

  static ThemeData _construir(Brightness b) {
    final escuro = b == Brightness.dark;
    final t = escuro ? TokensIceiBank.escuro : TokensIceiBank.claro;

    final esquema = ColorScheme(
      brightness: b,
      primary: Paleta.primary[600]!,
      onPrimary: Colors.white,
      primaryContainer: escuro ? Paleta.primary[900]! : Paleta.primary[100]!,
      onPrimaryContainer: escuro ? Paleta.primary[100]! : Paleta.primary[900]!,
      secondary: Paleta.secondary[500]!,
      onSecondary: Colors.white,
      secondaryContainer: escuro ? Paleta.secondary[900]! : Paleta.secondary[100]!,
      onSecondaryContainer: escuro ? Paleta.secondary[100]! : Paleta.secondary[900]!,
      // verde-água: cor de sucesso do design system
      tertiary: Paleta.accent[500]!,
      onTertiary: Colors.white,
      tertiaryContainer: escuro ? Paleta.accent[900]! : Paleta.accent[100]!,
      onTertiaryContainer: escuro ? Paleta.accent[200]! : Paleta.accent[800]!,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: escuro ? const Color(0xFF3B1218) : const Color(0xFFFEE2E2),
      onErrorContainer: escuro ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
      surface: t.surface,
      onSurface: t.text,
      onSurfaceVariant: t.textMuted,
      surfaceContainerHighest: t.surfaceAlt,
      outline: t.border,
      outlineVariant: t.border,
    );

    OutlineInputBorder campo(Color cor, [double largura = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: cor, width: largura),
        );

    final retangulo8 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final textos = _textos(b, t);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: esquema,
      scaffoldBackgroundColor: t.bg,
      fontFamily: 'Inter',
      textTheme: textos,
      extensions: [t],
      iconTheme: const IconThemeData(size: 18),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: t.headerBg,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: t.border)),
        titleTextStyle: _sora(18, 700, t.text),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(
            color: Paleta.primary[escuro ? 400 : 600], fontSize: 12),
        hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
        errorStyle: const TextStyle(fontSize: 11),
        prefixIconColor: t.textMuted,
        suffixIconColor: t.textMuted,
        border: campo(t.border),
        enabledBorder: campo(t.border),
        disabledBorder: campo(t.border),
        focusedBorder: campo(Paleta.primary[500]!, 2),
        errorBorder: campo(esquema.error),
        focusedErrorBorder: campo(esquema.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Paleta.primary[600],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Paleta.primary[600]!.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(48),
          shape: retangulo8,
          textStyle: _variavel(const TextStyle(
              fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: t.surfaceAlt,
          foregroundColor: t.text,
          side: BorderSide(color: t.border),
          minimumSize: const Size.fromHeight(48),
          shape: retangulo8,
          textStyle: _variavel(const TextStyle(
              fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.textMuted,
          shape: retangulo8,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(BorderSide(color: t.border)),
          backgroundColor: WidgetStateProperty.resolveWith((estados) =>
              estados.contains(WidgetState.selected) ? Paleta.primary[600] : t.surfaceAlt),
          foregroundColor: WidgetStateProperty.resolveWith((estados) =>
              estados.contains(WidgetState.selected) ? Colors.white : t.textMuted),
          iconColor: WidgetStateProperty.resolveWith((estados) =>
              estados.contains(WidgetState.selected) ? Colors.white : t.textMuted),
          textStyle: WidgetStatePropertyAll(_variavel(const TextStyle(
              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600))),
        ),
        selectedIcon: const SizedBox.shrink(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: retangulo8,
      ),
    );
  }
}
