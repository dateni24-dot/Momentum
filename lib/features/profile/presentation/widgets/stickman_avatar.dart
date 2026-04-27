import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// StickmanAvatar — stickman animado con CustomPainter
// Animaciones: bob vertical (respiración) + saludo con brazo derecho + sway de piernas
// ---------------------------------------------------------------------------

class StickmanAvatar extends StatefulWidget {
  final double size;
  final Color color;

  const StickmanAvatar({
    super.key,
    this.size = 110,
    this.color = AppColors.primary,
  });

  @override
  State<StickmanAvatar> createState() => _StickmanAvatarState();
}

class _StickmanAvatarState extends State<StickmanAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size * 1.25),
        painter: _StickmanPainter(
          animValue: _ctrl.value,
          color: widget.color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _StickmanPainter extends CustomPainter {
  final double animValue; // 0.0 → 1.0 continuo
  final Color color;

  const _StickmanPainter({required this.animValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 10.0; // unidad base proporcional al tamaño

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = u * 0.42
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    // ── Breathing bob (ciclo completo por vuelta) ──────────────────────────
    final bob = sin(animValue * 2 * pi) * u * 0.22;

    // ── Cabeza ────────────────────────────────────────────────────────────
    final headRadius = u * 1.38;
    final headCenter = Offset(cx, u * 1.85 + bob);
    canvas.drawCircle(headCenter, headRadius, linePaint);

    // Ojos
    canvas.drawCircle(
      Offset(cx - u * 0.45, headCenter.dy - u * 0.18),
      u * 0.18,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + u * 0.45, headCenter.dy - u * 0.18),
      u * 0.18,
      fillPaint,
    );

    // Sonrisa (arco en la mitad inferior de la cabeza)
    final smileRect = Rect.fromCenter(
      center: Offset(cx, headCenter.dy + u * 0.20),
      width: u * 1.20,
      height: u * 0.78,
    );
    canvas.drawArc(smileRect, 0.0, pi, false,
        linePaint..strokeWidth = u * 0.30);
    linePaint.strokeWidth = u * 0.42; // restaurar grosor

    // ── Cuerpo ────────────────────────────────────────────────────────────
    final bodyTop = Offset(cx, headCenter.dy + headRadius * 0.95);
    final bodyBot = Offset(cx, headCenter.dy + u * 5.40);
    canvas.drawLine(bodyTop, bodyBot, linePaint);

    // ── Brazos ────────────────────────────────────────────────────────────
    final armPivot = Offset(cx, headCenter.dy + u * 2.50);
    final armLen = u * 2.75;

    // Brazo izquierdo: estático, relajado hacia abajo-izquierda
    canvas.drawLine(
      armPivot,
      Offset(armPivot.dx - armLen * 0.82, armPivot.dy + armLen * 0.52),
      linePaint,
    );

    // Brazo derecho: saluda (oscila entre abajo-derecha y arriba-derecha)
    // waveT: 0 = relajado abajo, 1 = levantado arriba
    final waveT = (sin(animValue * 2 * pi) + 1) / 2;
    final rightArmDy = _lerp(0.52, -0.68, waveT);
    canvas.drawLine(
      armPivot,
      Offset(armPivot.dx + armLen * 0.82, armPivot.dy + armLen * rightArmDy),
      linePaint,
    );

    // ── Piernas ───────────────────────────────────────────────────────────
    final legPivot = bodyBot;
    final legLen = u * 3.10;
    // Leve balanceo alternado
    final legSway = sin(animValue * 2 * pi) * u * 0.28;

    canvas.drawLine(
      legPivot,
      Offset(legPivot.dx - legLen * 0.60 + legSway, legPivot.dy + legLen * 0.80),
      linePaint,
    );
    canvas.drawLine(
      legPivot,
      Offset(legPivot.dx + legLen * 0.60 - legSway, legPivot.dy + legLen * 0.80),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_StickmanPainter old) => old.animValue != animValue;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
