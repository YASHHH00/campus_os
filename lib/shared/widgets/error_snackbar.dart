import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Helper to show themed snackbars for errors, success, and warnings.
///
/// Uses [ScaffoldMessenger] so snackbars survive navigation transitions.
/// All snackbars are floating with rounded corners per the app design system.
class ErrorSnackbar {
  ErrorSnackbar._();

  /// Show an error snackbar with a red accent.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.surfaceContainerHighest,
      iconColor: AppColors.error,
    );
  }

  /// Show a success snackbar with a green accent.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.surfaceContainerHighest,
      iconColor: AppColors.success,
    );
  }

  /// Show a warning snackbar with an amber accent.
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.surfaceContainerHighest,
      iconColor: AppColors.warning,
    );
  }

  /// Show an informational snackbar with a blue accent.
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.surfaceContainerHighest,
      iconColor: AppColors.info,
    );
  }

  /// Show an offline banner snackbar that stays until dismissed.
  static void showOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textPrimary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'re offline. Changes will sync when connected.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.offlineBanner,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
