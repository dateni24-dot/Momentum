import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../stats/presentation/stats_screen.dart';
import '../data/profile_provider.dart';
import 'change_password_screen.dart';
import 'change_username_screen.dart';
import 'delete_account_screen.dart';
import 'widgets/avatar_registry.dart';

// ---------------------------------------------------------------------------
// ProfileScreen — contenido embebido en el tab "Perfil" del HomeScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => const _ProfileError(),
      data: (profile) => profile == null
          ? const _ProfileError()
          : _ProfileContent(profile: profile),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido principal del perfil
// ---------------------------------------------------------------------------

class _ProfileContent extends StatelessWidget {
  final UserProfile profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          // ── Header con avatar ──────────────────────────────────────────
          _ProfileHeader(profile: profile),

          const SizedBox(height: 32),

          // ── Stats row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _StatsRow(
              coins:  profile.coins,
              streak: profile.streakDays,
            ),
          ),

          const SizedBox(height: 32),

          // ── Sección actividad ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionCard(
              title: 'Actividad',
              items: [
                _SettingItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Estadísticas e historial',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sección cuenta ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionCard(
              title: 'Mi Cuenta',
              items: [
                _SettingItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Cambiar nombre de usuario',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Cambiar contraseña',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar mi cuenta',
                  danger: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sección avatar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SectionCard(
              title: 'Avatar',
              items: const [
                _SettingItem(
                  icon: Icons.storefront_outlined,
                  label: 'Tienda de avatares',
                  comingSoon: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: círculo con stickman + nombre + nivel
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        children: [
          // Título
          const Text(
            'Mi Perfil',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 28),

          // Avatar con ring de progreso XP alrededor
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ring de progreso XP (anillo exterior)
                CustomPaint(
                  size: const Size(168, 168),
                  painter: _XpRingPainter(
                    progress: profile.xpProgress,
                    color: AvatarRegistry.glowColorForKey(profile.evoImg),
                  ),
                ),
                // Avatar circular (interior)
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AvatarRegistry.glowColorForKey(profile.evoImg)
                            .withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AvatarRegistry.glowColorForKey(profile.evoImg)
                            .withValues(alpha: 0.12),
                        blurRadius: 60,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AvatarRegistry.forKey(profile.evoImg, size: 150),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Username
          Text(
            profile.username,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          // Nivel badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              AvatarRegistry.labelForKey(profile.evoImg),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Barra horizontal de XP + texto
          _XpBar(
            currentXp: profile.currentXp,
            xpForNextLevel: profile.xpForNextLevel,
            color: AvatarRegistry.glowColorForKey(profile.evoImg),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila de estadísticas
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final int coins;
  final int streak;
  const _StatsRow({required this.coins, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.monetization_on_outlined,
            value: '$coins',
            label: 'Monedas',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_outlined,
            value: '$streak',
            label: 'Racha',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_outlined,
            value: '0',
            label: 'Logros',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de sección con opciones
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    indent: 54,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool comingSoon;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.comingSoon = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.textPrimary;

    return InkWell(
      onTap: onTap ??
          (comingSoon
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.construction_rounded,
                              color: AppColors.primary, size: 16),
                          SizedBox(width: 8),
                          Text('Próximamente'),
                        ],
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
              : null),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: danger ? Colors.redAccent : AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 15),
              ),
            ),
            if (comingSoon)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pronto',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _XpRingPainter — anillo circular de progreso de XP alrededor del avatar
// ---------------------------------------------------------------------------

class _XpRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  const _XpRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    // Anillo de fondo (atenuado)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Arco de progreso
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);

      const startAngle = -math.pi / 2; // arranca arriba
      final sweepAngle = progress * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_XpRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// _XpBar — barra horizontal de progreso con texto "X / Y XP"
// ---------------------------------------------------------------------------

class _XpBar extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final Color color;

  const _XpBar({
    required this.currentXp,
    required this.xpForNextLevel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpForNextLevel <= 0
        ? 0.0
        : (currentXp / xpForNextLevel).clamp(0.0, 1.0);

    return SizedBox(
      width: 220,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // Fondo
                Container(
                  height: 7,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                ),
                // Relleno con gradient + glow
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currentXp / $xpForNextLevel XP',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ProfileError extends StatelessWidget {
  const _ProfileError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No se pudo cargar el perfil',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
