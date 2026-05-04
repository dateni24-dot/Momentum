import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';

class UserProfile {
  final String id;
  final String username;
  final int coins;
  final String evoImg;
  final String avatarName;
  final int currentXp;
  final int level;
  final int maxXp;

  const UserProfile({
    required this.id,
    required this.username,
    required this.coins,
    required this.evoImg,
    required this.avatarName,
    required this.currentXp,
    required this.level,
    required this.maxXp,
  });

  int get xpForNextLevel => maxXp;

  double get xpProgress {
    if (maxXp <= 0) return 0;
    return (currentXp / maxXp).clamp(0.0, 1.0);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    var evoImg = 'stickman_lv1';
    var avatarName = 'Stickman';
    var currentXp = 0;
    var level = 1;
    var maxXp = 200;

    final userAvatarList = map[AppConstants.tableUserAvatar];
    if (userAvatarList is List && userAvatarList.isNotEmpty) {
      final ua = userAvatarList.first as Map<String, dynamic>;
      currentXp = (ua['current_xp'] as num?)?.toInt() ?? 0;

      final evoData = ua[AppConstants.tableAvatarEvo];
      Map<String, dynamic>? evo;
      if (evoData is Map) {
        evo = evoData as Map<String, dynamic>;
      } else if (evoData is List && evoData.isNotEmpty) {
        evo = evoData.first as Map<String, dynamic>;
      }

      if (evo != null) {
        evoImg = evo['evo_img'] as String? ?? evoImg;
        level = (evo['level'] as num?)?.toInt() ?? 1;
        maxXp = (evo['max_xp'] as num?)?.toInt() ?? 200;
      }

      final av = ua[AppConstants.tableAvatars];
      if (av is Map) {
        avatarName = av['avatar_name'] as String? ?? avatarName;
      }
    }

    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String? ?? 'Usuario',
      coins: (map['coins'] as int?) ?? 0,
      evoImg: evoImg,
      avatarName: avatarName,
      currentXp: currentXp,
      level: level,
      maxXp: maxXp,
    );
  }
}

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => _fetch();

  Future<UserProfile?> _fetch() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final userData = await client
        .from(AppConstants.tableUser)
        .select('id, username, coins')
        .eq('id', userId)
        .single();

    final uaData = await client
        .from(AppConstants.tableUserAvatar)
        .select('current_xp, avatar_evo_id, avatar_id')
        .eq('user_id', userId)
        .single();

    final avatarEvoId = (uaData['avatar_evo_id'] as num?)?.toInt();
    final avatarId    = (uaData['avatar_id'] as num?)?.toInt();

    Map<String, dynamic>? evoData;
    if (avatarEvoId != null) {
      evoData = await client
          .from(AppConstants.tableAvatarEvo)
          .select('evo_img, level, max_xp')
          .eq('id', avatarEvoId)
          .maybeSingle();
    }

    Map<String, dynamic>? avatarData;
    if (avatarId != null) {
      avatarData = await client
          .from(AppConstants.tableAvatars)
          .select('avatar_name')
          .eq('avatar_id', avatarId)
          .maybeSingle();
    }

    final profile = UserProfile(
      id:         userData['id'] as String,
      username:   userData['username'] as String? ?? 'Usuario',
      coins:      (userData['coins'] as num?)?.toInt() ?? 0,
      evoImg:     evoData?['evo_img'] as String? ?? 'stickman_lv1',
      avatarName: avatarData?['avatar_name'] as String? ?? 'Stickman',
      currentXp:  (uaData['current_xp'] as num?)?.toInt() ?? 0,
      level:      (evoData?['level'] as num?)?.toInt() ?? 1,
      maxXp:      (evoData?['max_xp'] as num?)?.toInt() ?? 200,
    );

    debugPrint('PROFILE: level=${profile.level} xp=${profile.currentXp}/${profile.maxXp} evo=${profile.evoImg}');
    return profile;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final userProfileProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
