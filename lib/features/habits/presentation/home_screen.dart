import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/habit_model.dart';
import '../domain/habit_notifier.dart';
import 'habit_form_screen.dart';
import 'widgets/swipeable_habit_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/data/profile_provider.dart';
import '../../profile/presentation/widgets/avatar_registry.dart';

// ---------------------------------------------------------------------------
// HomeScreen principal — gestiona la animación de bienvenida y el tab actual
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showWelcome = true;
  late final AnimationController _welcomeCtrl;
  late final Animation<double>   _welcomeFade;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();

    // Controlador para desvanecer el splash de bienvenida
    _welcomeCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _welcomeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeOut),
    );

    // Mostrar splash 2 segundos, luego desvanecerlo
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _welcomeCtrl.forward().then((_) {
        if (mounted) setState(() => _showWelcome = false);
      });
    });
  }

  @override
  void dispose() {
    _welcomeCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 0 || index == 1) {
      setState(() => _currentTab = index);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.construction_rounded,
                color: AppColors.primary, size: 18),
            SizedBox(width: 10),
            Text('Tienda — Próximamente'),
          ],
        ),
        backgroundColor: AppColors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user     = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ??
        user?.email?.split('@').first ??
        'Usuario';

    final habitsAsync = ref.watch(habitsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Contenido según tab activo
          SafeArea(
            child: _currentTab == 1
                ? const ProfileScreen()
                : habitsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (_, __) => _ErrorView(
                      onRetry: () =>
                          ref.read(habitsNotifierProvider.notifier).refresh(),
                    ),
                    data: (state) => _HomeContent(state: state),
                  ),
          ),

          // Splash de bienvenida (solo en tab hábitos)
          if (_showWelcome && _currentTab == 0)
            FadeTransition(
              opacity: _welcomeFade,
              child: _WelcomeSplash(username: username),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentTab,
        onTap:        _onTabTapped,
      ),
      floatingActionButton: _currentTab == 0 ? _AddHabitFab() : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Splash de bienvenida animado
// ---------------------------------------------------------------------------

class _WelcomeSplash extends StatefulWidget {
  final String username;
  const _WelcomeSplash({required this.username});

