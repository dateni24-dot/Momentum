import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Momentum';
  static const String appVersion = '1.0.0';

  // ── Debug ──────────────────────────────────────────────────────────────
  // En modo debug los minutos se tratan como segundos para testear rápido.
  // En release esto es siempre false.
  static const bool debugFastTimer = kDebugMode;

  // Supabase tables (nombres exactos del esquema real)
  static const String tableUser            = 'user';
  static const String tableHabits          = 'habit';
  static const String tableUserHabits      = 'user_habit';
  static const String tableAvatars         = 'avatars';
  static const String tableAvatarEvo       = 'avatar_evo';
  static const String tableUserAvatar      = 'user_avatar';
  static const String tableAchievements    = 'achievement';
  static const String tableUserAchievement = 'user_achievement';
  static const String tableStatistic       = 'statistic';
  static const String tableUserStatistic   = 'user_statistic';

  // Validation - auth
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 10;
  static const int passwordMinLength = 8;

  // Validation - habits
  static const int habitNameMinLength = 2;
  static const int habitNameMaxLength = 50;
}
