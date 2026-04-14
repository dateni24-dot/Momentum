import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/habit_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';

/// Repositorio CRUD de hábitos.
/// La tabla `habit` almacena la definición del hábito.
/// La tabla `user_habit` vincula cada hábito con su usuario.
class HabitRepository {
  HabitRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve los hábitos del usuario actual usando el JOIN Supabase:
  /// user_habit → habit (relación anidada)
  Future<List<HabitModel>> fetchHabits() async {
    final userId = _userId;
    if (userId == null) return [];

    // Supabase permite hacer SELECT con relaciones anidadas:
    // from user_habit, select habit(*) donde user_id = userId
    final data = await _client
        .from(AppConstants.tableUserHabits)
        .select('${AppConstants.tableHabits}(*)')
        .eq('user_id', userId)
        .order('created_at', referencedTable: AppConstants.tableHabits,
            ascending: true);

    return (data as List<dynamic>).map((row) {
      final habitMap = row[AppConstants.tableHabits] as Map<String, dynamic>;
      return HabitModel.fromMap(habitMap);
    }).toList();
  }

  /// Crea un hábito: inserta en `habit`, luego en `user_habit`
  Future<HabitModel> createHabit(HabitModel habit) async {
    final userId = _userId!;

    // 1. Insertar en habit
    final habitData = await _client
        .from(AppConstants.tableHabits)
        .insert(habit.toInsertMap())
        .select()
        .single();

    final created = HabitModel.fromMap(habitData);

    // 2. Vincular con el usuario
    await _client.from(AppConstants.tableUserHabits).insert({
      'user_id':  userId,
      'habit_id': created.habitId,
    });

    return created;
  }

  /// Actualiza la definición del hábito en la tabla `habit`
  Future<HabitModel> updateHabit(HabitModel habit) async {
    final data = await _client
        .from(AppConstants.tableHabits)
        .update(habit.toUpdateMap())
        .eq('habit_id', habit.habitId)
        .select()
        .single();

    return HabitModel.fromMap(data);
  }

  /// Elimina el hábito: borra de `user_habit` y luego de `habit`
  Future<void> deleteHabit(int habitId) async {
    final userId = _userId!;

    // 1. Eliminar la vinculación usuario-hábito
    await _client
        .from(AppConstants.tableUserHabits)
        .delete()
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    // 2. Eliminar el hábito (solo si ya no lo tiene ningún otro usuario)
    final remaining = await _client
        .from(AppConstants.tableUserHabits)
        .select()
        .eq('habit_id', habitId);

    if ((remaining as List).isEmpty) {
      await _client
          .from(AppConstants.tableHabits)
          .delete()
          .eq('habit_id', habitId);
    }
  }
}

/// Provider del repositorio de hábitos
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitRepository(client);
});
