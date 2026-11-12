import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../util/formato.dart';

// Entrada suave: o conteúdo sobe alguns pixels enquanto aparece. [ordem]
// escalona os itens de uma lista (cada um começa um pouco depois do anterior).
class Entrada extends StatefulWidget {
  final Widget child;
  final int ordem;

  const Entrada({super.key, required this.child, this.ordem = 0});

  @override
  State<Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<Entrada> with SingleTickerProviderStateMixin {
  static const _atrasoPorItem = 70; // ms
  static const _duracao = 420; // ms

  late final int _total = _duracao + math.min(widget.ordem, 8) * _atrasoPorItem;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total),
  )..forward();

  late final Animation<double> _curva = CurvedAnimation(
    parent: _ctrl,
    curve: Interval(
      math.min(widget.ordem, 8) * _atrasoPorItem / _total,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curva,
      builder: (_, filho) => Opacity(
        opacity: _curva.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _curva.value)),
          child: filho,
        ),
      ),
      child: widget.child,
    );
  }
}

// Valor em reais que "rola" até o novo número quando muda. A primeira exibição
// aparece direto, sem animar.
class ReaisAnimado extends StatelessWidget {
  final double valor;
  final TextStyle? estilo;

  const ReaisAnimado({super.key, required this.valor, this.estilo});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: valor),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(formatarReais(v), style: estilo),
    );
  }
}

// Botão que afunda um pouco ao ser pressionado (retorno tátil visual).
class Pressionavel extends StatefulWidget {
  final Widget child;

  const Pressionavel({super.key, required this.child});

  @override
  State<Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<Pressionavel> {
  bool _baixo = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _baixo = true),
      onPointerUp: (_) => setState(() => _baixo = false),
      onPointerCancel: (_) => setState(() => _baixo = false),
      child: AnimatedScale(
        scale: _baixo ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
