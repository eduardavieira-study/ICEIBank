import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/cores.dart';

enum TipoAviso { sucesso, info, erro }

// Pop-up discreto que desce do topo, fica alguns segundos e sobe de novo.
// Substitui o SnackBar: um selo com o ícone desenhado na entrada (o "check"
// se traça sozinho) e uma linha de texto. Só um aviso por vez.
class Aviso {
  static OverlayEntry? _atual;

  static void mostrar(
    BuildContext context,
    String texto, {
    TipoAviso tipo = TipoAviso.sucesso,
    Duration duracao = const Duration(milliseconds: 3200),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _atual?.remove();
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _AvisoWidget(
        texto: texto,
        tipo: tipo,
        duracao: duracao,
        aoTerminar: () {
          if (_atual == entrada) _atual = null;
          entrada.remove();
        },
      ),
    );
    _atual = entrada;
    overlay.insert(entrada);
  }
}

class _AvisoWidget extends StatefulWidget {
  final String texto;
  final TipoAviso tipo;
  final Duration duracao;
  final VoidCallback aoTerminar;

  const _AvisoWidget({
    required this.texto,
    required this.tipo,
    required this.duracao,
    required this.aoTerminar,
  });

  @override
  State<_AvisoWidget> createState() => _AvisoWidgetState();
}

class _AvisoWidgetState extends State<_AvisoWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _icone = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _timer;
  bool _saindo = false;

  @override
  void initState() {
    super.initState();
    _entrada.forward();
    // o traço do ícone começa um instante depois do selo aparecer
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _icone.forward();
    });
    _timer = Timer(widget.duracao, _sair);
  }

  Future<void> _sair() async {
    if (_saindo || !mounted) return;
    _saindo = true;
    await _entrada.reverse();
    if (mounted) widget.aoTerminar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrada.dispose();
    _icone.dispose();
    super.dispose();
  }

  Color _cor(bool escuro) => switch (widget.tipo) {
    TipoAviso.sucesso => Paleta.accent[escuro ? 400 : 600]!,
    TipoAviso.info => const Color(0xFFD97706),
    TipoAviso.erro => Paleta.secondary[escuro ? 400 : 600]!,
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final t = context.tokens;
    final cor = _cor(escuro);
    final topo = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topo + 12,
      left: 20,
      right: 20,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: _entrada,
          builder: (context, filho) {
            final curva = Curves.easeOutBack.transform(_entrada.value);
            return Opacity(
              opacity: Curves.easeOut.transform(_entrada.value).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -28 * (1 - curva)),
                child: Transform.scale(
                  scale: 0.94 + 0.06 * curva,
                  child: filho,
                ),
              ),
            );
          },
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.aoTerminar(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.border),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: escuro ? 0.22 : 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: escuro ? 0.35 : 0.05,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cor.withValues(alpha: 0.14),
                      ),
                      child: widget.tipo == TipoAviso.sucesso
                          ? AnimatedBuilder(
                              animation: _icone,
                              builder: (_, _) => CustomPaint(
                                painter: _PintorCheck(
                                  progresso: Curves.easeOut.transform(
                                    _icone.value,
                                  ),
                                  cor: cor,
                                ),
                              ),
                            )
                          : Icon(
                              widget.tipo == TipoAviso.erro
                                  ? LucideIcons.triangleAlert
                                  : LucideIcons.clock,
                              size: 16,
                              color: cor,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.texto,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: t.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

// Desenha o "check" aos poucos, como se alguém o traçasse com o dedo.
class _PintorCheck extends CustomPainter {
  final double progresso;
  final Color cor;

  _PintorCheck({required this.progresso, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final caminho = Path()
      ..moveTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.44, h * 0.66)
      ..lineTo(w * 0.70, h * 0.37);
    final metrica = caminho.computeMetrics().first;
    final parcial = metrica.extractPath(0, metrica.length * progresso);
    canvas.drawPath(
      parcial,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PintorCheck antigo) => antigo.progresso != progresso;
}
