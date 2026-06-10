import 'package:intl/intl.dart';

/// Date/time utility helpers for consistent formatting across the app.
///
/// Uses the `intl` package for locale-aware formatting. All methods are
/// pure functions with no side effects.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _time24 = DateFormat('HH:mm');
  static final DateFormat _time12 = DateFormat('h:mm a');
  static final DateFormat _fullDateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _weekday = DateFormat('EEEE');
  static final DateFormat _shortWeekday = DateFormat('EEE');
  static final DateFormat _iso8601 = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _dayOfMonth = DateFormat('d');

  /// Format as "5 Jun"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// Format as "5 Jun 2025"
  static String dayMonthYear(DateTime date) => _dayMonthYear.format(date);

  /// Format as "14:30"
  static String time24(DateTime date) => _time24.format(date);

  /// Format as "2:30 PM"
  static String time12(DateTime date) => _time12.format(date);

  /// Format as "5 Jun 2025, 2:30 PM"
  static String fullDateTime(DateTime date) => _fullDateTime.format(date);

  /// Format as "Monday"
  static String weekday(DateTime date) => _weekday.format(date);

  /// Format as "Mon"
  static String shortWeekday(DateTime date) => _shortWeekday.format(date);

  /// Format as ISO 8601 string for storage.
  static String toIso8601(DateTime date) => _iso8601.format(date);

  /// Parse ISO 8601 string back to DateTime.
  static DateTime fromIso8601(String iso) => DateTime.parse(iso);

  /// Format as "June 2025"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// Format as "5" (day of month only).
  static String dayOfMonth(DateTime date) => _dayOfMonth.format(date);

  /// Returns "Today", "Tomorrow", "Yesterday", or the formatted date.
  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return dayMonthYear(date);
  }

  /// Returns "2h ago", "5m ago", "just now", or the date if > 24h.
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dayMonthYear(date);
  }

  /// Check if a date is in the past.
  static bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Check if a date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get the start of the week (Monday) for a given date.
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// Get all 7 days of the week starting from a given date's Monday.
  static List<DateTime> weekDays(DateTime date) {
    final monday = startOfWeek(date);
    return List.generate(
      7,
      (i) => monday.add(Duration(days: i)),
    );
  }
}
