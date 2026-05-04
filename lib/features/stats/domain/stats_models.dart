/// Estadísticas agregadas de un hábito en un mes.
class HabitStat {
  final int habitId;
  final String habitName;
  final int timesCompleted;
  final int totalMinutes;
  final int totalXp;

  const HabitStat({
    required this.habitId,
    required this.habitName,
    required this.timesCompleted,
    required this.totalMinutes,
    required this.totalXp,
  });

  factory HabitStat.fromMap(Map<String, dynamic> m) => HabitStat(
        habitId:        (m['habit_id'] as num?)?.toInt() ?? 0,
        habitName:      m['habit_name'] as String? ?? 'Hábito eliminado',
        timesCompleted: (m['veces'] as num).toInt(),
        totalMinutes:   (m['minutos_totales'] as num).toInt(),
        totalXp:        (m['xp_totales'] as num).toInt(),
      );
}

/// Una entrada del historial: hábito completado en una fecha concreta.
class HistoryEntry {
  final String habitName;
  final int durationMin;
  final DateTime startedAt;
  final DateTime completedAt;
  final int xpEarned;
  final double multiplier;

  const HistoryEntry({
    required this.habitName,
    required this.durationMin,
    required this.startedAt,
    required this.completedAt,
    required this.xpEarned,
    required this.multiplier,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> m) => HistoryEntry(
        habitName:   m['habit_name'] as String? ?? 'Hábito eliminado',
        durationMin: (m['duration_min'] as num).toInt(),
        startedAt:   DateTime.parse(m['started_at'] as String).toLocal(),
        completedAt: DateTime.parse(m['completed_at'] as String).toLocal(),
        xpEarned:    (m['xp_earned'] as num).toInt(),
        multiplier:  (m['multiplier'] as num).toDouble(),
      );
}
