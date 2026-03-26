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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
        );

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada. Revisa tu email para confirmarla.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.login);
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
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                const AuthLogo(small: true),

                const SizedBox(height: 32),

                // Título
                Text(
                  'Crea tu cuenta',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Empieza a construir tus hábitos hoy',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Username
                MomentumTextField(
                  controller: _usernameController,
                  label: 'Nombre de usuario',
                  hint: 'max 10 caracteres',
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre de usuario es obligatorio';
                    }
                    final trimmed = v.trim();
                    if (trimmed.length < AppConstants.usernameMinLength) {
                      return 'Mínimo ${AppConstants.usernameMinLength} caracteres';
                    }
                    if (trimmed.length > AppConstants.usernameMaxLength) {
                      return 'Máximo ${AppConstants.usernameMaxLength} caracteres';
                    }
                    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                    if (!usernameRegex.hasMatch(trimmed)) {
                      return 'Solo letras, números y guión bajo';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 16),

                // Confirmar contraseña
                MomentumTextField(
                  controller: _confirmController,
                  label: 'Confirmar contraseña',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (v != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botón registro
                AuthButton(
                  label: 'Crear cuenta',
                  isLoading: isLoading,
                  onPressed: _onRegister,
                ),

                const SizedBox(height: 24),

                // Volver al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Iniciar sesión'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
