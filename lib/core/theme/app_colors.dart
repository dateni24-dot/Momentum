import 'package:flutter/material.dart';

/// Colores corporativos de Momentum (verde, negro, gris)
class AppColors {
  AppColors._();

  // Verdes corporativos (extraídos del logo)
  static const Color primary = Color(0xFF5DBE2A);
  static const Color primaryDark = Color(0xFF3D8A1A);
  static const Color primaryLight = Color(0xFF7ED44E);

  // Fondo oscuro
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF242424);

  // Grises
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF616161);
  static const Color greyLight = Color(0xFFBDBDBD);

  // Texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF616161);

  // Bordes y divisores
  static const Color border = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFF1F1F1F);

  // Estados
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF5DBE2A);
  static const Color warning = Color(0xFFFFC107);
}
