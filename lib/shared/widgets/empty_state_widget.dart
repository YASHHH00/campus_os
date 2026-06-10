import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Empty state placeholder widget for list screens.
///
/// Displays an icon, title, subtitle, and an optional CTA button.
/// Every list screen should show this when there is no data instead
/// of a blank screen.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container with gradient background
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.15),
                    AppColors.primaryPurple.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppColors.primaryPurple.withValues(alpha: 0.7),
                semanticLabel: title,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCtaPressed,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
