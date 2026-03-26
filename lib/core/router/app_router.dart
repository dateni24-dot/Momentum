import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

part 'app_router.g.dart';

// Rutas nombradas
abstract class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: _getInitialRoute(),
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
      // TODO: añadir HomeScreen cuando esté lista
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Home - Próximamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
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
