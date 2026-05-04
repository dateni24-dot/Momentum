import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/profile_provider.dart';
import '../data/stats_provider.dart';
import '../domain/stats_models.dart';

const _months = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String _formatMonth(String yyyymm) {
  final parts = yyyymm.split('-');
  if (parts.length != 2) return yyyymm;
  final m = int.tryParse(parts[1]) ?? 1;
  return '${_months[m - 1]} ${parts[0]}';
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final monthsAsync  = ref.watch(availableMonthsProvider);
    final statsAsync   = ref.watch(habitStatsProvider);
    final historyAsync = ref.watch(historyProvider);
    final selected     = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Estadísticas',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        children: [
          // ── Streak record ────────────────────────────────────────────────
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) => p == null
                ? const SizedBox.shrink()
                : _StreakRecordCard(
                    current: p.streakDays,
                    record:  p.streakRecord,
                  ),
          ),

          const SizedBox(height: 28),

          // ── Sección hábitos por mes ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hábitos por mes',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              monthsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (months) => _MonthDropdown(
                  months: months,
                  selected: selected ?? _currentMonth(),
                  onChanged: (m) =>
                      ref.read(selectedMonthProvider.notifier).state = m,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => const _EmptyMsg('Error al cargar estadísticas'),
            data: (stats) => stats.isEmpty
                ? const _EmptyMsg('No hay hábitos completados este mes')
                : Column(
                    children: [
                      for (final s in stats) ...[
                        _HabitStatCard(stat: s),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 28),

          // ── Sección historial ────────────────────────────────────────────
          const Text('Historial',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),

          const SizedBox(height: 12),

          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => const _EmptyMsg('Error al cargar historial'),
            data: (entries) => entries.isEmpty
                ? const _EmptyMsg('Aún no hay actividad registrada')
                : Column(
                    children: [
                      for (final e in entries) ...[
                        _HistoryEntryTile(entry: e),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _currentMonth() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _StreakRecordCard extends StatelessWidget {
  final int current;
  final int record;
  const _StreakRecordCard({required this.current, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF5722).withValues(alpha: 0.15),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5722).withValues(alpha: 0.18),
              border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF5722), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Récord de racha',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text('$record día${record == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Racha actual: $current ${current == 1 ? 'día' : 'días'}',
                    style: const TextStyle(
                        color: Color(0xFFFFAB91), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  final List<String> months;
  final String selected;
  final ValueChanged<String> onChanged;
  const _MonthDropdown({
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = {selected, ...months}.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary, size: 20),
          dropdownColor: AppColors.surface,
          isDense: true,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          items: [
            for (final m in items)
              DropdownMenuItem(
                value: m,
                child: Text(_formatMonth(m)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _HabitStatCard extends StatelessWidget {
  final HabitStat stat;
  const _HabitStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.habitName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                icon: Icons.repeat_rounded,
                value: '${stat.timesCompleted}',
                label: stat.timesCompleted == 1 ? 'vez' : 'veces',
                color: AppColors.primary,
              ),
              _StatItem(
                icon: Icons.timer_outlined,
                value: '${stat.totalMinutes}',
                label: 'min',
                color: Colors.cyanAccent,
              ),
              _StatItem(
                icon: Icons.bolt_rounded,
                value: '${stat.totalXp}',
                label: 'XP',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w700)),
              TextSpan(
                  text: '  $label',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry.completedAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
    final startStr = _hhmm(entry.startedAt);
    final endStr   = _hhmm(entry.completedAt);
    final hasMult  = entry.multiplier > 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(dateStr,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.habitName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${entry.durationMin} min · $startStr → $endStr',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 13),
                  const SizedBox(width: 2),
                  Text('+${entry.xpEarned}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              if (hasMult)
                Text(
                  '×${entry.multiplier.toStringAsFixed(entry.multiplier % 1 == 0 ? 0 : 2)}',
                  style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _EmptyMsg extends StatelessWidget {
  final String text;
  const _EmptyMsg(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
