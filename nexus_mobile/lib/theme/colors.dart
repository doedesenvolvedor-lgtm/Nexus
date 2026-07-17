import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF6D28FF);
  static const Color primaryBlue = Color(0xFF2B7FFF);
  static const Color accentPurple = Color(0xFF8A4DFF);
  
  // Background
  static const Color background = Color(0xFF090909);
  static const Color cardBackground = Color(0xFF151515);
  static const Color cardBackgroundLight = Color(0xFF1F1F1F);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFB923C);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryBlue],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, primaryBlue],
  );
  
  // Opacity variants
  static Color textPrimaryWithOpacity(double opacity) =>
      textPrimary.withOpacity(opacity);
  
  static Color textSecondaryWithOpacity(double opacity) =>
      textSecondary.withOpacity(opacity);
  
  static Color primaryPurpleWithOpacity(double opacity) =>
      primaryPurple.withOpacity(opacity);
  
  static Color primaryBlueWithOpacity(double opacity) =>
      primaryBlue.withOpacity(opacity);
}
