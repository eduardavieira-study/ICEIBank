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
    final base = ThemeData(brightness: b).textTheme
        .apply(fontFamily: 'Inter', bodyColor: t.text, displayColor: t.text);
    final comVariacoes = base.copyWith(
      // texto digitado nos campos (o web usa text-sm, 14px)
      bodyLarge: _variavel(base.bodyLarge?.copyWith(fontSize: 14)),
      bodyMedium: _variavel(base.bodyMedium),
      bodySmall: _variavel(base.bodySmall)?.copyWith(color: t.textMuted),
      labelLarge: _variavel(
        base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      labelMedium: _variavel(
        base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      labelSmall: _variavel(
        base.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
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
      secondaryContainer: escuro
          ? Paleta.secondary[900]!
          : Paleta.secondary[100]!,
      onSecondaryContainer: escuro
          ? Paleta.secondary[100]!
          : Paleta.secondary[900]!,
      // verde-água: cor de sucesso do design system
      tertiary: Paleta.accent[500]!,
      onTertiary: Colors.white,
      tertiaryContainer: escuro ? Paleta.accent[900]! : Paleta.accent[100]!,
      onTertiaryContainer: escuro ? Paleta.accent[200]! : Paleta.accent[800]!,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: escuro
          ? const Color(0xFF3B1218)
          : const Color(0xFFFEE2E2),
      onErrorContainer: escuro
          ? const Color(0xFFFCA5A5)
          : const Color(0xFFB91C1C),
      surface: t.surface,
      onSurface: t.text,
      onSurfaceVariant: t.textMuted,
      surfaceContainerHighest: t.surfaceAlt,
      outline: t.border,
      outlineVariant: t.border,
    );

    OutlineInputBorder campo(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cor, width: largura),
        );

    final botao = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    // sombra arroxeada e bem suave no claro; preta no escuro
    final sombra = escuro
        ? Colors.black.withValues(alpha: 0.5)
        : Paleta.primary[600]!.withValues(alpha: 0.12);
    final estiloBotao = _variavel(
      const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );
    final textos = _textos(b, t);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: esquema,
      // transparente: quem desenha o fundo é o FundoIceiBank (radiais rosadas)
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Inter',
      textTheme: textos,
      extensions: [t],
      iconTheme: const IconThemeData(size: 18),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: t.headerBg.withValues(alpha: escuro ? 0.78 : 0.72),
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: t.border)),
        titleTextStyle: _sora(18, 700, t.text),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 3,
        shadowColor: sombra,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface.withValues(alpha: escuro ? 0.6 : 0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: Paleta.primary[escuro ? 400 : 600],
          fontSize: 12,
        ),
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
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(botao),
          textStyle: WidgetStatePropertyAll(estiloBotao),
          iconSize: const WidgetStatePropertyAll(18),
          foregroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? Colors.white70
                : Colors.white,
          ),
          // roxo da marca; ao pressionar, escurece um degrau
          backgroundColor: WidgetStateProperty.resolveWith((e) {
            if (e.contains(WidgetState.disabled)) {
              return Paleta.primary[escuro ? 700 : 600]!.withValues(
                alpha: 0.45,
              );
            }
            if (e.contains(WidgetState.pressed)) return Paleta.primary[700];
            if (e.contains(WidgetState.hovered)) return Paleta.primary[500];
            return Paleta.primary[600];
          }),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.12),
          ),
          // brilho roxo embaixo do botão (some quando desativado)
          elevation: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? 0
                : e.contains(WidgetState.pressed)
                ? 1
                : 6,
          ),
          shadowColor: WidgetStatePropertyAll(
            Paleta.primary[escuro ? 400 : 600]!.withValues(alpha: 0.55),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(botao),
          textStyle: WidgetStatePropertyAll(estiloBotao),
          iconSize: const WidgetStatePropertyAll(18),
          backgroundColor: WidgetStateProperty.resolveWith((e) {
            if (e.contains(WidgetState.disabled)) {
              return t.surface.withValues(alpha: 0.4);
            }
            if (e.contains(WidgetState.pressed)) {
              return Paleta.primary[escuro ? 900 : 100]!.withValues(alpha: 0.9);
            }
            return t.surface.withValues(alpha: escuro ? 0.7 : 0.85);
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? t.textMuted.withValues(alpha: 0.6)
                : t.text,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? t.textMuted.withValues(alpha: 0.5)
                : Paleta.primary[escuro ? 300 : 600],
          ),
          side: WidgetStateProperty.resolveWith(
            (e) => BorderSide(
              color:
                  e.contains(WidgetState.pressed) ||
                      e.contains(WidgetState.focused)
                  ? Paleta.primary[400]!
                  : t.border,
              width: 1.2,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            Paleta.primary[500]!.withValues(alpha: 0.08),
          ),
          elevation: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled) ? 0 : 2,
          ),
          shadowColor: WidgetStatePropertyAll(sombra),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: escuro ? Paleta.primary[300] : Paleta.primary[600],
          shape: botao,
          textStyle: estiloBotao,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: t.border,
        modalBackgroundColor: t.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Paleta.primary[escuro ? 400 : 600],
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(BorderSide(color: t.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Paleta.primary[600]
                : t.surfaceAlt,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Colors.white
                : t.textMuted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Colors.white
                : t.textMuted,
          ),
          textStyle: WidgetStatePropertyAll(
            _variavel(
              const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        selectedIcon: const SizedBox.shrink(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: escuro ? Paleta.primary[800] : Paleta.primary[950],
        contentTextStyle: _variavel(
          const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        shape: botao,
      ),
    );
  }
}
