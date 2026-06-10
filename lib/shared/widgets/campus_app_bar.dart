import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Reusable app bar with optional WebRTC connection status indicator.
///
/// Shows a small colored dot (green/red) next to the title when
/// [showConnectionStatus] is true, indicating laptop sync state.
class CampusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showConnectionStatus;
  final bool isConnected;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const CampusAppBar({
    super.key,
    required this.title,
    this.showConnectionStatus = false,
    this.isConnected = false,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      centerTitle: centerTitle,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            semanticsLabel: title,
          ),
          if (showConnectionStatus) ...[
            const SizedBox(width: 8),
            Semantics(
              label: isConnected ? 'Laptop connected' : 'Laptop disconnected',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? AppColors.connectedGreen
                      : AppColors.disconnectedRed,
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: AppColors.connectedGreen.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
