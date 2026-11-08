import 'package:flutter/material.dart';

// Espelho de frontend/tailwind.config.js (theme.extend.colors).
class Paleta {
  // Marca - roxo (primária)
  static const primary = MaterialColor(0xFF6D28D9, {
    50: Color(0xFFF5F1FE),
    100: Color(0xFFEBE2FD),
    200: Color(0xFFD3C0FA),
    300: Color(0xFFB695F6),
    400: Color(0xFF9B6EF3),
    500: Color(0xFF8146EE),
    600: Color(0xFF6D28D9),
    700: Color(0xFF5B1EB8),
    800: Color(0xFF481894),
    900: Color(0xFF37136F),
    950: Color(0xFF220A47),
  });

  // Marca - rosa (secundária / detalhes)
  static const secondary = MaterialColor(0xFFEC4899, {
    50: Color(0xFFFEF1F8),
    100: Color(0xFFFDE3F1),
    200: Color(0xFFFBC6E3),
    300: Color(0xFFF894CB),
    400: Color(0xFFF45FAF),
    500: Color(0xFFEC4899),
    600: Color(0xFFD42E7D),
    700: Color(0xFFB01E64),
    800: Color(0xFF8F1B53),
    900: Color(0xFF771A48),
  });

  // Complementar - verde-água (também a cor de "sucesso")
  static const accent = MaterialColor(0xFF22B2A3, {
    50: Color(0xFFEDFDFA),
    100: Color(0xFFD2FAF3),
    200: Color(0xFFA9F2E6),
    300: Color(0xFF71E4D4),
    400: Color(0xFF3ECEBE),
    500: Color(0xFF22B2A3),
    600: Color(0xFF178F85),
    700: Color(0xFF17726C),
    800: Color(0xFF185B57),
    900: Color(0xFF184B49),
  });

  // Gradiente de marca (uso pontual: ícone da marca e pequenos detalhes).
  static const gradienteMarca = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFFC0389B)],
  );
}

// Espelho das variáveis CSS de frontend/src/index.css (:root e .dark).
class TokensIceiBank extends ThemeExtension<TokensIceiBank> {
  final Color bg;
  final Color bgAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color headerBg;

  const TokensIceiBank({
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.headerBg,
  });

  static const claro = TokensIceiBank(
    bg: Color.fromRGBO(248, 246, 253, 1),
    bgAlt: Color.fromRGBO(240, 235, 251, 1),
    surface: Color.fromRGBO(255, 255, 255, 1),
    surfaceAlt: Color.fromRGBO(246, 243, 252, 1),
    border: Color.fromRGBO(226, 218, 245, 1),
    text: Color.fromRGBO(30, 21, 51, 1),
    textMuted: Color.fromRGBO(106, 96, 130, 1),
    headerBg: Color.fromRGBO(255, 255, 255, 1),
  );

  static const escuro = TokensIceiBank(
    bg: Color.fromRGBO(13, 10, 22, 1),
    bgAlt: Color.fromRGBO(18, 14, 29, 1),
    surface: Color.fromRGBO(21, 16, 31, 1),
    surfaceAlt: Color.fromRGBO(29, 23, 41, 1),
    border: Color.fromRGBO(44, 36, 63, 1),
    text: Color.fromRGBO(240, 236, 250, 1),
    textMuted: Color.fromRGBO(163, 152, 189, 1),
    headerBg: Color.fromRGBO(18, 14, 29, 1),
  );

  @override
  TokensIceiBank copyWith({
    Color? bg,
    Color? bgAlt,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? headerBg,
  }) =>
      TokensIceiBank(
        bg: bg ?? this.bg,
        bgAlt: bgAlt ?? this.bgAlt,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        border: border ?? this.border,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        headerBg: headerBg ?? this.headerBg,
      );

  @override
  TokensIceiBank lerp(ThemeExtension<TokensIceiBank>? other, double t) {
    if (other is! TokensIceiBank) return this;
    return TokensIceiBank(
      bg: Color.lerp(bg, other.bg, t)!,
      bgAlt: Color.lerp(bgAlt, other.bgAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
    );
  }
}

extension TokensNoContexto on BuildContext {
  TokensIceiBank get tokens => Theme.of(this).extension<TokensIceiBank>()!;
}
