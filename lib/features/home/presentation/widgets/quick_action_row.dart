import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Quick action shortcuts row displayed on the home screen.
///
/// Provides one-tap access to the most common actions:
/// Scan Note, Add Event, Split Expense, Post Item, Sync.
class QuickActionRow extends StatelessWidget {
  final VoidCallback? onScanNote;
  final VoidCallback? onAddEvent;
  final VoidCallback? onSplitExpense;
  final VoidCallback? onPostItem;
  final VoidCallback? onSync;

  const QuickActionRow({
    super.key,
    this.onScanNote,
    this.onAddEvent,
    this.onSplitExpense,
    this.onPostItem,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.camera_alt_rounded,
                  label: 'Scan Note',
                  color: AppColors.primaryPurple,
                  onTap: onScanNote,
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.event_rounded,
                  label: 'Add Event',
                  color: AppColors.accentCyan,
                  onTap: onAddEvent,
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.receipt_rounded,
                  label: 'Split',
                  color: AppColors.accentAmber,
                  onTap: onSplitExpense,
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Lost & Found',
                  color: AppColors.accentPink,
                  onTap: onPostItem,
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.sync_rounded,
                  label: 'Sync',
                  color: AppColors.accentGreen,
                  onTap: onSync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
