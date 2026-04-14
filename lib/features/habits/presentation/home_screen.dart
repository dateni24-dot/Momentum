import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/habit_model.dart';
import '../domain/habit_notifier.dart';
import 'habit_form_screen.dart';
import 'widgets/habit_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_notifier.dart';

/// Pantalla principal: muestra los hábitos del usuario
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _ErrorView(
            onRetry: () => ref.read(habitsNotifierProvider.notifier).refresh(),
          ),
          data: (state) => _HomeContent(state: state),
        ),
      ),
      floatingActionButton: _AddHabitFab(),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido principal
// ---------------------------------------------------------------------------

class _HomeContent extends ConsumerWidget {
  final HabitsState state;
  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header con saludo y datos del usuario
        SliverToBoxAdapter(child: _HomeHeader()),

        // Sección "Mis Hábitos"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                const Text(
                  'Mis Hábitos',
                  style: TextStyle(
                    color:      AppColors.textPrimary,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                if (state.habits.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.habits.length}',
                      style: const TextStyle(
                        color:      AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize:   13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Lista de hábitos o estado vacío
        state.habits.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyHabitsView(),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = state.habits[index];
                      return HabitCard(
                        habit:    habit,
                        onEdit:   () => _openForm(context, habit: habit),
                        onDelete: () => _confirmDelete(context, ref, habit),
                      );
                    },
                    childCount: state.habits.length,
                  ),
                ),
              ),
      ],
    );
  }

  void _openForm(BuildContext context, {HabitModel? habit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habit: habit),
        fullscreenDialog: true,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitModel habit,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar hábito?',
          style: TextStyle(
            color:      AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Se eliminará "${habit.habitName}" de tu lista. Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color:      AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final result = await ref
          .read(habitsNotifierProvider.notifier)
          .deleteHabit(habit.habitId);
      if (!context.mounted) return;
      if (result is HabitFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HomeHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ??
        user?.email?.split('@').first ??
        'Usuario';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: logo + logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo pequeño con texto
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape:       BoxShape.circle,
                      gradient:    const RadialGradient(
                        colors: [AppColors.primaryDark, Color(0xFF0D0D0D)],
                      ),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.primary,
                      size:  18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MOMENTUM',
                    style: TextStyle(
                      color:       AppColors.textPrimary,
                      fontWeight:  FontWeight.w700,
                      fontSize:    14,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),

              // Botón logout
              _LogoutButton(),
            ],
          ),

          const SizedBox(height: 28),

          // Saludo
          Text(
            _getGreeting(),
            style: const TextStyle(
              color:    AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            username,
            style: const TextStyle(
              color:      AppColors.textPrimary,
              fontSize:   26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          // Línea divisora con gradiente
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ---------------------------------------------------------------------------
// Botón de logout
// ---------------------------------------------------------------------------

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(
        Icons.logout_rounded,
        color: AppColors.textSecondary,
        size:  20,
      ),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '¿Cerrar sesión?',
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Salir',
                  style: TextStyle(
                    color:      AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// FAB para añadir hábito
// ---------------------------------------------------------------------------

class _AddHabitFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HabitFormScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        icon:  const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nuevo hábito',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vacío
// ---------------------------------------------------------------------------

class _EmptyHabitsView extends StatelessWidget {
  const _EmptyHabitsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con glow verde
          Container(
            width:  90,
            height: 90,
            decoration: BoxDecoration(
              color:        AppColors.primary.withValues(alpha: 0.08),
              shape:        BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:      AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_task_rounded,
              color: AppColors.primary,
              size:  42,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Sin hábitos todavía',
            style: TextStyle(
              color:      AppColors.textPrimary,
              fontSize:   20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Crea tu primer hábito y empieza\na construir tu mejor versión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:   AppColors.textSecondary,
              fontSize: 14,
              height:   1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vista de error
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textSecondary,
              size:  48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar los hábitos',
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon:  const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
