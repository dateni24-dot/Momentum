import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_provider.dart';

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
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncData(null);
      return const AuthSuccess();
    } on AuthException catch (e) {
      state = const AsyncData(null);
      return AuthFailure(_mapAuthError(e.message));
    } catch (_) {
      state = const AsyncData(null);
      return const AuthFailure('Ha ocurrido un error inesperado.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );
      state = const AsyncData(null);
      return const AuthSuccess();
    } on AuthException catch (e) {
      state = const AsyncData(null);
      return AuthFailure(_mapAuthError(e.message));
    } catch (_) {
      state = const AsyncData(null);
      return const AuthFailure('Ha ocurrido un error inesperado.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

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
    if (msg.contains('password')) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (msg.contains('email')) {
      return 'El formato del email no es válido.';
    }
    return 'Error: $message';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
