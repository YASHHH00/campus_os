import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../data/models/event_model.dart';
import 'bloc/timetable_bloc.dart';

/// Weekly calendar timetable screen.
///
/// Features:
/// - Horizontal scrolling day selector (Mon-Sun)
/// - Event list for the selected day
/// - Long-press context menu for complete/delete
/// - FAB for adding events manually or via WhatsApp screenshot
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime _selectedDay;
  late DateTime _weekStart;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekStart = AppDateUtils.startOfWeek(_selectedDay);
    context.read<TimetableBloc>().add(LoadWeekRequested(weekStart: _weekStart));
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event title',
                hintText: 'e.g., Math Assignment Due',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Pick Date'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        selectedTime = time;
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: const Text('Pick Time'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    context.read<TimetableBloc>().add(AddEventRequested(
                          title: titleController.text,
                          startTime: selectedDate,
                        ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractFromScreenshot() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (mounted) {
        context
            .read<TimetableBloc>()
            .add(ExtractDeadlinesRequested(imagePath: image.path));
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Could not pick image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = AppDateUtils.weekDays(_weekStart);

    return Scaffold(
      appBar: CampusAppBar(
        title: 'Timetable',
        actions: [
          IconButton(
            icon: const Icon(Icons.screenshot_monitor_rounded),
            tooltip: 'Extract from WhatsApp screenshot',
            onPressed: _extractFromScreenshot,
          ),
        ],
      ),
      body: BlocConsumer<TimetableBloc, TimetableState>(
        listener: (context, state) {
          switch (state) {
            case EventAddedSuccess():
              ErrorSnackbar.showSuccess(context, 'Event added!');
            case DeadlinesExtracted(events: final events):
              ErrorSnackbar.showSuccess(
                context,
                '${events.length} deadline(s) extracted!',
              );
              context
                  .read<TimetableBloc>()
                  .add(LoadWeekRequested(weekStart: _weekStart));
            case TimetableError(message: final msg):
              ErrorSnackbar.showError(context, msg);
            default:
              break;
          }
        },
        builder: (context, state) {
          final allEvents = switch (state) {
            TimetableLoaded(events: final e) => e,
            _ => <EventModel>[],
          };

          final dayEvents = allEvents
              .where((e) =>
                  e.startTime.year == _selectedDay.year &&
                  e.startTime.month == _selectedDay.month &&
                  e.startTime.day == _selectedDay.day)
              .toList();

          return Column(
            children: [
              // Week selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((day) {
                    final isSelected = day.day == _selectedDay.day &&
                        day.month == _selectedDay.month;
                    final isToday = AppDateUtils.isToday(day);
                    final hasEvents = allEvents.any((e) =>
                        e.startTime.year == day.year &&
                        e.startTime.month == day.month &&
                        e.startTime.day == day.day);

                    return GestureDetector(
                      onTap: () => _selectDay(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.primaryPurple
                                      .withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppDateUtils.shortWeekday(day),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppDateUtils.dayOfMonth(day),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasEvents) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.accentCyan,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),

              // Events list
              Expanded(
                child: dayEvents.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.event_available_rounded,
                        title: 'No Events',
                        subtitle: 'Nothing scheduled for this day.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) =>
                            _EventTile(event: dayEvents[index]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        heroTag: 'add_event_fab',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventModel event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final sourceIcon = switch (event.source) {
      'ocr_note' => Icons.document_scanner_rounded,
      'whatsapp_screenshot' => Icons.screenshot_rounded,
      _ => Icons.event_rounded,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: event.isOverdue
                      ? AppColors.error
                      : event.isCompleted
                          ? AppColors.success
                          : AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(sourceIcon, size: 20, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: event.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppDateUtils.time12(event.startTime),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (event.isOverdue && !event.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Overdue',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!event.isCompleted)
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                title: const Text('Mark as Complete'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (event.id != null) {
                    context.read<TimetableBloc>().add(
                          CompleteEventRequested(eventId: event.id!),
                        );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                if (event.id != null) {
                  context.read<TimetableBloc>().add(
                        DeleteEventRequested(eventId: event.id!),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
