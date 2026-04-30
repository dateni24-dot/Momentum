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
  final int streakDays;   // días consecutivos activos
  final int streakRecord; // récord histórico de racha

  const UserProfile({
    required this.id,
    required this.username,
    required this.coins,
    required this.evoImg,
    required this.avatarName,
    required this.currentXp,
    required this.level,
    required this.maxXp,
    this.streakDays   = 0,
    this.streakRecord = 0,
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

    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty && v.first is Map) {
        return Map<String, dynamic>.from(v.first as Map);
      }
      return null;
    }

    final ua = asMap(map[AppConstants.tableUserAvatar]);
    if (ua != null) {
      currentXp = (ua['current_xp'] as num?)?.toInt() ?? 0;

      final evo = asMap(ua[AppConstants.tableAvatarEvo]);
      if (evo != null) {
        evoImg = evo['evo_img'] as String? ?? evoImg;
        level  = (evo['level']  as num?)?.toInt() ?? 1;
        maxXp  = (evo['max_xp'] as num?)?.toInt() ?? 200;
      }

      final av = asMap(ua[AppConstants.tableAvatars]);
      if (av != null) {
        avatarName = av['avatar_name'] as String? ?? avatarName;
      }
    }

    return UserProfile(
      id:           map['id'] as String,
      username:     map['username'] as String? ?? 'Usuario',
      coins:        (map['coins'] as int?) ?? 0,
      evoImg:       evoImg,
      avatarName:   avatarName,
      currentXp:    currentXp,
      level:        level,
      maxXp:        maxXp,
      streakDays:   (map['streak_days']   as num?)?.toInt() ?? 0,
      streakRecord: (map['streak_record'] as num?)?.toInt() ?? 0,
    );
  }
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await client
      .from(AppConstants.tableUser)
      .select('''
        id,
        username,
        coins,
        streak_days,
        streak_record,
        user_avatar(
          current_xp,
          avatar_evo!fk_user_avatar_avatar_evo(evo_img, level, max_xp),
          avatars(avatar_name)
        )
      ''')
      .eq('id', userId)
      .single();

  return UserProfile.fromMap(data);
});