  @override
  State<_WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<_WelcomeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo pulsante con glow neon
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width:  110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.primaryDark, Color(0xFF0A0A0A)],
                  ),
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color:      AppColors.primaryLight.withValues(alpha: 0.2),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size:  55,
                ),
              ),
            ),

            const SizedBox(height: 36),

            const Text(
              'MOMENTUM',
              style: TextStyle(
                color:        AppColors.textPrimary,
                fontSize:     28,
                fontWeight:   FontWeight.w700,
                letterSpacing: 8,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '¡Bienvenido de nuevo!',
              style: TextStyle(
                color:    AppColors.textSecondary,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 6),

            // Nombre de usuario en verde
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.username,
                style: const TextStyle(
                  color:      AppColors.primary,
                  fontSize:   20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido principal (hábitos)
// ---------------------------------------------------------------------------

class _HomeContent extends ConsumerWidget {
  final HabitsState state;
  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _HomeHeader(habitCount: state.habits.length)),

        // Título sección
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

        // Lista o estado vacío
        state.habits.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyHabitsView(),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = state.habits[index];
                      // Animación de entrada escalonada por tarjeta
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds: 250 + index * 70),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, child) => Transform.translate(
                          offset: Offset(0, 24 * (1 - value)),
                          child:  Opacity(opacity: value, child: child),
                        ),
                        child: SwipeableHabitCard(
                          habit:    habit,
                          isFirst:  index == 0,
                          onEdit:   () => _openForm(context, habit: habit),
                          onDelete: () => _confirmDelete(context, ref, habit),
                        ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, HabitModel habit) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar hábito?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Se eliminará "${habit.habitName}" de tu lista. Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
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
// Header rediseñado: avatar + saludo + stats
// ---------------------------------------------------------------------------

class _HomeHeader extends ConsumerWidget {
  final int habitCount;
  const _HomeHeader({required this.habitCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ??
        user?.email?.split('@').first ??
        'Usuario';
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Barra superior: logo + logout ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [AppColors.primaryDark, Color(0xFF0D0D0D)],
                      ),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.trending_up_rounded,
                        color: AppColors.primary, size: 15),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MOMENTUM',
                    style: TextStyle(
                      color:        AppColors.textPrimary,
                      fontWeight:   FontWeight.w700,
                      fontSize:     13,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              _LogoutButton(),
            ],
          ),

          const SizedBox(height: 24),

          // ── Avatar + saludo + nombre ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar con ring de XP
              Builder(builder: (_) {
                final profile = ref.watch(userProfileProvider).valueOrNull;
                final glowColor = profile != null
                    ? AvatarRegistry.glowColorForKey(profile.evoImg)
                    : AppColors.primary;
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (profile != null)
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: _HomeXpRingPainter(
                            progress: profile.xpProgress,
                            color: glowColor,
                          ),
                        ),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(
                            color: glowColor.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profile != null
                              ? AvatarRegistry.forKey(profile.evoImg, size: 68)
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(width: 16),

              // Saludo + nombre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username,
                      style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontSize:   24,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          //Text(user_avatar ?? 'no hay', style: const TextStyle(fontSize: 20)), // Para evitar overflow si no hay avatar

          const SizedBox(height: 20),

          // ── Línea divisora con gradiente ──
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark, Colors.transparent],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Chips de estadísticas rápidas ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatChip(
                  icon:  Icons.task_alt_rounded,
                  label: '$habitCount hábito${habitCount == 1 ? '' : 's'}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon:  Icons.local_fire_department_rounded,
                  label: 'Racha: 0 días',
                  color: const Color(0xFFFF5722),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon:  Icons.monetization_on_rounded,
                  label: '0 monedas',
                  color: const Color(0xFFFFC107),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días ☀️';
    if (hour < 19) return 'Buenas tardes 🌤️';
    return 'Buenas noches 🌙';
  }
}

/// Chip de estadística rápida
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:      color,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botón logout
// ---------------------------------------------------------------------------

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout_rounded,
          color: AppColors.textSecondary, size: 20),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('¿Cerrar sesión?',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Salir',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
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
// Barra de navegación inferior
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
            top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex:       currentIndex,
        onTap:              onTap,
        backgroundColor:    Colors.transparent,
        elevation:          0,
        selectedItemColor:  AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize:   11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon:       Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes_rounded),
            label:      'Hábitos',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label:      'Perfil',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store_rounded),
            label:      'Tienda',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAB animado para añadir hábito
// ---------------------------------------------------------------------------

class _AddHabitFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 0,
            offset:     const Offset(0, 6),
          ),
          BoxShadow(
            color:      AppColors.primaryLight.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 4,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const HabitFormScreen(),
            fullscreenDialog: true,
          ),
        ),
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
// Estado vacío con animación de pulso
// ---------------------------------------------------------------------------

class _EmptyHabitsView extends StatefulWidget {
  const _EmptyHabitsView();

  @override
  State<_EmptyHabitsView> createState() => _EmptyHabitsViewState();
}

class _EmptyHabitsViewState extends State<_EmptyHabitsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono pulsante con glow
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width:  96,
              height: 96,
              decoration: BoxDecoration(
                color:  AppColors.primary.withValues(alpha: 0.08),
                shape:  BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_task_rounded,
                color: AppColors.primary,
                size:  44,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Sin hábitos todavía',
            style: TextStyle(
              color:      AppColors.textPrimary,
              fontSize:   22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Crea tu primer hábito y empieza\na construir tu mejor versión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    AppColors.textSecondary,
              fontSize: 14,
              height:   1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// XP ring painter para el header del home
// ---------------------------------------------------------------------------

class _HomeXpRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HomeXpRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HomeXpRingPainter old) =>
      old.progress != progress || old.color != color;
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
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar los hábitos',
              style: TextStyle(
                color: AppColors.textPrimary,
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
