import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/cores.dart';

// Cartão que vira ao toque, como um cartão de verdade: a frente mostra o saldo
// e o verso os dados da conta. Gira em 3D (perspectiva) com um leve "pulo" no
// fim. Só a face visível entra na árvore de widgets.
class CartaoVirar extends StatefulWidget {
  final Widget frente;
  final Widget verso;

  const CartaoVirar({super.key, required this.frente, required this.verso});

  @override
  State<CartaoVirar> createState() => _CartaoVirarState();
}

class _CartaoVirarState extends State<CartaoVirar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOutCubicEmphasized,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _virar() {
    if (_ctrl.isAnimating) return;
    _ctrl.isCompleted ? _ctrl.reverse() : _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('cartao-virar'),
      onTap: _virar,
      child: AnimatedBuilder(
        animation: _curva,
        builder: (context, _) {
          final angulo = _curva.value * math.pi;
          final mostrandoVerso = angulo > math.pi / 2;
          // o card "levanta" no meio do giro e a sombra acompanha
          final elevacao = math.sin(angulo);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angulo)
              ..scaleByDouble(1 + 0.04 * elevacao, 1 + 0.04 * elevacao, 1, 1),
            child: mostrandoVerso
                // o verso nasce espelhado; gira mais meia-volta para ler certo
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: widget.verso,
                  )
                : widget.frente,
          );
        },
      ),
    );
  }
}

// Base visual comum às duas faces: gradiente da marca, cantos e sombra.
class CartaoBase extends StatelessWidget {
  final Widget child;
  final bool invertido; // verso: gradiente espelhado

  const CartaoBase({super.key, required this.child, this.invertido = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: invertido
            ? const LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [Color(0xFF6D28D9), Color(0xFFC0389B)],
              )
            : Paleta.gradienteMarca,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Paleta.secondary[600]!.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Paleta.primary[600]!.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: invertido ? null : -50,
              left: invertido ? -50 : null,
              top: -50,
              child: const _Circulo(tamanho: 190, alpha: 0.12),
            ),
            Positioned(
              left: invertido ? null : -40,
              right: invertido ? -40 : null,
              bottom: -70,
              child: const _Circulo(tamanho: 170, alpha: 0.08),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  final double tamanho;
  final double alpha;

  const _Circulo({required this.tamanho, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

// Verso do cartão: curvas de nível ao fundo, selo holográfico, número da conta
// em destaque e o titular. Sem tarja preta: só luz e linhas finas.
class VersoCartao extends StatelessWidget {
  final String nome;
  final int? conta;
  final String agencia;

  const VersoCartao({
    super.key,
    required this.nome,
    required this.conta,
    required this.agencia,
  });

  // 7 -> "0007", 1234 -> "1234", 12345 -> "12 345"
  String _formatarConta() {
    if (conta == null) return '—';
    final d = conta.toString().padLeft(4, '0');
    if (d.length <= 4) return d;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && (d.length - i) % 3 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    const branco = Colors.white;
    final suave = branco.withValues(alpha: 0.7);
    final rotulo = tema.bodySmall?.copyWith(
      color: suave,
      fontSize: 10,
      letterSpacing: 1.6,
    );

    return CartaoBase(
      invertido: true,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PintorCurvas())),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: branco.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: branco.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        agencia.toUpperCase(),
                        style: tema.bodySmall?.copyWith(
                          color: branco,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const _SeloHolografico(),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NÚMERO DA CONTA', style: rotulo),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatarConta(),
                        key: const Key('verso-conta'),
                        style: tema.headlineMedium?.copyWith(
                          color: branco,
                          letterSpacing: 5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TITULAR', style: rotulo),
                          const SizedBox(height: 2),
                          Text(
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.titleSmall?.copyWith(color: branco),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.rotateCw, size: 14, color: suave),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Selo pequeno com brilho cônico, no estilo dos hologramas de cartão.
class _SeloHolografico extends StatelessWidget {
  const _SeloHolografico();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFF9B6EF3),
            Color(0xFF71E4D4),
            Color(0xFFF894CB),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.18),
        ),
        child: const Icon(LucideIcons.landmark, size: 14, color: Colors.white),
      ),
    );
  }
}

// Arcos concêntricos finos saindo do canto inferior direito, como curvas de
// nível de um mapa: dá textura sem competir com as informações.
class _PintorCurvas extends CustomPainter {
  const _PintorCurvas();

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width * 1.02, size.height * 1.1);
    for (var i = 1; i <= 9; i++) {
      canvas.drawCircle(
        centro,
        i * size.width * 0.105,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.13 - i * 0.008),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorCurvas antigo) => false;
}
