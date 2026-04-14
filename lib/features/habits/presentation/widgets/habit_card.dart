import 'package:flutter/material.dart';
import '../../domain/habit_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Tarjeta que representa un hábito en la lista.
/// El color es determinista: palette[habitId % palette.length]
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = HabitColors.forHabit(habit.habitId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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

            // Icono de hábito (decorativo, no viene de BD)
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
                  Icons.task_alt_rounded,
                  color: habitColor,
                  size:  22,
                ),
              ),
            ),

            // Nombre + descripción + badge duración
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
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

            // Acciones: editar y eliminar
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon:    Icons.edit_outlined,
                    color:   AppColors.grey,
                    onTap:   onEdit,
                    tooltip: 'Editar',
                  ),
                  const SizedBox(height: 4),
                  _ActionButton(
                    icon:    Icons.delete_outline_rounded,
                    color:   AppColors.error,
                    onTap:   onDelete,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
