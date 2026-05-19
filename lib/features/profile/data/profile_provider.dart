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

  // DEPRECADO: este factory ya no se usa. La query embebida que lo
  // alimentaba (user → user_avatar → avatar_evo) se sustituyó en
  // _fetch() por dos selects explícitos para no depender del FK
  // embedding de PostgREST, que dejó de funcionar bien tras varios
  // refactors del esquema. Se conserva por si alguna pantalla antigua
  // necesita parsear el formato embebido; si en una limpieza futura
  // confirmas que nadie llama a UserProfile.fromMap, bórralo entero.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    var evoImg = 'stickman_lv1';
    var avatarName = 'Stickman';
    var currentXp = 0;
    var level = 1;
    var maxXp = 200;

    // PostgREST devuelve un join 1:N como List, y un join 1:1 como Map.
    // Cuando hay varias filas (caso típico: un usuario con varios avatares
    // en user_avatar) hay que elegir cuál es el "activo" — preferimos el
    // que tiene current = true. Caer al primero es un fallback defensivo:
    // si quedara basura con todos current = false, al menos algo renderiza.
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty) {
        final maps = v.whereType<Map>().toList();
        final current = maps.firstWhere(
          (m) => m['current'] == true,
          orElse: () => maps.first,
        );
        return Map<String, dynamic>.from(current);
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

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => _fetch();

  Future<UserProfile?> _fetch() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final userData = await client
        .from(AppConstants.tableUser)
        .select('id, username, coins, streak_days, streak_record')
        .eq('id', userId)
        .single();

    // Obtener el avatar activo con su avatar_evo_id explícito
    final ua = await client
        .from(AppConstants.tableUserAvatar)
        .select('current_xp, avatar_evo_id, avatar_id')
        .eq('user_id', userId)
        .eq('current', true)
        .maybeSingle();

    var evoImg     = 'stickman_lv1';
    var avatarName = 'Stickman';
    var currentXp  = 0;
    var level      = 1;
    var maxXp      = 200;

    if (ua != null) {
      currentXp = (ua['current_xp'] as num?)?.toInt() ?? 0;

      // Usar avatar_evo_id directamente — sin depender de FK embedding
      final evoId   = ua['avatar_evo_id'];
      final avatarId = ua['avatar_id'];

      final futures = await Future.wait<Map<String, dynamic>?>([
        evoId != null
          ? client
              .from(AppConstants.tableAvatarEvo)
              .select('evo_img, level, max_xp')
              .eq('id', evoId)
              .maybeSingle()
              .then((r) => r == null ? null : Map<String, dynamic>.from(r))
          : Future.value(null),
        avatarId != null
          ? client
              .from(AppConstants.tableAvatars)
              .select('avatar_name')
              .eq('avatar_id', avatarId)
              .maybeSingle()
              .then((r) => r == null ? null : Map<String, dynamic>.from(r))
          : Future.value(null),
      ]);

      final evoData    = futures[0];
      final avatarData = futures[1];

      if (evoData != null) {
        evoImg = evoData['evo_img'] as String? ?? evoImg;
        level  = (evoData['level']  as num?)?.toInt() ?? level;
        maxXp  = (evoData['max_xp'] as num?)?.toInt() ?? maxXp;
      }
      if (avatarData != null) {
        avatarName = avatarData['avatar_name'] as String? ?? avatarName;
      }
    }

    return UserProfile(
      id:           userData['id'] as String,
      username:     userData['username'] as String? ?? 'Usuario',
      coins:        (userData['coins'] as int?) ?? 0,
      evoImg:       evoImg,
      avatarName:   avatarName,
      currentXp:    currentXp,
      level:        level,
      maxXp:        maxXp,
      streakDays:   (userData['streak_days']   as num?)?.toInt() ?? 0,
      streakRecord: (userData['streak_record'] as num?)?.toInt() ?? 0,
    );
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
