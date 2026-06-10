import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/isar_service.dart';
import '../../data/models/event_model.dart';
import '../../domain/usecases/add_event_usecase.dart';
import '../../domain/usecases/extract_deadline_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class TimetableEvent extends Equatable {
  const TimetableEvent();
  @override
  List<Object?> get props => [];
}

final class LoadWeekRequested extends TimetableEvent {
  final DateTime weekStart;
  const LoadWeekRequested({required this.weekStart});
  @override
  List<Object?> get props => [weekStart];
}

final class AddEventRequested extends TimetableEvent {
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  const AddEventRequested({
    required this.title,
    required this.startTime,
    this.endTime,
  });
  @override
  List<Object?> get props => [title, startTime, endTime];
}

final class AddEventFromOcr extends TimetableEvent {
  final DateTime deadline;
  final String title;
  final int? linkedNoteId;
  const AddEventFromOcr({
    required this.deadline,
    this.title = 'OCR Deadline',
    this.linkedNoteId,
  });
  @override
  List<Object?> get props => [deadline, title, linkedNoteId];
}

final class CompleteEventRequested extends TimetableEvent {
  final int eventId;
  const CompleteEventRequested({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

final class DeleteEventRequested extends TimetableEvent {
  final int eventId;
  const DeleteEventRequested({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

final class ExtractDeadlinesRequested extends TimetableEvent {
  final String imagePath;
  const ExtractDeadlinesRequested({required this.imagePath});
  @override
  List<Object?> get props => [imagePath];
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class TimetableState extends Equatable {
  const TimetableState();
  @override
  List<Object?> get props => [];
}

final class TimetableInitial extends TimetableState {
  const TimetableInitial();
}

final class TimetableLoading extends TimetableState {
  const TimetableLoading();
}

final class TimetableLoaded extends TimetableState {
  final List<EventModel> events;
  final DateTime weekStart;
  const TimetableLoaded({required this.events, required this.weekStart});
  @override
  List<Object?> get props => [events, weekStart];
}

final class EventAddedSuccess extends TimetableState {
  final EventModel event;
  const EventAddedSuccess({required this.event});
  @override
  List<Object?> get props => [event];
}

final class DeadlinesExtracted extends TimetableState {
  final List<EventModel> events;
  const DeadlinesExtracted({required this.events});
  @override
  List<Object?> get props => [events];
}

final class TimetableError extends TimetableState {
  final String message;
  const TimetableError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final AddEventUsecase _addEventUsecase;
  final ExtractDeadlineUsecase _extractDeadlineUsecase;
  final DatabaseService _databaseService;

  TimetableBloc({
    required AddEventUsecase addEventUsecase,
    required ExtractDeadlineUsecase extractDeadlineUsecase,
    required DatabaseService databaseService,
  })  : _addEventUsecase = addEventUsecase,
        _extractDeadlineUsecase = extractDeadlineUsecase,
        _databaseService = databaseService,
        super(const TimetableInitial()) {
    on<LoadWeekRequested>(_onLoadWeek);
    on<AddEventRequested>(_onAddEvent);
    on<AddEventFromOcr>(_onAddEventFromOcr);
    on<CompleteEventRequested>(_onCompleteEvent);
    on<DeleteEventRequested>(_onDeleteEvent);
    on<ExtractDeadlinesRequested>(_onExtractDeadlines);
  }

  Future<void> _onLoadWeek(
    LoadWeekRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(const TimetableLoading());

    try {
      final weekEnd = event.weekStart.add(const Duration(days: 7));
      final db = await _databaseService.database;

      final results = await db.query(
        'events',
        where: 'start_time >= ? AND start_time < ?',
        whereArgs: [
          event.weekStart.toIso8601String(),
          weekEnd.toIso8601String(),
        ],
        orderBy: 'start_time ASC',
      );

      final events = results.map((m) => EventModel.fromMap(m)).toList();

      emit(TimetableLoaded(events: events, weekStart: event.weekStart));
    } catch (e) {
      emit(TimetableError(message: 'Failed to load events: $e'));
    }
  }

  Future<void> _onAddEvent(
    AddEventRequested event,
    Emitter<TimetableState> emit,
  ) async {
    final result = await _addEventUsecase(
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime,
    );

    result.fold(
      (failure) => emit(TimetableError(message: failure.message)),
      (savedEvent) {
        emit(EventAddedSuccess(event: savedEvent));
        // Reload current week
        final weekStart = _getWeekStart(savedEvent.startTime);
        add(LoadWeekRequested(weekStart: weekStart));
      },
    );
  }

  Future<void> _onAddEventFromOcr(
    AddEventFromOcr event,
    Emitter<TimetableState> emit,
  ) async {
    final result = await _addEventUsecase(
      title: event.title,
      startTime: event.deadline,
      source: 'ocr_note',
      linkedNoteId: event.linkedNoteId,
    );

    result.fold(
      (failure) => emit(TimetableError(message: failure.message)),
      (savedEvent) => emit(EventAddedSuccess(event: savedEvent)),
    );
  }

  Future<void> _onCompleteEvent(
    CompleteEventRequested event,
    Emitter<TimetableState> emit,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'events',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [event.eventId],
      );

      // Reload
      if (state is TimetableLoaded) {
        add(LoadWeekRequested(
          weekStart: (state as TimetableLoaded).weekStart,
        ));
      }
    } catch (e) {
      emit(TimetableError(message: 'Failed to complete event: $e'));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventRequested event,
    Emitter<TimetableState> emit,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.delete('events', where: 'id = ?', whereArgs: [event.eventId]);

      if (state is TimetableLoaded) {
        add(LoadWeekRequested(
          weekStart: (state as TimetableLoaded).weekStart,
        ));
      }
    } catch (e) {
      emit(TimetableError(message: 'Failed to delete event: $e'));
    }
  }

  Future<void> _onExtractDeadlines(
    ExtractDeadlinesRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(const TimetableLoading());

    final result = await _extractDeadlineUsecase(event.imagePath);

    result.fold(
      (failure) => emit(TimetableError(message: failure.message)),
      (events) => emit(DeadlinesExtracted(events: events)),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
}
