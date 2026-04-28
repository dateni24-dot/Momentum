import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/habit_model.dart';
import 'habit_card.dart';

// ---------------------------------------------------------------------------
// SwipeableHabitCard
//
// Envuelve una HabitCard con gestos de swipe:
//   - Derecha (→) → editar (azul, lápiz con wiggle)
//   - Izquierda (←) → eliminar (rojo, papelera que rota)
// Incluye haptic feedback al cruzar el umbral, fondo con glow,
// y una animación "peek" en el primer arranque para enseñar la mecánica.
// ---------------------------------------------------------------------------

class SwipeableHabitCard extends StatefulWidget {
  final HabitModel habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isFirst;

  const SwipeableHabitCard({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    this.isFirst = false,
  });

  @override
  State<SwipeableHabitCard> createState() => _SwipeableHabitCardState();
}

class _SwipeableHabitCardState extends State<SwipeableHabitCard>
    with TickerProviderStateMixin {
  // Solo mostramos el peek una vez por sesión (primera tarjeta visible)
  static bool _peekShown = false;

  // Distancia (px) que hay que recorrer para activar la acción
  static const double _threshold = 90.0;

  // Estado actual del drag
  double _offset = 0.0;
  bool _crossedThreshold = false;
  bool _isDragging = false;

  late final AnimationController _settleCtrl;
  Animation<double>? _settleAnim;

  late final AnimationController _peekCtrl;
  late final Animation<double> _peekAnim;

  @override
  void initState() {
    super.initState();

    _settleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(_onSettle);

    _peekCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Peek = drag derecha → snap → drag izquierda → snap
    _peekAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 60.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 28,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 6),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 22,
      ),
    ]).animate(_peekCtrl);

    _peekAnim.addListener(_onPeek);

    if (widget.isFirst && !_peekShown) {
      _peekShown = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _peekCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _settleCtrl.dispose();
    _peekCtrl.dispose();
    super.dispose();
  }

  void _onPeek() {
    if (_isDragging) return;
    setState(() => _offset = _peekAnim.value);
  }

  void _onSettle() {
    if (_settleAnim == null) return;
    setState(() => _offset = _settleAnim!.value);
  }

  // ── Gestures ─────────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    _isDragging = true;
    _crossedThreshold = false;
    if (_settleCtrl.isAnimating) _settleCtrl.stop();
    if (_peekCtrl.isAnimating) _peekCtrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      double next = _offset + details.delta.dx;
      final mag = next.abs();
      // Resistencia más allá del umbral (sensación elástica)
      if (mag > _threshold) {
        final excess = mag - _threshold;
        final damped = excess * 0.45;
        next = next.sign * (_threshold + damped);
      }
      _offset = next;

      final crossed = next.abs() > _threshold;
      if (crossed && !_crossedThreshold) {
        _crossedThreshold = true;
        HapticFeedback.mediumImpact();
      } else if (!crossed && _crossedThreshold) {
        _crossedThreshold = false;
      }
    });
  }

  void _onDragEnd(DragEndDetails _) {
    _isDragging = false;
    final passed = _offset.abs() > _threshold;
    final wasRight = _offset > 0;

    // Animación elástica de vuelta a 0
    _settleAnim = Tween<double>(begin: _offset, end: 0.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_settleCtrl);
    _settleCtrl.forward(from: 0);

    // Si cruzó el umbral, dispara la acción tras un breve delay
    // para que el usuario sienta el snap-back antes de que aparezca el modal
    if (passed) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        wasRight ? widget.onEdit() : widget.onDelete();
      });
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            // Fondo con icono animado (visible solo si se está deslizando)
            if (_offset.abs() > 0.5)
              Positioned.fill(child: _ActionBackground(offset: _offset)),

            // Tarjeta translada con el dedo
            Transform.translate(
              offset: Offset(_offset, 0),
              child: HabitCard(habit: widget.habit),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo de acción — pinta el color y el icono animado detrás de la tarjeta
// ---------------------------------------------------------------------------

class _ActionBackground extends StatelessWidget {
  final double offset;
  static const double _threshold = 90.0;

  const _ActionBackground({required this.offset});

  @override
  Widget build(BuildContext context) {
    final isDeleting = offset < 0;
    final mag = offset.abs();
    final progress = (mag / _threshold).clamp(0.0, 1.0);
    // "extra" = qué tanto pasa del umbral (0 → 1 cuando duplica el umbral)
    final extra = ((mag - _threshold) / _threshold).clamp(0.0, 1.0);

    // Colores
    final baseColor = isDeleting
        ? const Color(0xFFFF3B30) // rojo iOS
        : const Color(0xFF2979FF); // azul vibrante

    final fillColor = Color.lerp(
      baseColor.withValues(alpha: 0.18),
      baseColor,
      Curves.easeOutCubic.transform(progress),
    )!;

    // Para el lápiz: wiggle de escritura tipo sin
    // Para la papelera: usamos un CustomPainter custom (ver _AnimatedTrash)
    final pencilRotation =
        math.sin(progress * math.pi * 2.4) * 0.35 - extra * 0.3;

    final iconScale = 0.65 + 0.55 * progress + 0.25 * extra;

    final label = isDeleting ? 'Eliminar' : 'Editar';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isDeleting ? Alignment.centerLeft : Alignment.centerRight,
            end: isDeleting ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              fillColor.withValues(alpha: 0.35),
              fillColor,
            ],
          ),
          boxShadow: progress > 0.55
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.5 * progress),
                    blurRadius: 28,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Align(
          alignment:
              isDeleting ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: iconScale,
                  child: isDeleting
                      ? _AnimatedTrash(
                          progress: progress,
                          extra: extra,
                        )
                      : Transform.rotate(
                          angle: pencilRotation,
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 32,
                            shadows: progress > 0.5
                                ? const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: Curves.easeIn.transform(progress),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedTrash — papelera dibujada con CustomPainter
//
// progress (0→1): mientras se desliza hacia el umbral
//   • la tapa se levanta y empieza a inclinarse
//   • la basurilla cae poco a poco
// extra (0→1): cuanto se pasa del umbral
//   • la papelera tiembla
//   • la tapa se cae del todo y se desvanece
//   • más basurilla cae
// ---------------------------------------------------------------------------

class _AnimatedTrash extends StatelessWidget {
  final double progress;
  final double extra;

  const _AnimatedTrash({required this.progress, required this.extra});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 44,
      child: CustomPaint(
        painter: _TrashPainter(progress: progress, extra: extra),
      ),
    );
  }
}

