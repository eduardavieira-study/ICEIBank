import 'dart:math';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

// Granulado sutil por cima de um fundo colorido, como o `noise-overlay` do
// BankCard do web. Os pontos são sorteados com semente fixa, então o desenho
// é sempre o mesmo (sem tremer a cada rebuild).
class Granulado extends StatelessWidget {
  final double opacidade;

  const Granulado({super.key, this.opacidade = 0.5});

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _PintorGranulado(opacidade)),
          ),
        ),
      );
}

class _PintorGranulado extends CustomPainter {
  final double opacidade;

  _PintorGranulado(this.opacidade);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final area = size.width * size.height;
    final quantidade = (area / 14).clamp(0, 14000).toInt();
    final claro = <Offset>[];
    final escuro = <Offset>[];
    for (var i = 0; i < quantidade; i++) {
      final ponto = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      (rnd.nextBool() ? claro : escuro).add(ponto);
    }
    Paint tinta(Color c) => Paint()
      ..color = c.withValues(alpha: 0.16 * opacidade)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.square;
    canvas.drawPoints(PointMode.points, claro, tinta(Colors.white));
    canvas.drawPoints(PointMode.points, escuro, tinta(Colors.black));
  }

  @override
  bool shouldRepaint(_PintorGranulado antigo) => antigo.opacidade != opacidade;
}
