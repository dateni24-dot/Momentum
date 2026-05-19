import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/habit_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../achievements/domain/achievement_model.dart';
import '../../auth/data/auth_provider.dart';

/// Repositorio CRUD de hábitos.
/// La tabla `habit` almacena la definición del hábito.
/// La tabla `user_habit` vincula cada hábito con su usuario.
class HabitRepository {
  HabitRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve los hábitos del usuario con estado de timer (completed, started_at)
  Future<List<HabitModel>> fetchHabits() async {
    final userId = _userId;
    if (userId == null) return [];

    final data = await _client
        .from(AppConstants.tableUserHabits)
        .select('completed, started_at, ${AppConstants.tableHabits}(*)')
        .eq('user_id', userId)
        .order('created_at', referencedTable: AppConstants.tableHabits,
            ascending: true);

    return (data as List<dynamic>).map((row) {
      final habitMap = {
        ...row[AppConstants.tableHabits] as Map<String, dynamic>,
        'completed':  row['completed'],
        'started_at': row['started_at'],
      };
      return HabitModel.fromMap(habitMap);
    }).toList();
  }

  /// Crea un hábito: inserta en `habit`, luego en `user_habit`
  Future<HabitModel> createHabit(HabitModel habit) async {
    final userId = _userId!;

    final habitData = await _client
        .from(AppConstants.tableHabits)
        .insert(habit.toInsertMap())
        .select()
        .single();

    final created = HabitModel.fromMap(habitData);

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

    await _client
        .from(AppConstants.tableUserHabits)
        .delete()
        .eq('habit_id', habitId)
        .eq('user_id', userId);

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

  /// Inicia el temporizador del hábito guardando el timestamp actual en Supabase.
  /// Al reabrir la app se recalcula el tiempo restante desde started_at.
  Future<HabitModel> startCooldownHabit(int habitId) async {
    final userId = _userId!;
    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from(AppConstants.tableUserHabits)
        .update({'started_at': now, 'completed': false})
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    final data = await _client
        .from(AppConstants.tableUserHabits)
        .select('completed, started_at, ${AppConstants.tableHabits}(*)')
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .single();

    final habitMap = {
      ...data[AppConstants.tableHabits] as Map<String, dynamic>,
      'completed':  data['completed'],
      'started_at': data['started_at'],
    };
    return HabitModel.fromMap(habitMap);
  }

  /// Cancela un hábito iniciado: resetea started_at a NULL y completed a false.
  /// No otorga XP. Útil cuando el usuario inicia un hábito por error.
  Future<HabitModel> cancelHabit(int habitId) async {
    final userId = _userId!;

    await _client
        .from(AppConstants.tableUserHabits)
        .update({'started_at': null, 'completed': false})
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    final data = await _client
        .from(AppConstants.tableUserHabits)
        .select('completed, started_at, ${AppConstants.tableHabits}(*)')
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .single();

    final habitMap = {
      ...data[AppConstants.tableHabits] as Map<String, dynamic>,
      'completed':  data['completed'],
      'started_at': data['started_at'],
    };
    return HabitModel.fromMap(habitMap);
  }

  /// Devuelve los logros recién desbloqueados, o [] si la RPC falla.
  /// Aislado para poder pasarlo a Future.wait sin perder el catch.
  Future<List<UnlockedAchievement>> _fetchNewAchievements(String userId) async {
    try {
      final result = await _client.rpc(
        'check_and_grant_achievements',
        params: {'p_user_id': userId},
      );
      if (result == null) return const [];
      return (result as List)
          .map((m) => UnlockedAchievement.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Marca el hábito como completado, actualiza la racha y otorga XP con multiplicador.
  /// [baseXp] = habit.time * 2 (ej: 30 min → 60 XP base).
  /// Solo debe llamarse cuando habit.isReadyToComplete == true.
  Future<CompleteHabitResult> completeHabit(int habitId, int baseXp) async {
    final userId = _userId!;

    await _client
        .from(AppConstants.tableUserHabits)
        .update({'completed': true})
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    final rpcResult = await _client.rpc('complete_habit_with_streak', params: {
      'p_user_id':  userId,
      'p_habit_id': habitId,
      'p_base_xp':  baseXp,
    }) as Map<String, dynamic>;

    // Refetch del hábito y check de logros son independientes entre sí:
    // se lanzan en paralelo para ahorrar un round-trip al completar.
    //
    // El catch del check de logros se traga el error a propósito: si
    // la RPC falla (red caída, permisos, función mal versionada en
    // Supabase) NO queremos abortar la finalización del hábito, que ya
    // está persistida arriba. El coste es que un bug server-side en
    // check_and_grant_achievements se vuelve invisible — fue así como
    // el bug de monedas pasó desapercibido semanas. Si en el futuro
    // añades lógica crítica (p.ej. anti-cheat), súbela a
    // complete_habit_with_streak en lugar de a check_and_grant_achievements.
    // Ambos Futures se crean (y empiezan) aquí. El primer await bloquea
    // hasta que la consulta termine, pero achievementsFuture ha estado
    // ejecutándose en paralelo todo este tiempo → al llegar al segundo
    // await, normalmente ya está resuelto.
    final dataFuture = _client
        .from(AppConstants.tableUserHabits)
        .select('completed, started_at, ${AppConstants.tableHabits}(*)')
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .single();
    final achievementsFuture = _fetchNewAchievements(userId);

    final data            = await dataFuture;
    final newAchievements = await achievementsFuture;

    final habitMap = {
      ...data[AppConstants.tableHabits] as Map<String, dynamic>,
      'completed':  data['completed'],
      'started_at': data['started_at'],
    };

    return CompleteHabitResult(
      habit:           HabitModel.fromMap(habitMap),
      xpAwarded:       (rpcResult['xp_awarded']  as num).toInt(),
      multiplier:      (rpcResult['multiplier']   as num).toDouble(),
      streakDays:      (rpcResult['streak_days']  as num).toInt(),
      isMilestone:     rpcResult['is_milestone']  as bool,
      leveledUp:       rpcResult['leveled_up']    as bool? ?? false,
      newAchievements: newAchievements,
    );
  }
}

/// Datos que devuelve completeHabit (hábito actualizado + info de racha + logros)
class CompleteHabitResult {
  final HabitModel habit;
  final int xpAwarded;
  final double multiplier;
  final int streakDays;
  final bool isMilestone;
  final bool leveledUp;
  final List<UnlockedAchievement> newAchievements;

  const CompleteHabitResult({
    required this.habit,
    required this.xpAwarded,
    required this.multiplier,
    required this.streakDays,
    required this.isMilestone,
    required this.leveledUp,
    this.newAchievements = const [],
  });
}

/// Provider del repositorio de hábitos
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitRepository(client);
});