class _TrashPainter extends CustomPainter {
  final double progress;
  final double extra;

  const _TrashPainter({required this.progress, required this.extra});

  // Geometría base (cuando el cubo está en pie, sin rotar)
  static const double _bodyBotRightX = 25.5;  // pivot X
  static const double _bodyBotY      = 34.0;  // pivot Y (esquina inferior-derecha)
  static const double _lidCx         = 18.0;  // centro X de la tapa
  static const double _lidCy         = 12.0;  // centro Y de la tapa

  static const double _maxRotation = 1.66; // ~95° del cubo entero
  static const double _detachAt    = 0.45; // a qué progress se despega la tapa
  static const double _spillStart  = 0.82; // a qué progress empieza a salir basura

  @override
  void paint(Canvas canvas, Size size) {
    // Tembleque al pasar el umbral
    if (extra > 0) {
      final shake = math.sin(progress * 40) * extra * 1.0;
      canvas.translate(shake, 0);
    }

    // ── 1. Cuerpo + ranuras: rotan en bloque alrededor de la esquina inferior-derecha ──
    final bodyRotation = progress * _maxRotation + extra * 0.08;

    canvas.save();
    canvas.translate(_bodyBotRightX, _bodyBotY);
    canvas.rotate(bodyRotation);
    canvas.translate(-_bodyBotRightX, -_bodyBotY);

    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Cuerpo trapezoidal
    final body = Path()
      ..moveTo(8, 14)
      ..lineTo(28, 14)
      ..lineTo(_bodyBotRightX, _bodyBotY)
      ..lineTo(10.5, _bodyBotY)
      ..close();
    canvas.drawPath(body, stroke);

    // 3 ranuras verticales
    canvas.drawLine(const Offset(14, 17), const Offset(14, 31), stroke);
    canvas.drawLine(const Offset(18, 17), const Offset(18, 31), stroke);
    canvas.drawLine(const Offset(22, 17), const Offset(22, 31), stroke);

    canvas.restore();

    // ── 2. Tapa: pegada al cubo hasta detachAt, luego se despega y cae ──
    _drawLid(canvas);

    // ── 3. Basurilla: solo cuando el cubo está casi volcado ──
    _drawDebris(canvas);
  }

