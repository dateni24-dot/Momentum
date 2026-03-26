import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Logo de Momentum con texto corporativo.
/// El logo PNG se cargará desde assets cuando esté disponible.
/// Mientras tanto muestra el logotipo tipográfico con los colores corporativos.
class AuthLogo extends StatelessWidget {
  final bool small;

  const AuthLogo({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final logoSize = small ? 80.0 : 110.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intenta cargar el logo desde assets, sino usa el fallback
        Container(
          width: logoSize,
          height: logoSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: logoSize,
            height: logoSize,
            errorBuilder: (_, __, ___) => _buildFallbackLogo(logoSize),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MOMENTUM',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: small ? 20 : 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: small ? 60 : 80,
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [AppColors.primaryDark, Color(0xFF0D0D0D)],
        ),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.trending_up_rounded,
          color: AppColors.primary,
          size: size * 0.5,
        ),
      ),
    );
  }
}
