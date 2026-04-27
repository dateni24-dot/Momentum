import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';

class UserProfile {
  final String id;
  final String username;
  final int coins;
  final String evoImg;
  final String avatarName;

  const UserProfile({
    required this.id,
    required this.username,
    required this.coins,
    required this.evoImg,
    required this.avatarName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Valores por defecto si no hay avatar asignado aún
    var evoImg = 'stickman_lv1';
    var avatarName = 'Stickman';

    // JOIN: user -> user_avatar -> avatar_evo / avatars
    final userAvatarList = map[AppConstants.tableUserAvatar];
    if (userAvatarList is List && userAvatarList.isNotEmpty) {
      final ua = userAvatarList.first as Map<String, dynamic>;

      final evo = ua[AppConstants.tableAvatarEvo];
      if (evo is Map) {
        evoImg = evo['evo_img'] as String? ?? evoImg;
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
    );
  }
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  // Cargamos el perfil con el avatar y su evolución en una sola consulta
  final data = await client
      .from(AppConstants.tableUser)
      .select('''
        id,
        username,
        coins,
        user_avatar(
          avatar_evo(evo_img),
          avatars(avatar_name)
        )
      ''')
      .eq('id', userId)
      .single();

  return UserProfile.fromMap(data);
});
