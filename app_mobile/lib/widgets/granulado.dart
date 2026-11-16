import 'dart:math';
import 'dart:typed_data';
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

  // Os pontos só dependem do tamanho: são sorteados uma vez e reaproveitados
  // (antes eram 14 mil sorteios + listas de Offset a cada pintura).
  static final Map<(int, int), (Float32List, Float32List)> _cache = {};

  static (Float32List, Float32List) _pontos(Size size) {
    return _cache.putIfAbsent((size.width.round(), size.height.round()), () {
      final rnd = Random(7);
      final quantidade = (size.width * size.height / 20).clamp(0, 6000).toInt();
      final claro = <double>[];
      final escuro = <double>[];
      for (var i = 0; i < quantidade; i++) {
        (rnd.nextBool() ? claro : escuro)
          ..add(rnd.nextDouble() * size.width)
          ..add(rnd.nextDouble() * size.height);
      }
      return (Float32List.fromList(claro), Float32List.fromList(escuro));
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (claro, escuro) = _pontos(size);
    Paint tinta(Color c) => Paint()
      ..color = c.withValues(alpha: 0.16 * opacidade)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    canvas.drawRawPoints(PointMode.points, claro, tinta(Colors.white));
    canvas.drawRawPoints(PointMode.points, escuro, tinta(Colors.black));
  }

  @override
  bool shouldRepaint(_PintorGranulado antigo) => antigo.opacidade != opacidade;
}
