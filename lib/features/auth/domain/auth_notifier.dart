import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_provider.dart';
import '../../profile/data/profile_provider.dart';
import '../../habits/domain/habit_notifier.dart';
import '../../stats/data/stats_provider.dart';

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
      _invalidateUserData();
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

  /// Invalida todos los providers que cachean datos del usuario actual.
  /// Imprescindible en login/logout/delete para evitar que la siguiente
  /// sesión vea datos del usuario anterior.
  void _invalidateUserData() {
    ref.invalidate(userProfileProvider);
    ref.invalidate(habitsNotifierProvider);
    ref.invalidate(availableMonthsProvider);
    ref.invalidate(habitStatsProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(selectedMonthProvider);
  }

  // Cierra la sesión del usuario
  Future<void> signOut() async {
    await _client.auth.signOut();
    _invalidateUserData();
  }

  /// Cambia el username en `public.user` y en los metadatos de auth.
  Future<AuthResult> changeUsername(String newUsername) async {
    state = const AsyncLoading();
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = const AsyncData(null);
        return const AuthFailure('No hay sesión activa.');
      }
      final trimmed = newUsername.trim();

      await _client
          .from('user')
          .update({'username': trimmed})
          .eq('id', user.id);

      await _client.auth.updateUser(
        UserAttributes(data: {'username': trimmed}),
      );

      ref.invalidate(userProfileProvider);
      state = const AsyncData(null);
      return const AuthSuccess();
    } on PostgrestException catch (e) {
      state = const AsyncData(null);
      debugPrint('[Auth] changeUsername PG: ${e.message}');
      return AuthFailure('Error al cambiar el nombre. Inténtalo de nuevo.');
    } catch (e) {
      state = const AsyncData(null);
      debugPrint('[Auth] changeUsername error: $e');
      return AuthFailure('Error inesperado: $e');
    }
  }

  /// Cambia la contraseña verificando antes la antigua mediante re-login.
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) {
        state = const AsyncData(null);
        return const AuthFailure('No hay sesión activa.');
      }

      // Verificar la contraseña actual re-logueando con ella.
      //
      // Supabase no expone una API "verifyPassword" — updateUser acepta
      // una password nueva sin pedir la antigua, lo que sería un fallo
      // de seguridad si tu token estuviera expuesto (alguien con la
      // sesión activa podría cambiar la contraseña sin saber la actual).
      // Hacer signInWithPassword con la antigua es el workaround
      // estándar: si triunfa, sabemos que el usuario la conoce. Si no,
      // lanza AuthException y abortamos antes de tocar nada.
      try {
        await _client.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } on AuthException {
        state = const AsyncData(null);
        return const AuthFailure('La contraseña actual es incorrecta.');
      }

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      state = const AsyncData(null);
      return const AuthSuccess();
    } on AuthException catch (e) {
      state = const AsyncData(null);
      return AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      state = const AsyncData(null);
      debugPrint('[Auth] changePassword error: $e');
      return AuthFailure('Error inesperado: $e');
    }
  }

  /// Elimina la cuenta del usuario y todos sus datos. Irreversible.
  Future<AuthResult> deleteAccount() async {
    state = const AsyncLoading();
    try {
      await _client.rpc('delete_my_account');
      await _client.auth.signOut();
      _invalidateUserData();
      state = const AsyncData(null);
      return const AuthSuccess();
    } on PostgrestException catch (e) {
      state = const AsyncData(null);
      debugPrint('[Auth] deleteAccount PG: code=${e.code} msg=${e.message}');
      return AuthFailure('SQL: ${e.message}');
    } catch (e) {
      state = const AsyncData(null);
      debugPrint('[Auth] deleteAccount: $e');
      return AuthFailure('$e');
    }
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
