import 'package:flutter/material.dart';

/// Opciones de duración en minutos para un hábito
class HabitDuration {
  HabitDuration._();

  static const List<int> options = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  static String label(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

/// Colores deterministas para las tarjetas (basados en habit_id % longitud)
class HabitColors {
  HabitColors._();

  static const List<Color> palette = [
    Color(0xFF5DBE2A), // Verde Momentum
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Púrpura
    Color(0xFFFF5722), // Naranja
    Color(0xFFF44336), // Rojo
    Color(0xFFFFC107), // Ámbar
    Color(0xFF2196F3), // Azul
    Color(0xFFE91E63), // Rosa
  ];

  /// Devuelve un color consistente para un hábito según su ID
  static Color forHabit(int habitId) {
    return palette[habitId % palette.length];
  }
}

/// Modelo de hábito que refleja el esquema real de Supabase:
/// tabla `habit` + tabla `user_habit`
class HabitModel {
  final int habitId;
  final String habitName;
  final String? habitDescript;
  /// Duración objetivo en minutos (columna `time` int2)
  final int time;
  final DateTime createdAt;

  const HabitModel({
    required this.habitId,
    required this.habitName,
    this.habitDescript,
    required this.time,
    required this.createdAt,
  });

  /// Construye un HabitModel desde una fila de Supabase
  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      habitId:      map['habit_id'] as int,
      habitName:    map['habit_name'] as String,
      habitDescript: map['habit_descript'] as String?,
      time:         map['time'] as int,
      createdAt:    DateTime.parse(map['created_at'] as String),
    );
  }

  /// Map para insertar en la tabla `habit`
  Map<String, dynamic> toInsertMap() {
    return {
      'habit_name':   habitName,
      'habit_descript': habitDescript,
      'time':         time,
    };
  }

  /// Map para actualizar en la tabla `habit`
  Map<String, dynamic> toUpdateMap() {
    return {
      'habit_name':   habitName,
      'habit_descript': habitDescript,
      'time':         time,
    };
  }

  HabitModel copyWith({
    String? habitName,
    String? habitDescript,
    int? time,
  }) {
    return HabitModel(
      habitId:       habitId,
      habitName:     habitName      ?? this.habitName,
      habitDescript: habitDescript  ?? this.habitDescript,
      time:          time           ?? this.time,
      createdAt:     createdAt,
    );
  }
}
