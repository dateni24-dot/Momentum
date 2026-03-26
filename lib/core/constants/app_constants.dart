class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Momentum';
  static const String appVersion = '1.0.0';

  // Supabase tables
  static const String tableProfiles = 'profiles';
  static const String tableHabits = 'habits';
  static const String tableAvatars = 'avatars';
  static const String tableAchievements = 'achievements';
  static const String tableUserAvatars = 'user_avatars';
  static const String tableUserAchievements = 'user_achievements';
  static const String tableHabitSessions = 'habit_sessions';

  // Validation
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 10;
  static const int passwordMinLength = 8;
}