  void _drawLid(Canvas canvas) {
    canvas.save();

    if (progress <= _detachAt) {
      // Pegada → comparte la rotación del cuerpo
      canvas.translate(_bodyBotRightX, _bodyBotY);
      canvas.rotate(progress * _maxRotation);
      canvas.translate(-_bodyBotRightX, -_bodyBotY);
      _drawLidShape(canvas, 1.0);
    } else {
      // Despegada → calculamos dónde estaba en el momento del despegue
      // y a partir de ahí la tapa cae con gravedad real (en coords absolutas)
      final detachRot = _detachAt * _maxRotation;
      const relX = _lidCx - _bodyBotRightX; // -7.5
      const relY = _lidCy - _bodyBotY;      // -22.0
      final cosD = math.cos(detachRot);
      final sinD = math.sin(detachRot);
      final detachAbsX = _bodyBotRightX + relX * cosD - relY * sinD;
      final detachAbsY = _bodyBotY      + relX * sinD + relY * cosD;

      // Tiempo desde el despegue (0 → 1+ con extra)
      final t = (progress - _detachAt) / (1.0 - _detachAt) + extra * 0.5;

      // La tapa sigue rotando + cae con gravedad real en coords absolutas
      final additionalRot = t * 1.6;
      final dx = t * 5.0;
      final dy = t * t * 32.0;

      canvas.translate(detachAbsX + dx, detachAbsY + dy);
      canvas.rotate(detachRot + additionalRot);
      canvas.translate(-_lidCx, -_lidCy);

      final opacity = (1.0 - (t - 0.7).clamp(0.0, 1.0) / 0.4).clamp(0.0, 1.0);
      _drawLidShape(canvas, opacity);
    }

    canvas.restore();
  }

  void _drawLidShape(Canvas canvas, double opacity) {
    final lidPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Barra horizontal de la tapa (centrada en _lidCx, _lidCy)
    canvas.drawLine(const Offset(6, 12), const Offset(30, 12), lidPaint);

    // Asa
    final handlePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final handle = Path()
      ..moveTo(15, 9.5)
      ..lineTo(15, 11)
      ..lineTo(21, 11)
      ..lineTo(21, 9.5);
    canvas.drawPath(handle, handlePaint);
  }

  void _drawDebris(Canvas canvas) {
    if (progress < _spillStart) return;

    // Avance del derrame: 0 al inicio, 1 al final del progress, +extra al rebasar
    final spill = (progress - _spillStart) / (1.0 - _spillStart) + extra * 1.0;

    // Spawn cerca de la apertura ya volcada (~x=44, y de 20 a 35)
    // vx pequeño porque la apertura mira a la derecha — la mayor parte cae por gravedad
    const specs = [
      _Particle(spawnX: 44, spawnY: 20, vx: 1.5, delay: 0.00, fall: 32, type: 0, rot:  5.0),
      _Particle(spawnX: 45, spawnY: 25, vx: 2.5, delay: 0.20, fall: 30, type: 1, rot:  0.0),
      _Particle(spawnX: 44, spawnY: 30, vx: 0.8, delay: 0.38, fall: 28, type: 2, rot: -3.5),
      _Particle(spawnX: 45, spawnY: 35, vx: 3.5, delay: 0.55, fall: 34, type: 3, rot:  6.0),
    ];

    for (final p in specs) {
      final raw = spill - p.delay;
      if (raw <= 0) continue;
      final t = raw.clamp(0.0, 2.0);

      // Trayectoria: vx ligero hacia la derecha + caída acelerada (t²)
      final x = p.spawnX + p.vx * t;
      final y = p.spawnY + t * t * p.fall;

      // Fade out al final del recorrido
      final fadeStart = 0.9;
      final opacity = t < fadeStart
          ? 1.0
          : (1.0 - (t - fadeStart) / 0.5).clamp(0.0, 1.0);
      if (opacity <= 0.05) continue;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.rot);

      switch (p.type) {
        case 0: // papel arrugado
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-1.4, -1.4, 2.8, 2.8),
              const Radius.circular(0.5),
            ),
            paint,
          );
          break;
        case 1: // bolita
          canvas.drawCircle(Offset.zero, 1.6, paint);
          break;
        case 2: // piel de plátano
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-2, -0.8, 4, 1.6),
              const Radius.circular(0.8),
            ),
            paint,
          );
          break;
        case 3: // pico/triángulo
          final tri = Path()
            ..moveTo(0, -1.6)
            ..lineTo(1.5, 1.2)
            ..lineTo(-1.5, 1.2)
            ..close();
          canvas.drawPath(tri, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TrashPainter old) =>
      old.progress != progress || old.extra != extra;
}

class _Particle {
  final double spawnX;
  final double spawnY;
  final double vx;
  final double delay;
  final double fall;
  final int type;
  final double rot;

  const _Particle({
    required this.spawnX,
    required this.spawnY,
    required this.vx,
    required this.delay,
    required this.fall,
    required this.type,
    required this.rot,
  });
}
