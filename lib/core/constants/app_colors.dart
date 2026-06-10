import 'package:flutter/material.dart';

/// Design system color tokens for Campus OS.
///
/// Primary palette built around campus purple (#6C63FF) with Material 3
/// harmonized surface and container colors for dark theme.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryPurpleLight = Color(0xFF9D97FF);
  static const Color primaryPurpleDark = Color(0xFF3B34CC);

  // ── Accent Colors ─────────────────────────────────────────────────────────
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentGreen = Color(0xFF4CAF50);

  // ── Surface Colors (Dark Theme) ───────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainer = Color(0xFF1E1E2E);
  static const Color surfaceContainerHigh = Color(0xFF252538);
  static const Color surfaceContainerHighest = Color(0xFF2D2D44);
  static const Color surfaceBright = Color(0xFF38384F);

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8E6F0);
  static const Color textSecondary = Color(0xFFB0ADBE);
  static const Color textTertiary = Color(0xFF7A7890);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ── Offline / WebRTC Status ───────────────────────────────────────────────
  static const Color offlineBanner = Color(0xFFFFA726);
  static const Color connectedGreen = Color(0xFF66BB6A);
  static const Color disconnectedRed = Color(0xFFEF5350);

  // ── Card & Border ─────────────────────────────────────────────────────────
  static const Color cardBackground = Color(0xFF1E1E2E);
  static const Color cardBorder = Color(0xFF2D2D44);
  static const Color divider = Color(0xFF2D2D44);

  // ── Shimmer ───────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1E1E2E);
  static const Color shimmerHighlight = Color(0xFF2D2D44);

  // ── Gradient Presets ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceContainer, surfaceContainerHigh],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentCyan, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
