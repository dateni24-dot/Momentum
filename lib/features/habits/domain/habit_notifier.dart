import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'habit_model.dart';
import '../data/habit_provider.dart';
import '../../profile/data/profile_provider.dart';

/// Estado del notifier de hábitos
class HabitsState {
  final List<HabitModel> habits;
  final bool isLoading;
  final String? errorMessage;

  const HabitsState({
    this.habits = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HabitsState copyWith({
    List<HabitModel>? habits,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HabitsState(
      habits:       habits       ?? this.habits,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Resultado de una operación de hábito
sealed class HabitResult {}
class HabitSuccess extends HabitResult {}
class HabitFailure extends HabitResult {
  final String message;
  HabitFailure(this.message);
}
// Resultado cuando el hábito se completa exitosamente: incluye XP, racha y multiplicador
class HabitCompleted extends HabitResult {
  final int xpAwarded;
  final double multiplier;
  final int streakDays;
  final bool isMilestone;
  final bool leveledUp;

  HabitCompleted({
    required this.xpAwarded,
    required this.multiplier,
    required this.streakDays,
    required this.isMilestone,
    required this.leveledUp,
  });
}

/// Notifier que gestiona el estado y las operaciones CRUD de hábitos
class HabitsNotifier extends AsyncNotifier<HabitsState> {

  @override
  Future<HabitsState> build() async {
    return await _loadHabits();
  }

  Future<HabitsState> _loadHabits() async {
    final repo = ref.read(habitRepositoryProvider);
    final habits = await repo.fetchHabits();
    return HabitsState(habits: habits);
  }

  /// Recarga la lista de hábitos desde Supabase
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadHabits());
  }

  /// Crea un nuevo hábito
  Future<HabitResult> createHabit(HabitModel habit) async {
    final current = state.valueOrNull ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final repo = ref.read(habitRepositoryProvider);
      final created = await repo.createHabit(habit);
      final updated = [...current.habits, created];
      state = AsyncValue.data(HabitsState(habits: updated));
      return HabitSuccess();
    } on PostgrestException catch (e) {
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al crear el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  /// Actualiza un hábito existente
  Future<HabitResult> updateHabit(HabitModel habit) async {
    final current = state.valueOrNull ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final repo = ref.read(habitRepositoryProvider);
      final updated = await repo.updateHabit(habit);
      final list = current.habits
          .map((h) => h.habitId == updated.habitId ? updated : h)
          .toList();
      state = AsyncValue.data(HabitsState(habits: list));
      return HabitSuccess();
    } on PostgrestException catch (e) {
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al actualizar el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  /// Elimina un hábito
  Future<HabitResult> deleteHabit(int habitId) async {
    final current = state.valueOrNull ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      
      final repo = ref.read(habitRepositoryProvider); // Obtener el repositorio para interactuar con Supabase
      await repo.deleteHabit(habitId); // Eliminar el hábito del estado local
      final list = current.habits.where((h) => h.habitId != habitId).toList(); // Actualizar la lista de hábitos sin el hábito eliminado
      state = AsyncValue.data(HabitsState(habits: list)); // Actualizar el estado con la nueva lista de hábitos
      return HabitSuccess();
    } on PostgrestException catch (e) {
      // Si ocurre un error al eliminar el hábito, se mantiene el estado actual y se muestra un mensaje de error
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al eliminar el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  /// Inicia el temporizador del hábito. Guarda started_at en Supabase
  /// para que el progreso persista aunque la app se cierre.
  Future<HabitResult> startCooldownHabit(int habitId) async {
    final current = state.valueOrNull ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final repo = ref.read(habitRepositoryProvider);
      final updated = await repo.startCooldownHabit(habitId);
      final list = current.habits
          .map((h) => h.habitId == habitId ? updated : h)
          .toList();
      state = AsyncValue.data(HabitsState(habits: list));
      return HabitSuccess();
    } on PostgrestException catch (e) {
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al iniciar el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  /// Cancela el temporizador iniciado por error.
  /// Resetea started_at a null y completed a false. No otorga XP.
  Future<HabitResult> cancelHabit(int habitId) async {
    final current = state.valueOrNull ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final repo = ref.read(habitRepositoryProvider);
      final updated = await repo.cancelHabit(habitId);
      final list = current.habits
          .map((h) => h.habitId == habitId ? updated : h)
          .toList();
      state = AsyncValue.data(HabitsState(habits: list));
      return HabitSuccess();
    } on PostgrestException catch (e) {
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al cancelar el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  /// Completa el hábito, actualiza la racha y concede XP con multiplicador.
  /// Solo ejecuta si habit.isReadyToComplete == true.
  Future<HabitResult> completeHabit(int habitId) async {
    final current = state.valueOrNull ?? const HabitsState();

    final habit = current.habits.firstWhere((h) => h.habitId == habitId);
    if (!habit.isReadyToComplete) {
      return HabitFailure('El temporizador aún no ha terminado.');
    }

    final baseXp = habit.time * 2;
    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final repo = ref.read(habitRepositoryProvider);
      final result = await repo.completeHabit(habitId, baseXp);
      final list = current.habits
          .map((h) => h.habitId == habitId ? result.habit : h)
          .toList();
      state = AsyncValue.data(HabitsState(habits: list));
      ref.invalidate(userProfileProvider);
      return HabitCompleted(
        xpAwarded:   result.xpAwarded,
        multiplier:  result.multiplier,
        streakDays:  result.streakDays,
        isMilestone: result.isMilestone,
        leveledUp:   result.leveledUp,
      );
    } on PostgrestException catch (e) {
      state = AsyncValue.data(current.copyWith(errorMessage: e.message));
      return HabitFailure('Error al completar el hábito. Inténtalo de nuevo.');
    } catch (_) {
      state = AsyncValue.data(current);
      return HabitFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }
}

final habitsNotifierProvider =
    AsyncNotifierProvider<HabitsNotifier, HabitsState>(HabitsNotifier.new);
