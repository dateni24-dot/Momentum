import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_provider.dart';
import '../../profile/data/profile_provider.dart';
import '../../habits/domain/habit_notifier.dart';

/// Resultado de una operación de auth
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

/// Notifier que gestiona login, registro y logout
class AuthNotifier extends AsyncNotifier<void> {
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  Future<void> build() async {}

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      // Se intenta iniciar sesión con email y password, asegurándose de eliminar espacios en blanco
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      ref.invalidate(userProfileProvider);
      ref.invalidate(habitsNotifierProvider);
      state = const AsyncData(null);
      return const AuthSuccess();
    } on AuthException catch (e) {
      // Si ocurre un error de autenticación, se mapea el mensaje y se devuelve un AuthFailure
      state = const AsyncData(null);
      debugPrint('[Auth] signIn AuthException: ${e.message}');
      return AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      // Para cualquier otro error inesperado, se captura y se devuelve un mensaje genérico
      state = const AsyncData(null);
      debugPrint('[Auth] signIn error: $e');
      return AuthFailure('Error inesperado: $e');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // Para el registro, también se envía el username como dato adicional
    state = const AsyncLoading();
    try {
      await _client.auth.signUp(
        // Supabase maneja el registro con email y password, y permite enviar datos adicionales
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );
      // El registro exitoso no inicia sesión automáticamente, por lo que no se espera un usuario activo aquí
      state = const AsyncData(null);
      return const AuthSuccess();
    } on AuthException catch (e) {
      // Si ocurre un error de autenticación, se mapea el mensaje y se devuelve un AuthFailure
      state = const AsyncData(null);
      debugPrint('[Auth] signUp AuthException: ${e.message}');
      return AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      // Para cualquier otro error inesperado, se captura y se devuelve un mensaje genérico
      state = const AsyncData(null);
      debugPrint('[Auth] signUp error: $e');
      return AuthFailure('Error inesperado: $e');
    }
  }

  // Cierra la sesión del usuario
  Future<void> signOut() async {
    await _client.auth.signOut();
    ref.invalidate(userProfileProvider);
    ref.invalidate(habitsNotifierProvider);
  }

  // Mapea mensajes de error de Supabase a mensajes amigables para el usuario
  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (msg.contains('email already registered') ||
        msg.contains('already registered')) {
      return 'Este email ya está registrado.';
    }
    if (msg.contains('password should be at least') ||
        msg.contains('password is too short')) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email') ||
        msg.contains('email format')) {
      return 'El formato del email no es válido.';
    }
    if (msg.contains('database error')) {
      return 'Error al guardar el usuario. Contacta con soporte.';
    }
    if (msg.contains('email rate limit') || msg.contains('rate limit')) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }
    return 'Error: $message';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
