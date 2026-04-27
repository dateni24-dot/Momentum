import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// AvatarRegistry — mapea el identificador evo_img de la BD al widget correcto
//
// evo_img guarda una clave string ('stickman_lv1', 'warrior_lv1', etc.).
// Todos los avatares son .gif animados en assets/avatars/.
// ---------------------------------------------------------------------------

abstract final class AvatarRegistry {
  static Widget forKey(String key, {double size = 80}) {
    switch (key) {
      case 'stickman_lv1':
        return _GifAvatar(
            asset: 'assets/avatars/stickman_lv1.gif', size: size);
      case 'stickman_lv2':
        return _GifAvatar(
            asset: 'assets/avatars/stickman_lv2.gif', size: size);
      case 'stickman_lv3':
        return _GifAvatar(
            asset: 'assets/avatars/stickman_lv3.gif', size: size);
      default:
        return _GifAvatar(
            asset: 'assets/avatars/stickman_lv1.gif', size: size);
    }
  }

  static String labelForKey(String key) {
    switch (key) {
      case 'stickman_lv1': return 'Nivel 1 · Stickman';
      case 'stickman_lv2': return 'Nivel 2 · Stickman';
      case 'stickman_lv3': return 'Nivel 3 · Stickman';
      default:             return 'Nivel 1 · Stickman';
    }
  }

  static Color glowColorForKey(String key) {
    switch (key) {
      case 'stickman_lv2': return Colors.amber;
      case 'stickman_lv3': return Colors.cyanAccent;
      default:             return AppColors.primary;
    }
  }
}

// ---------------------------------------------------------------------------
// Widget interno que renderiza un .gif como avatar
// ---------------------------------------------------------------------------

class _GifAvatar extends StatelessWidget {
  final String asset;
  final double size;

  const _GifAvatar({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.medium,
    );
  }
}
