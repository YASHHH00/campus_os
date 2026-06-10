import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/storage/isar_service.dart';
import 'package:get_it/get_it.dart';

/// Today's summary card — shows upcoming events and pending expenses.
///
/// Displayed at the top of the home screen for a quick daily overview.
class TodayCard extends StatefulWidget {
  const TodayCard({super.key});

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard> {
  int _todayEventCount = 0;
  int _pendingExpenses = 0;
  int _unsyncedNotes = 0;
  String? _nextEventTitle;
  String? _nextEventTime;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    try {
      final db = await GetIt.instance<DatabaseService>().database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Today's events
      final events = await db.query(
        'events',
        where: 'start_time >= ? AND start_time < ? AND is_completed = 0',
        whereArgs: [
          todayStart.toIso8601String(),
          todayEnd.toIso8601String(),
        ],
        orderBy: 'start_time ASC',
      );

      // Pending expenses
      final expenses = await db.query(
        'expenses',
        where: 'is_settled = 0',
      );

      // Unsynced notes
      final notes = await db.query(
        'notes',
        where: 'is_synced = 0',
      );

      if (mounted) {
        setState(() {
          _todayEventCount = events.length;
          _pendingExpenses = expenses.length;
          _unsyncedNotes = notes.length;

          if (events.isNotEmpty) {
            final next = events.first;
            _nextEventTitle = next['title'] as String?;
            final startTime =
                DateTime.parse(next['start_time'] as String);
            _nextEventTime = AppDateUtils.time12(startTime);
          }
        });
      }
    } catch (_) {
      // Silently handle — card shows zeros
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.relativeDay(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateUtils.dayMonthYear(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_todayEventCount event${_todayEventCount == 1 ? "" : "s"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_nextEventTitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next: $_nextEventTitle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _nextEventTime ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: Icons.receipt_rounded,
                label: '$_pendingExpenses pending',
                color: Colors.white70,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                icon: Icons.cloud_off_rounded,
                label: '$_unsyncedNotes unsynced',
                color: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
