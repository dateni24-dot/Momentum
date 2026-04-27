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

    // Rotación específica por acción
    //   - papelera: gira como un loco (0 → ~108° en threshold, +252° más allá)
    //   - lápiz: wiggle de escritura tipo sin
    final iconRotation = isDeleting
        ? progress * math.pi * 0.6 + extra * math.pi * 1.6
        : math.sin(progress * math.pi * 2.4) * 0.35 - extra * 0.3;

    final iconScale = 0.65 + 0.55 * progress + 0.25 * extra;

    final icon = isDeleting
        ? Icons.delete_outline_rounded
        : Icons.edit_note_rounded;

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
                  child: Transform.rotate(
                    angle: iconRotation,
                    child: Icon(
                      icon,
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
