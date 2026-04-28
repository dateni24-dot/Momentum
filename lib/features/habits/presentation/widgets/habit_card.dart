import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/habit_model.dart';
import '../../domain/habit_notifier.dart';
import '../../../../core/theme/app_colors.dart';

/// Tarjeta que representa un hábito en la lista.
/// Las acciones de editar/eliminar se hacen deslizando (SwipeableHabitCard).
/// Los botones internos gestionan el ciclo de vida del temporizador:
///   • Idle           → botón "Iniciar"
///   • In progress    → cuenta atrás + botón "Cancelar"
///   • Ready          → botón "Finalizar +N XP"
///   • Completed      → check verde
class HabitCard extends StatelessWidget {
  final HabitModel habit;

  const HabitCard({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = HabitColors.forHabit(habit.habitId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color:      habitColor.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset:     const Offset(-2, 0),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra de color izquierda con glow
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: habitColor,
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      habitColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Icono de hábito (decorativo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:        habitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  habit.completed ? Icons.check_rounded : Icons.task_alt_rounded,
                  color: habitColor,
                  size:  22,
                ),
              ),
            ),

            // Nombre + descripción + badge duración
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(
                      habit.habitName,
                      style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (habit.habitDescript != null &&
                        habit.habitDescript!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        habit.habitDescript!,
                        style: const TextStyle(
                          color:    AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Badge de duración
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:        habitColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: habitColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        HabitDuration.label(habit.time),
                        style: TextStyle(
                          color:      habitColor,
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Área de acciones (estado del temporizador)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _HabitActions(habit: habit),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HabitActions — botones de Iniciar / Cancelar / Finalizar según estado
// Tiene un Timer interno que refresca la cuenta atrás cada segundo cuando
// el hábito está en progreso.
// ---------------------------------------------------------------------------

class _HabitActions extends ConsumerStatefulWidget {
  final HabitModel habit;
  const _HabitActions({required this.habit});

  @override
  ConsumerState<_HabitActions> createState() => _HabitActionsState();
}

class _HabitActionsState extends ConsumerState<_HabitActions> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_HabitActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Arranca/para el ticker según el estado del hábito.
  /// Solo necesitamos refrescar cada segundo cuando el timer está corriendo.
  void _syncTicker() {
    final inProgress = widget.habit.isInProgress;
    if (inProgress && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!inProgress && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  Future<void> _start() async {
    final result = await ref
        .read(habitsNotifierProvider.notifier)
        .startCooldownHabit(widget.habit.habitId);
    _toast(result);
  }

  Future<void> _cancel() async {
    final result = await ref
        .read(habitsNotifierProvider.notifier)
        .cancelHabit(widget.habit.habitId);
    _toast(result);
  }

  Future<void> _complete() async {
    final result = await ref
        .read(habitsNotifierProvider.notifier)
        .completeHabit(widget.habit.habitId);
    if (!mounted) return;
    if (result is HabitSuccess) {
      final xp = widget.habit.time * 2;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text('+$xp XP para tu avatar'),
            ],
          ),
          backgroundColor: AppColors.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      _toast(result);
    }
  }

  void _toast(HabitResult result) {
    if (!mounted) return;
    if (result is HabitFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    if (habit.completed) return _StartButton(onTap: _start, isRepeat: true);
    if (habit.isReadyToComplete) {
      return _CompleteButton(xp: habit.time * 2, onTap: _complete);
    }
    if (habit.isInProgress) {
      return _InProgressView(
        remaining: habit.remainingTime ?? Duration.zero,
        onCancel: _cancel,
      );
    }
    return _StartButton(onTap: _start);
  }
}

// ---------------------------------------------------------------------------
// Botón "Iniciar" (estado idle)
// ---------------------------------------------------------------------------

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRepeat;
  const _StartButton({required this.onTap, this.isRepeat = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRepeat ? Icons.replay_rounded : Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              isRepeat ? 'Repetir' : 'Iniciar',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vista en progreso: cuenta atrás + botón cancelar
// ---------------------------------------------------------------------------

class _InProgressView extends StatelessWidget {
  final Duration remaining;
  final VoidCallback onCancel;

  const _InProgressView({required this.remaining, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final m = remaining.inMinutes.toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cuenta atrás
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.primary, size: 13),
              const SizedBox(width: 4),
              Text(
                '$m:$s',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Cancelar
        InkWell(
          onTap: onCancel,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded,
                    color: AppColors.error, size: 12),
                const SizedBox(width: 3),
                Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Botón "Finalizar" cuando el timer ha terminado — con glow llamativo
// ---------------------------------------------------------------------------

class _CompleteButton extends StatefulWidget {
  final int xp;
  final VoidCallback onTap;
  const _CompleteButton({required this.xp, required this.onTap});

  @override
  State<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<_CompleteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = 0.35 + 0.35 * _pulse.value;
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: glow),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 3),
                    Text(
                      'Finalizar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '+${widget.xp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

