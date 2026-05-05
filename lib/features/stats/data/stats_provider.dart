import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/stats_models.dart';

/// Mes seleccionado en formato 'YYYY-MM'. Null = mes actual.
final selectedMonthProvider = StateProvider<String?>((ref) => null);

/// Lista de meses con actividad ordenada de más reciente a más antigua.
final availableMonthsProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('habit_completion')
      .select('completed_at')
      .eq('user_id', userId);
  // Extraemos los meses únicos en formato 'YYYY-MM'.
  final months = <String>{};
  for (final row in data as List) {
    final dt = DateTime.parse((row as Map)['completed_at'] as String).toLocal();
    final m = '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
    months.add(m);
  }
  // Ordenamos de más reciente a más antigua.
  final list = months.toList()..sort((a, b) => b.compareTo(a));
  return list;
});

/// Stats por hábito del mes seleccionado (o el actual si no hay selección).
final habitStatsProvider = FutureProvider<List<HabitStat>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];
  // Si no hay mes seleccionado, usamos el mes actual.
  final selected = ref.watch(selectedMonthProvider);
  final now = DateTime.now();
  final month = selected ??
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  final data = await client.rpc('habit_stats_for_month', params: {
    'p_month': month,
  });
 // El RPC devuelve una lista de objetos con: habit_name, total_completions, total_duration_min, total_xp_earned.
  return (data as List)
      .map((m) => HabitStat.fromMap(m as Map<String, dynamic>))
      .toList();
});

/// Historial cronológico de las últimas 100 finalizaciones.
final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('habit_completion')
      .select(
          'habit_name, duration_min, started_at, completed_at, xp_earned, multiplier')
      .eq('user_id', userId)
      .order('completed_at', ascending: false)
      .limit(100);

  return (data as List)
      .map((m) => HistoryEntry.fromMap(m as Map<String, dynamic>))
      .toList();
});
