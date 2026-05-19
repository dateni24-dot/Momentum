import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/shop_provider.dart';
import '../../profile/presentation/widgets/avatar_registry.dart';
import '../../profile/data/profile_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync    = ref.watch(avatarShopProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShopHeader(coins: profileAsync.valueOrNull?.coins ?? 0),
                Expanded(
                  child: shopAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) => _ErrorView(
                      onRetry: () => ref.invalidate(avatarShopProvider),
                    ),
                    data: (avatars) => avatars.isEmpty
                        ? const _EmptyState()
                        : _AvatarGrid(avatars: avatars),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header con título y saldo de monedas
// ---------------------------------------------------------------------------

class _ShopHeader extends StatelessWidget {
  final int coins;
  const _ShopHeader({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tienda',
                style: TextStyle(
                  color:      AppColors.textPrimary,
                  fontSize:   26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Saldo de monedas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:        const Color(0xFFFFC107).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFC107),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color:      Color(0xFFFFC107),
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Avatares para personalizar tu perfil',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid de avatares
// ---------------------------------------------------------------------------

class _AvatarGrid extends StatelessWidget {
  final List<ShopAvatar> avatars;
  const _AvatarGrid({required this.avatars});

  static int _columns(double width) {
    if (width >= 900) return 4;
    if (width >= 580) return 3;
    return 2;
  }

  // Ratio más ancho en pantallas grandes para que ~2 filas queden visibles
  static double _ratio(int cols) {
    if (cols == 4) return 0.82;
    if (cols == 3) return 0.76;
    return 0.72;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols  = _columns(constraints.maxWidth);
        final ratio = _ratio(cols);
        final gap   = cols >= 3 ? 16.0 : 14.0;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(20, 0, 20, cols >= 3 ? 40 : 100),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   cols,
            mainAxisSpacing:  gap,
            crossAxisSpacing: gap,
            childAspectRatio: ratio,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + index * 60),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child:  Opacity(opacity: value, child: child),
              ),
              child: _AvatarCard(avatar: avatars[index]),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de avatar
// ---------------------------------------------------------------------------

class _AvatarCard extends ConsumerWidget {
  final ShopAvatar avatar;
  const _AvatarCard({required this.avatar});

  Color get _borderColor {
    if (avatar.isCurrent)   return AppColors.primary;
    if (avatar.isPurchased) return Colors.amber;
    return AppColors.border;
  }

  Color get _glowColor {
    if (avatar.isCurrent)   return AppColors.primary;
    if (avatar.isPurchased) return Colors.amber;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final coins        = profileAsync.valueOrNull?.coins ?? 0;
    final canAfford    = coins >= avatar.price;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: avatar.isCurrent ? 2 : 1),
        boxShadow: avatar.isCurrent || avatar.isPurchased
            ? [BoxShadow(color: _glowColor.withValues(alpha: 0.25), blurRadius: 12)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview del avatar (carrusel + badge de nivel)
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _AvatarCarouselPreview(
                    levels: avatar.previewLevels,
                    size:   90,
                  ),
                ),
                if (avatar.isCurrent)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Equipado',
                        style: TextStyle(
                          color:      Colors.black,
                          fontSize:   10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info + acción
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avatar.name,
                    style: const TextStyle(
                      color:      AppColors.textPrimary,
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    avatar.description,
                    style: const TextStyle(
                      color:    AppColors.textSecondary,
                      fontSize: 11,
                      height:   1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  _ActionButton(
                    avatar:     avatar,
                    canAfford:  canAfford,
                    onPurchase: () => _onPurchase(context, ref),
                    onEquip:    () => _onEquip(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPurchase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Comprar avatar?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Gastarás ${avatar.price} monedas para desbloquear "${avatar.name}".',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Comprar',
                style: TextStyle(
                    color: Color(0xFFFFC107), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(avatarShopProvider.notifier)
        .purchaseAvatar(avatar);

    if (!context.mounted) return;
    _showSnack(context, error ?? '¡Avatar desbloqueado!', isError: error != null);
  }

  Future<void> _onEquip(BuildContext context, WidgetRef ref) async {
    final error = await ref
        .read(avatarShopProvider.notifier)
        .equipAvatar(avatar.id);

    if (!context.mounted) return;
    _showSnack(context, error ?? '¡Avatar equipado!', isError: error != null);
  }

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botón de acción adaptable al estado del avatar
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final ShopAvatar   avatar;
  final bool         canAfford;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const _ActionButton({
    required this.avatar,
    required this.canAfford,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    if (avatar.isCurrent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 14),
            SizedBox(width: 5),
            Text(
              'En uso',
              style: TextStyle(
                color:      AppColors.primary,
                fontSize:   12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (avatar.isPurchased) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onEquip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding:         const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          child: const Text('Equipar'),
        ),
      );
    }

    // No comprado
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAfford ? onPurchase : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford
              ? const Color(0xFFFFC107)
              : AppColors.surface,
          foregroundColor: canAfford ? Colors.black : AppColors.textDisabled,
          padding:  const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.monetization_on_rounded, size: 13),
        label: Text('${avatar.price}'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados vacíos y de error
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_outlined, color: AppColors.textSecondary, size: 56),
          SizedBox(height: 16),
          Text(
            'La tienda está vacía',
            style: TextStyle(
              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Próximamente habrá avatares disponibles.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carrusel automático de evoluciones del avatar (niveles 1, 5, 10)
// ---------------------------------------------------------------------------

class _AvatarCarouselPreview extends StatefulWidget {
  final List<AvatarPreview> levels;
  final double size;

  const _AvatarCarouselPreview({
    required this.levels,
    required this.size,
  });

  @override
  State<_AvatarCarouselPreview> createState() => _AvatarCarouselPreviewState();
}

class _AvatarCarouselPreviewState extends State<_AvatarCarouselPreview> {
  static const _interval = Duration(milliseconds: 2200);
  static const _fade     = Duration(milliseconds: 500);

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _AvatarCarouselPreview old) {
    super.didUpdateWidget(old);
    if (old.levels.length != widget.levels.length) {
      _index = 0;
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    if (widget.levels.length <= 1) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.levels.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levels.isEmpty) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final current = widget.levels[_index];

    return SizedBox(
      width:  widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Imagen con fade-in/fade-out al cambiar de nivel
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: _fade,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: SizedBox.expand(
                key: ValueKey(current.evoImg),
                child: AvatarRegistry.forKey(current.evoImg, size: widget.size),
              ),
            ),
          ),
          // Badge de nivel en la esquina inferior izquierda
          Positioned(
            left: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: _fade,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _LevelBadge(
                key:   ValueKey(current.level),
                level: current.level,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        'Nv. $level',
        style: const TextStyle(
          color:        Colors.white,
          fontSize:     10,
          fontWeight:   FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la tienda',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon:  const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
