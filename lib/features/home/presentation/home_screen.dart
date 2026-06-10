import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/webrtc_service.dart';
import '../../note_scanner/presentation/note_scanner_screen.dart';
import '../../timetable/presentation/timetable_screen.dart';
import '../../expense_splitter/presentation/expense_screen.dart';
import '../../lost_found/presentation/lost_found_screen.dart';
import '../../laptop_sync/presentation/sync_screen.dart';
import '../../laptop_sync/presentation/bloc/sync_bloc.dart';
import 'widgets/today_card.dart';
import 'widgets/quick_action_row.dart';

/// Root home screen with bottom navigation shell.
///
/// 5 tabs: Home, Notes, Timetable, Expenses, More (Lost & Found + Sync).
/// Shows an offline amber banner when WebRTC is not connected and
/// Supabase is offline.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _HomeTab(),
    NoteScannerScreen(),
    TimetableScreen(),
    ExpenseScreen(),
    _MoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline banner
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              if (state is SyncDisconnected || state is SyncInitial) {
                return _OfflineBanner();
              }
              return const SizedBox.shrink();
            },
          ),

          // Active tab
          Expanded(child: _tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner_rounded),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            activeIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// Home tab content — Today card + Quick actions + Recent activity.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Campus OS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your unified campus companion',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today card
            const TodayCard(),
            const SizedBox(height: 20),

            // Quick actions
            const QuickActionRow(),
            const SizedBox(height: 24),

            // Feature highlights
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Features',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureHighlight(
              icon: Icons.camera_alt_rounded,
              title: 'AI Note Scanner',
              subtitle: 'Scan notes → AI summaries + flashcards',
              color: AppColors.primaryPurple,
            ),
            _FeatureHighlight(
              icon: Icons.calendar_today_rounded,
              title: 'Smart Timetable',
              subtitle: 'Extract deadlines from WhatsApp screenshots',
              color: AppColors.accentCyan,
            ),
            _FeatureHighlight(
              icon: Icons.receipt_rounded,
              title: 'Expense Splitter',
              subtitle: 'Scan receipts, split costs, share via WhatsApp',
              color: AppColors.accentAmber,
            ),
            _FeatureHighlight(
              icon: Icons.search_rounded,
              title: 'Lost & Found',
              subtitle: 'Campus-wide lost item board with realtime updates',
              color: AppColors.accentPink,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// "More" tab — Lost & Found and Laptop Sync.
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('More'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryPurple,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(
                icon: Icon(Icons.search_rounded),
                text: 'Lost & Found',
              ),
              Tab(
                icon: Icon(Icons.sync_rounded),
                text: 'Laptop Sync',
              ),
            ],
          ),
        ),
        body: const TabBody(),
      ),
    );
  }
}

class TabBody extends StatelessWidget {
  const TabBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LostFoundScreen(),
        SyncScreen(),
      ],
    );
  }
}

/// Persistent offline banner shown at the top of the screen.
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.offlineBanner.withValues(alpha: 0.9),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Laptop not connected. Some features work offline.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to sync tab — user can manually dismiss
              },
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
