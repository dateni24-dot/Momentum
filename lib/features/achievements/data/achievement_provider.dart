import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/achievement_model.dart';

/// Fetches all achievements with unlock + eligibility status.
final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final allAchievements = await client
      .from(AppConstants.tableAchievements)
      .select('id, achievement_name, achievement_description, achievement_coins')
      .order('id');

  final userAchievements = await client
      .from(AppConstants.tableUserAchievement)
      .select('achievement_id')
      .eq('user_id', userId);

  final unlockedIds = {
    for (final ua in userAchievements as List)
      (ua['achievement_id'] as num).toInt(),
  };

  Set<int> eligibleIds = {};
  try {
    final eligibleResult = await client
        .rpc('get_eligible_achievement_ids', params: {'p_user_id': userId});
    eligibleIds = {
      for (final e in eligibleResult as List)
        (e['eligible_id'] as num).toInt(),
    };
  } catch (_) {
    // La función aún no existe en Supabase — se muestra sin elegibilidad
  }

  return (allAchievements as List).map((m) {
    final map = m as Map<String, dynamic>;
    final id  = (map['id'] as num).toInt();
    return AchievementModel.fromMap(
      map,
      isUnlocked: unlockedIds.contains(id),
      isEligible: !unlockedIds.contains(id) && eligibleIds.contains(id),
    );
  }).toList();
});

/// Count of unlocked achievements — used in the profile stats row.
final unlockedAchievementsCountProvider = FutureProvider<int>((ref) async {
  final achievements = await ref.watch(achievementsProvider.future);
  return achievements.where((a) => a.isUnlocked).length;
});

/// Claims a specific achievement and awards its coins to the user.
Future<void> claimAchievement(WidgetRef ref, int achievementId) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;

  await client.rpc('claim_achievement', params: {
    'p_user_id':        userId,
    'p_achievement_id': achievementId,
  });

  ref.invalidate(achievementsProvider);
  ref.invalidate(unlockedAchievementsCountProvider);
}
