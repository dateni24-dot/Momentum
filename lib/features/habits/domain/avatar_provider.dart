import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo para el avatar del usuario
class UserAvatar {
  final String avatarId;
  final String avatarName;
  final String avatarEvoId;
  final String avatarEvoLevel;

  const UserAvatar({
    required this.avatarId,
    required this.avatarName,
    required this.avatarEvoId,
    required this.avatarEvoLevel,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      avatarId: json['avatar_id'].toString(),
      avatarName: json['avatar_name'] ?? 'Avatar',
      avatarEvoId: json['avatar_evo_id'].toString(),
      avatarEvoLevel: json['avatar_evo_level'] ?? '1',
    );
  }
}

/// Provider para obtener el avatar del usuario actual
final userAvatarProvider = FutureProvider<UserAvatar?>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) return null;

  try {
    final response = await client
        .from('user_avatar')
        .select('''
          avatar_id,
          avatar_evo_id,
          avatars!inner(name),
          avatar_evo!inner(level)
        ''')
        .eq('user_id', userId)
        .single();

    return UserAvatar.fromJson({
      'avatar_id': response['avatar_id'],
      'avatar_name': response['avatars']['name'],
      'avatar_evo_id': response['avatar_evo_id'],
      'avatar_evo_level': response['avatar_evo']['level'].toString(),
    });
  } catch (e) {
    // Si no hay avatar, devolver valores por defecto
    return const UserAvatar(
      avatarId: '1',
      avatarName: 'Novato',
      avatarEvoId: '1',
      avatarEvoLevel: '1',
    );
  }
});
