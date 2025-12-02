import 'package:flutter/material.dart';

/// Uygulama Renkleri - Merkezi Tanımlamalar
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);

  // Text Colors
  static const Color textLight = Color(0xFF1F2937);
  static const Color textDark = Color(0xFFF3F4F6);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Card Colors - Light Mode
  static const Color card1Light = Color(0xFF6366F1);
  static const Color card2Light = Color(0xFF8B5CF6);
  static const Color card3Light = Color(0xFFEC4899);

  // Card Colors - Dark Mode
  static const Color card1Dark = Color(0xFF4F46E5);
  static const Color card2Dark = Color(0xFF7C3AED);
  static const Color card3Dark = Color(0xFFDB2777);

  // Test Screen Gradient
  static const Color testGradientStart = Color(0xFF000428);
  static const Color testGradientEnd = Color(0xFF004e92);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Glassmorphism
  static const Color glassLight = Colors.white;
  static const Color glassDark = Colors.black;
  static const double glassOpacity = 0.1;
  static const double glassBorderOpacity = 0.2;

  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFD1D5DB);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
}
