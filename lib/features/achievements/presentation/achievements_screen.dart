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
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'No se pudieron cargar los logros\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (achievements) => achievements.isEmpty
            ? const _EmptyState()
            : _AchievementsBody(
                achievements: achievements,
                onClaim: (id) => claimAchievement(ref, id),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body responsive con 3 secciones
// ---------------------------------------------------------------------------

class _AchievementsBody extends StatelessWidget {
  final List<AchievementModel> achievements;
  final Future<void> Function(int achievementId) onClaim;

  const _AchievementsBody({
    required this.achievements,
    required this.onClaim,
  });

  static int _columns(double width) {
    if (width >= 900) return 4;
    if (width >= 580) return 3;
    return 2;
  }

  static double _aspectRatio(int cols) {
    if (cols == 4) return 1.0;
    if (cols == 3) return 0.92;
    return 0.82;
  }

  @override
  Widget build(BuildContext context) {
    final unlocked  = achievements.where((a) => a.isUnlocked).length;
    final eligible  = achievements.where((a) => a.isEligible).toList();
    final completed = achievements.where((a) => a.isUnlocked).toList();
    final locked    = achievements.where((a) => !a.isUnlocked && !a.isEligible).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols        = _columns(constraints.maxWidth);
        final aspectRatio = _aspectRatio(cols);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              children: [
                _ProgressCard(unlocked: unlocked, total: achievements.length),
                const SizedBox(height: 28),

                // ── Disponibles para reclamar ──
                if (eligible.isNotEmpty) ...[
                  _sectionLabel('Disponibles', highlight: true),
                  const SizedBox(height: 10),
                  _AchievementGrid(
                    achievements: eligible,
                    cols: cols,
                    aspectRatio: aspectRatio,
                    onClaim: onClaim,
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Completados ──
                _sectionLabel('Completados'),
                const SizedBox(height: 10),
                completed.isEmpty
                    ? const _EmptySection(text: 'Aún no has completado ningún logro.')
                    : _AchievementGrid(
                        achievements: completed,
                        cols: cols,
                        aspectRatio: aspectRatio,
                      ),

                // ── Bloqueados ──
                if (locked.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _sectionLabel('Bloqueados'),
                  const SizedBox(height: 10),
                  _AchievementGrid(
                    achievements: locked,
                    cols: cols,
                    aspectRatio: aspectRatio,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionLabel(String text, {bool highlight = false}) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: highlight ? AppColors.primary : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.primary, size: 22),
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
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlocked de $total logros',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(height: 8, width: double.infinity, color: AppColors.surfaceVariant),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 8)
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid responsive
// ---------------------------------------------------------------------------

class _AchievementGrid extends StatelessWidget {
  final List<AchievementModel> achievements;
  final int cols;
  final double aspectRatio;
  final Future<void> Function(int)? onClaim;

  const _AchievementGrid({
    required this.achievements,
    required this.cols,
    required this.aspectRatio,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: achievements.length,
      itemBuilder: (_, i) => _AchievementCard(
        achievement: achievements[i],
        onClaim: onClaim,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta individual con estado de carga para el botón Reclamar
// ---------------------------------------------------------------------------

class _AchievementCard extends StatefulWidget {
  final AchievementModel achievement;
  final Future<void> Function(int)? onClaim;

  const _AchievementCard({required this.achievement, this.onClaim});

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _claiming = false;

  Future<void> _handleClaim() async {
    if (_claiming || widget.onClaim == null) return;
    setState(() => _claiming = true);
    try {
      await widget.onClaim!(widget.achievement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Text('¡${widget.achievement.name} reclamado! +${widget.achievement.coins} monedas'),
          ]),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al reclamar: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a         = widget.achievement;
    final unlocked  = a.isUnlocked;
    final eligible  = a.isEligible;

    final borderColor = unlocked
        ? AppColors.primary.withValues(alpha: 0.25)
        : eligible
            ? AppColors.primary.withValues(alpha: 0.5)
            : AppColors.border;

    final bgColor = unlocked
        ? AppColors.primary.withValues(alpha: 0.10)
        : eligible
            ? AppColors.primary.withValues(alpha: 0.07)
            : AppColors.surfaceVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: eligible ? 1.5 : 1),
        boxShadow: eligible
            ? [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 12,
              )]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: unlocked
                ? const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 22)
                : eligible
                    ? const Icon(Icons.emoji_events_rounded,
                        color: AppColors.primary, size: 22)
                    : const Icon(Icons.lock_outline_rounded,
                        color: AppColors.greyDark, size: 20),
          ),

          const SizedBox(height: 8),

          // Nombre
          Text(
            a.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: (unlocked || eligible) ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 3),

          // Descripción
          Expanded(
            child: Text(
              a.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10, height: 1.4),
            ),
          ),

          const SizedBox(height: 6),

          // Footer: monedas + estado / botón reclamar
          if (eligible)
            // Botón Reclamar
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: _claiming ? null : _handleClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _claiming
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '+${a.coins}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Text('Reclamar',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            )
          else
            // Monedas + check
            Row(children: [
              const Icon(Icons.monetization_on_outlined,
                  color: AppColors.warning, size: 11),
              const SizedBox(width: 3),
              Text(
                '+${a.coins}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
              if (unlocked) ...[
                const Spacer(),
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 13),
              ],
            ]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      );
}

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
          Text('No hay logros disponibles aún',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}
