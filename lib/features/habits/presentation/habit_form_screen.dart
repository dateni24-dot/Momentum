import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit_model.dart';
import '../domain/habit_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla para crear o editar un hábito.
/// Campos: habit_name, habit_descript, time (duración en minutos)
class HabitFormScreen extends ConsumerStatefulWidget {
  /// Si es null se crea un nuevo hábito; si tiene valor se edita.
  final HabitModel? habit;

  const HabitFormScreen({super.key, this.habit});

  bool get isEditing => habit != null;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late int _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.habit?.habitName ?? '');
    _descController = TextEditingController(
        text: widget.habit?.habitDescript ?? '');
    _selectedTime = widget.habit?.time ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final habit = widget.isEditing
        ? widget.habit!.copyWith(
            habitName:    _nameController.text.trim(),
            habitDescript: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            time: _selectedTime,
          )
        : HabitModel(
            habitId:       0, // Supabase lo genera automáticamente
            habitName:     _nameController.text.trim(),
            habitDescript: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            time:      _selectedTime,
            createdAt: DateTime.now(),
          );

    final notifier = ref.read(habitsNotifierProvider.notifier);
    final result = widget.isEditing
        ? await notifier.updateHabit(habit)
        : await notifier.createHabit(habit);

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case HabitSuccess():
      case HabitCompleted():
        Navigator.of(context).pop(true);
      case HabitFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(message),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Color de preview basado en un ID temporal mientras se crea
    final previewColor = widget.isEditing
        ? HabitColors.forHabit(widget.habit!.habitId)
        : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditing ? 'Editar hábito' : 'Nuevo hábito',
          style: const TextStyle(
            color:      AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize:   18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Preview animado
                _HabitPreview(
                  name:  _nameController.text.isEmpty
                      ? 'Nombre del hábito'
                      : _nameController.text,
                  time:  _selectedTime,
                  color: previewColor,
                ),

                const SizedBox(height: 32),

                // --- Nombre ---
                _SectionLabel('Nombre'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  maxLength:  AppConstants.habitNameMaxLength,
                  onChanged:  (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText:    'Ej: Leer 30 minutos',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (v.trim().length < AppConstants.habitNameMinLength) {
                      return 'Mínimo ${AppConstants.habitNameMinLength} caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // --- Descripción ---
                _SectionLabel('Descripción (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLength:  100,
                  maxLines:   2,
                  decoration: const InputDecoration(
                    hintText:    'Ej: Leer un libro cada noche antes de dormir',
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 24),

                // --- Duración ---
                _SectionLabel('Duración objetivo'),
                const SizedBox(height: 12),
                Wrap(
                  spacing:    10,
                  runSpacing: 10,
                  children: HabitDuration.options.map((minutes) {
                    final selected = _selectedTime == minutes;
                    return _DurationChip(
                      label:    HabitDuration.label(minutes),
                      selected: selected,
                      color:    previewColor,
                      onTap:    () => setState(() => _selectedTime = minutes),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                // --- Botón guardar ---
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    child: _isSaving
                        ? const SizedBox(
                            width:  22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color:       Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.isEditing
                                  ? 'Guardar cambios'
                                  : 'Crear hábito'),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_rounded,
                                size:  18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color:       AppColors.textSecondary,
        fontSize:    13,
        fontWeight:  FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected ? color : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize:   13,
          ),
        ),
      ),
    );
  }
}

/// Preview del hábito en tiempo real mientras se edita el formulario
class _HabitPreview extends StatelessWidget {
  final String name;
  final int time;
  final Color color;

  const _HabitPreview({
    required this.name,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color:      color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset:     const Offset(-2, 0),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra de color
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Icono
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.task_alt_rounded, color: color, size: 22),
              ),
            ),
            // Nombre + badge
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:        color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        HabitDuration.label(time),
                        style: TextStyle(
                          color:      color,
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
