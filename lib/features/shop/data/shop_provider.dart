import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import '../../profile/data/profile_provider.dart';

/// Una evolución que la carta de tienda puede mostrar como preview.
class AvatarPreview {
  final int    level;
  final String evoImg;
  const AvatarPreview({required this.level, required this.evoImg});
}

class ShopAvatar {
  final String id;
  final String name;
  final String description;
  final int price;
  final bool isPurchased;
  final bool isCurrent;
  /// Niveles 1, 5 y 10 (los que existan) para mostrar en carrusel automático.
  final List<AvatarPreview> previewLevels;

  const ShopAvatar({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isPurchased,
    required this.isCurrent,
    required this.previewLevels,
  });
}

class AvatarShopNotifier
    extends AutoDisposeAsyncNotifier<List<ShopAvatar>> {
  @override
  Future<List<ShopAvatar>> build() => _fetch();

  Future<List<ShopAvatar>> _fetch() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    // Las dos queries son independientes → en paralelo para ahorrar un
    // round-trip al abrir la tienda.
    final results = await Future.wait([
      client
          .from('avatars')
          .select('avatar_id, avatar_name, avatar_descript, avatar_price, avatar_evo(evo_img, level)')
          .order('avatar_price'),
      client
          .from('user_avatar')
          .select('avatar_id, current, avatar_evo_id')
          .eq('user_id', userId),
    ]);
    final allAvatars = results[0] as List<dynamic>;
    final ownedRows  = results[1] as List<dynamic>;

    final isPurchasedMap = <String, bool>{};
    final isCurrentMap   = <String, bool>{};

    for (final row in ownedRows) {
      final id = row['avatar_id'].toString();
      isPurchasedMap[id] = true;
      isCurrentMap[id]   = row['current'] == true;
    }

    return allAvatars.map<ShopAvatar>((a) {
      final id = a['avatar_id'].toString();

      // Construir mapa level → evo_img de las evoluciones devueltas en el join
      final allEvos = <int, String>{};
      final evoData = a['avatar_evo'];
      if (evoData is List) {
        for (final e in evoData) {
          final lvl = (e['level'] as num?)?.toInt();
          final img = e['evo_img'] as String?;
          if (lvl != null && img != null) allEvos[lvl] = img;
        }
      } else if (evoData is Map) {
        final lvl = (evoData['level'] as num?)?.toInt();
        final img = evoData['evo_img'] as String?;
        if (lvl != null && img != null) allEvos[lvl] = img;
      }

      // Carrusel: niveles 1, 5 y 10 (los que existan). Fallback al primero disponible.
      final previewLevels = <AvatarPreview>[
        for (final lvl in const [1, 5, 10])
          if (allEvos.containsKey(lvl))
            AvatarPreview(level: lvl, evoImg: allEvos[lvl]!),
      ];
      if (previewLevels.isEmpty && allEvos.isNotEmpty) {
        final firstLvl = allEvos.keys.first;
        previewLevels.add(AvatarPreview(level: firstLvl, evoImg: allEvos[firstLvl]!));
      }

      return ShopAvatar(
        id:            id,
        name:          a['avatar_name'] as String? ?? '',
        description:   a['avatar_descript'] as String? ?? '',
        price:         (a['avatar_price'] as int?) ?? 0,
        isPurchased:   isPurchasedMap.containsKey(id),
        isCurrent:     isCurrentMap[id] == true,
        previewLevels: previewLevels,
      );
    }).toList();
  }

  /// Compra un avatar. Devuelve un mensaje de error o null si fue exitoso.
  ///
  /// LIMITACIÓN CONOCIDA: esta operación NO es atómica. Se lee
  /// profile.coins, se compara con avatar.price, se descuenta vía
  /// UPDATE y luego se inserta la fila en user_avatar — todo en
  /// requests separadas. Si el usuario hace doble-tap muy rápido o
  /// dos clientes están abiertos a la vez, podría comprar dos avatares
  /// con un solo balance (o quedarse con coins negativas si el UPDATE
  /// de descuento no protege contra ello). Para hacerlo robusto habría
  /// que envolverlo en una RPC server-side con un WHERE coins >= price
  /// en el UPDATE y comprobar el `count` de filas afectadas. Por ahora
  /// es aceptable porque el riesgo en producción es bajo y las coins
  /// no son moneda real, pero documentado para que conste.
  Future<String?> purchaseAvatar(ShopAvatar avatar) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 'Usuario no autenticado';

    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) return 'No se pudo cargar tu perfil';
    if (profile.coins < avatar.price) return 'Monedas insuficientes';

    try {
      // Descontar monedas
      await client
          .from('user')
          .update({'coins': profile.coins - avatar.price})
          .eq('id', userId);

      // Obtener el avatar_evo_id de nivel 1 para este avatar
      final evo = await client
          .from('avatar_evo')
          .select('id')
          .eq('avatar_id', avatar.id)
          .eq('level', 1)
          .single();

      // Insertar en user_avatar (no se equipa automáticamente)
      await client.from('user_avatar').insert({
        'user_id':       userId,
        'avatar_id':     avatar.id,
        'avatar_evo_id': evo['id'],
        'current_xp':    0,
        'current':       false,
      });

      ref.invalidate(userProfileProvider);
      state = await AsyncValue.guard(_fetch);
      return null;
    } catch (e) {
      return 'Error al comprar: $e';
    }
  }

  /// Equipa un avatar que ya posee el usuario. Devuelve error o null si OK.
  Future<String?> equipAvatar(String avatarId) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 'Usuario no autenticado';

    try {
      // Desequipar todos los avatares del usuario
      await client
          .from('user_avatar')
          .update({'current': false})
          .eq('user_id', userId);

      // Equipar el seleccionado
      await client
          .from('user_avatar')
          .update({'current': true})
          .eq('user_id', userId)
          .eq('avatar_id', avatarId);

      ref.invalidate(userProfileProvider);
      state = await AsyncValue.guard(_fetch);
      return null;
    } catch (e) {
      return 'Error al equipar el avatar';
    }
  }
}

final avatarShopProvider =
    AsyncNotifierProvider.autoDispose<AvatarShopNotifier, List<ShopAvatar>>(
  AvatarShopNotifier.new,
);
