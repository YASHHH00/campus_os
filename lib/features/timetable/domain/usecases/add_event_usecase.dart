import 'package:dartz/dartz.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/isar_service.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../data/models/event_model.dart';

/// Adds a manual event and schedules a local notification.
///
/// Handles:
/// - Past deadline → skip notification scheduling, mark as overdue
/// - Notification permission not granted → prompt once, store flag in prefs
/// - Notification scheduling via flutter_local_notifications
class AddEventUsecase {
  final DatabaseService _databaseService;
  final PrefsService _prefsService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  AddEventUsecase({
    required DatabaseService databaseService,
    required PrefsService prefsService,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  })  : _databaseService = databaseService,
        _prefsService = prefsService,
        _notificationsPlugin = notificationsPlugin;

  Future<Either<Failure, EventModel>> call({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String source = 'manual',
    int? linkedNoteId,
  }) async {
    try {
      // Validate
      if (title.trim().isEmpty) {
        return const Left(ValidationFailure(
          message: 'Event title cannot be empty.',
        ));
      }

      final now = DateTime.now();
      final isPast = startTime.isBefore(now);

      final event = EventModel(
        title: title.trim(),
        startTime: startTime,
        endTime: endTime,
        source: source,
        isCompleted: isPast,
        linkedNoteId: linkedNoteId,
        createdAt: now,
      );

      // Insert into DB
      final db = await _databaseService.database;
      final eventId = await db.insert('events', event.toMap());
      final savedEvent = event.copyWith(id: eventId);

      // Schedule notification if event is in the future
      if (!isPast) {
        await _scheduleNotification(savedEvent);
      }

      return Right(savedEvent);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to add event: $e',
      ));
    }
  }

  Future<void> _scheduleNotification(EventModel event) async {
    // Check notification permission
    final hasPermission = await PermissionUtils.isNotificationGranted;
    if (!hasPermission) {
      final hasAsked = await _prefsService.hasAskedNotificationPermission;
      if (!hasAsked) {
        await PermissionUtils.requestNotifications();
        await _prefsService.setNotificationPermissionAsked(true);
      }

      // Re-check after request
      final granted = await PermissionUtils.isNotificationGranted;
      if (!granted) return;
    }

    // Schedule 30 minutes before the event
    final notifyTime =
        event.startTime.subtract(const Duration(minutes: 30));
    if (notifyTime.isBefore(DateTime.now())) return;

    try {
      await _notificationsPlugin.zonedSchedule(
        event.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '📅 Upcoming: ${event.title}',
        'Starts at ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
        tz.TZDateTime.from(notifyTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notifChannelDeadlines,
            AppConstants.notifChannelDeadlinesName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Notification scheduling failed silently — event is still saved
    }
  }
}
