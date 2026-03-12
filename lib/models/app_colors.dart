import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF05080F);
  static const Color surface = Color(0xFF0D1320);
  static const Color surface2 = Color(0xFF121A2E);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accent2 = Color(0xFF7C3AED);
  static const Color accent3 = Color(0xFF10B981);
  static const Color warn = Color(0xFFF59E0B);
  static const Color textColor = Color(0xFFE2E8F0);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0x1F00E5FF);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [accent, Color(0xFFA78BFA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration glowDecoration({
    Color color = accent,
    double radius = 16,
    double blurRadius = 20,
    double spreadRadius = 0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }
}
