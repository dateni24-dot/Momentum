import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// AvatarRegistry — resuelve dinámicamente el evo_img de la BD
//
// Convención: evo_img == nombre del fichero sin extensión dentro de assets/avatars/
// El nivel se extrae del sufijo _lv<N> o _lvl<N> (ej. stickman_lv2, chica_lvl1).
// Para añadir un nuevo avatar basta con poner el GIF en assets/avatars/ — no
// hace falta tocar este archivo.
// ---------------------------------------------------------------------------

abstract final class AvatarRegistry {
  // Patrón que captura el número de nivel al final de la clave (_lv1, _lvl1, etc.)
  static final _levelRe = RegExp(r'_lvl?(\d+)$');

  static Widget forKey(String key, {double size = 80}) {
    return _GifAvatar(asset: 'assets/avatars/$key.png', size: size);
  }

  static String labelForKey(String key) {
    final match  = _levelRe.firstMatch(key);
    final level  = match?.group(1) ?? '1';
    final name   = key.replaceAll(_levelRe, '').replaceAll('_', ' ');
    final titled = name[0].toUpperCase() + name.substring(1);
    return 'Nivel $level · $titled';
  }

  static Color glowColorForKey(String key) {
    final level = int.tryParse(_levelRe.firstMatch(key)?.group(1) ?? '1') ?? 1;
    if (level >= 3) return Colors.cyanAccent;
    if (level == 2) return Colors.amber;
    return AppColors.primary;
  }
}

// ---------------------------------------------------------------------------
// Widget interno que renderiza la imagen del avatar
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
      // low es suficiente a los tamaños a los que se renderizan los
      // avatares (68-150 px). medium aplica un filtro bilineal extra
      // que solo se nota a tamaños grandes y cuesta CPU por frame —
      // crítico en el carrusel de la tienda que repinta cada 2.2s.
      filterQuality: FilterQuality.low,
    );
  }
}
