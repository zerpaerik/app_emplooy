import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

/// Clase que define todos los colores de la aplicación Emplooy
class AppColors {
  AppColors._(); // Constructor privado para prevenir instanciación

  // Colores Primarios
  static final Color primary = HexColor('EA6012');
  static final Color gradientStart = HexColor('FBB03B');
  static final Color gradientEnd = HexColor('EF6826');

  // Gradiente Principal
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [
      Color(0xFFFBB03B),
      Color(0xFFEF6826),
    ],
  );

  // Gradiente Sutil (para fondos)
  static LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HexColor('FBB03B').withValues(alpha: 0.1),
      HexColor('EF6826').withValues(alpha: 0.05),
    ],
  );

  // Gradiente de Fondo
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF9FAFB),
      Color(0xFFFFFFFF),
    ],
  );

  // Colores de Texto
  static const Color textDark = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Colors.white;

  // Colores de Fondo
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundGrey = Color(0xFFF3F4F6);

  // Colores de Estado
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Colores de Acento
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFC4B5FD);

  // Colores de Borde
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF9CA3AF);

  // Colores de Sombra
  static Color shadow = Colors.black.withValues(alpha: 0.1);
  static Color shadowDark = Colors.black.withValues(alpha: 0.2);

  // Colores de Overlay
  static Color overlay = Colors.black.withValues(alpha: 0.5);
  static Color overlayLight = Colors.black.withValues(alpha: 0.3);

  // Colores para Shimmer Loading
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);
}
