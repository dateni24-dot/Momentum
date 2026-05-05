import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/achievement_model.dart';

/// Fetches all achievements with the current user's unlock status.
final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('[Achievements] userId is null, aborting');
    return [];
  }

  debugPrint('[Achievements] fetching for userId=$userId');

  late List allAchievements;
  late List userAchievements;

  try {
    allAchievements = await client
        .from(AppConstants.tableAchievements)
        .select('id, achievement_name, achievement_description, achievement_coins')
        .order('id');
    debugPrint('[Achievements] achievement rows=${allAchievements.length} data=$allAchievements');
  } catch (e, st) {
    debugPrint('[Achievements] ERROR fetching achievement table: $e\n$st');
    rethrow;
  }

  try {
    userAchievements = await client
        .from(AppConstants.tableUserAchievement)
        .select()
        .eq('user_id', userId);
    debugPrint('[Achievements] user_achievement rows=${userAchievements.length} data=$userAchievements');
  } catch (e, st) {
    debugPrint('[Achievements] ERROR fetching user_achievement table: $e\n$st');
    rethrow;
  }

  // Build lookup map: achievement_id → unlocked_at
  final unlockMap = <int, DateTime>{};
  for (final ua in userAchievements) {
    final id = (ua['achievement_id'] as num).toInt();
    final raw = ua['created_at'] as String?;
    if (raw != null) unlockMap[id] = DateTime.parse(raw).toLocal();
  }

  return allAchievements.map((m) {
    final map = m as Map<String, dynamic>;
    final id = (map['id'] as num).toInt();
    return AchievementModel.fromMap(map, unlockedAt: unlockMap[id]);
  }).toList();
});

/// Count of unlocked achievements — used in the profile stats row.
final unlockedAchievementsCountProvider = FutureProvider<int>((ref) async {
  final achievements = await ref.watch(achievementsProvider.future);
  return achievements.where((a) => a.isUnlocked).length;
});
