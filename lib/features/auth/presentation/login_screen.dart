import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/auth_logo.dart';
import 'widgets/momentum_text_field.dart';
import 'widgets/auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        context.go(AppRoutes.home);
      case AuthFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo
                const AuthLogo(),

                const SizedBox(height: 48),

                // Título
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Inicia sesión para continuar tu progreso',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email
                MomentumTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'tu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El email es obligatorio';
                    }
                    final emailRegex =
                        RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Introduce un email válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Contraseña
                MomentumTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (v.length < AppConstants.passwordMinLength) {
                      return 'Mínimo ${AppConstants.passwordMinLength} caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botón de login
                AuthButton(
                  label: 'Iniciar sesión',
                  isLoading: isLoading,
                  onPressed: _onLogin,
                ),

                const SizedBox(height: 24),

                // Divisor
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.border),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '¿No tienes cuenta?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.border),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ir a registro
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
