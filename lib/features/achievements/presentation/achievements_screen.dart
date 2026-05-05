import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/achievement_provider.dart';
import '../domain/achievement_model.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mis Logros',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text(
            'No se pudieron cargar los logros',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (achievements) => achievements.isEmpty
            ? const _EmptyState()
            : _AchievementsBody(achievements: achievements),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body con resumen + grid de logros
// ---------------------------------------------------------------------------

class _AchievementsBody extends StatelessWidget {
  final List<AchievementModel> achievements;
  const _AchievementsBody({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        _ProgressCard(unlocked: unlocked, total: total),
        const SizedBox(height: 24),
        const Text(
          'Desbloqueados',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        _AchievementGrid(
          achievements: achievements.where((a) => a.isUnlocked).toList(),
          unlocked: true,
        ),
        if (achievements.any((a) => !a.isUnlocked)) ...[
          const SizedBox(height: 24),
          const Text(
            'Por desbloquear',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _AchievementGrid(
            achievements: achievements.where((a) => !a.isUnlocked).toList(),
            unlocked: false,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de progreso global
// ---------------------------------------------------------------------------

class _ProgressCard extends StatelessWidget {
  final int unlocked;
  final int total;
  const _ProgressCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progreso de logros',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlocked de $total logros',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
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
// Grid de tarjetas de logros
// ---------------------------------------------------------------------------

class _AchievementGrid extends StatelessWidget {
  final List<AchievementModel> achievements;
  final bool unlocked;
  const _AchievementGrid({required this.achievements, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          unlocked
              ? 'Aún no has desbloqueado ningún logro.'
              : 'Has completado todos los logros. ¡Increíble!',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (_, i) => _AchievementCard(achievement: achievements[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta individual de logro
// ---------------------------------------------------------------------------

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final bgColor = unlocked
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.surfaceVariant.withValues(alpha: 0.5);
    final borderColor = unlocked
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: unlocked
                ? const Icon(Icons.emoji_events_rounded,
                    color: AppColors.primary, size: 24)
                : const Icon(Icons.lock_outline_rounded,
                    color: AppColors.greyDark, size: 22),
          ),

          const SizedBox(height: 12),

          // Nombre
          Text(
            achievement.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 4),

          // Descripción
          Expanded(
            child: Text(
              achievement.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),

          // Monedas + fecha desbloqueado
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: AppColors.warning, size: 11),
              const SizedBox(width: 3),
              Text(
                '+${achievement.coins}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unlocked && achievement.unlockedAt != null) ...[
                const Spacer(),
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 11),
                const SizedBox(width: 3),
                Text(
                  _formatDate(achievement.unlockedAt!),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Estado vacío
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              color: AppColors.textDisabled, size: 64),
          SizedBox(height: 16),
          Text(
            'No hay logros disponibles aún',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
