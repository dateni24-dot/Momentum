import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/habits/presentation/home_screen.dart';

// Rutas nombradas
abstract class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}

/// Listenable que se notifica cada vez que cambia el estado de auth
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  // Si el provider se invalida (hot restart, tests, signOut con reset),
  // cierra la suscripción al stream de auth para no acumular listeners.
  ref.onDispose(authNotifier.dispose);
  return GoRouter(
    initialLocation: _getInitialRoute(),
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (session == null && !isAuthRoute) return AppRoutes.login;
      if (session != null && isAuthRoute) return AppRoutes.home;
      return null;
    },
  );
});

String _getInitialRoute() {
  final session = Supabase.instance.client.auth.currentSession;
  return session != null ? AppRoutes.home : AppRoutes.login;
}
