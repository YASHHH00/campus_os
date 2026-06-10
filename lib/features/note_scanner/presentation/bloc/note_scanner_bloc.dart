import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/isar_service.dart';
import '../../data/models/note_model.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/scan_note_usecase.dart';
import '../../domain/usecases/get_flashcards_usecase.dart';
import '../../domain/usecases/get_summary_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class NoteScannerEvent extends Equatable {
  const NoteScannerEvent();

  @override
  List<Object?> get props => [];
}

final class ScanNoteRequested extends NoteScannerEvent {
  final String imagePath;
  const ScanNoteRequested({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

final class LoadNotesRequested extends NoteScannerEvent {
  const LoadNotesRequested();
}

final class LoadFlashcardsRequested extends NoteScannerEvent {
  final int noteId;
  const LoadFlashcardsRequested({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}

final class LoadSummaryRequested extends NoteScannerEvent {
  final int noteId;
  const LoadSummaryRequested({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}

final class DeleteNoteRequested extends NoteScannerEvent {
  final int noteId;
  const DeleteNoteRequested({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class NoteScannerState extends Equatable {
  const NoteScannerState();

  @override
  List<Object?> get props => [];
}

final class NoteScannerInitial extends NoteScannerState {
  const NoteScannerInitial();
}

final class NoteScannerLoading extends NoteScannerState {
  final String? message;
  const NoteScannerLoading({this.message});

  @override
  List<Object?> get props => [message];
}

final class NotesLoaded extends NoteScannerState {
  final List<NoteEntity> notes;
  const NotesLoaded({required this.notes});

  @override
  List<Object?> get props => [notes];
}

final class NoteScanSuccess extends NoteScannerState {
  final NoteEntity note;
  const NoteScanSuccess({required this.note});

  @override
  List<Object?> get props => [note];
}

final class FlashcardsLoaded extends NoteScannerState {
  final List<Flashcard> flashcards;
  final int noteId;
  const FlashcardsLoaded({required this.flashcards, required this.noteId});

  @override
  List<Object?> get props => [flashcards, noteId];
}

final class SummaryLoaded extends NoteScannerState {
  final String summary;
  final int noteId;
  const SummaryLoaded({required this.summary, required this.noteId});

  @override
  List<Object?> get props => [summary, noteId];
}

final class LowConfidenceWarning extends NoteScannerState {
  final NoteEntity partialNote;
  final double confidence;
  const LowConfidenceWarning({
    required this.partialNote,
    required this.confidence,
  });

  @override
  List<Object?> get props => [partialNote, confidence];
}

final class NoteScannerError extends NoteScannerState {
  final String message;
  const NoteScannerError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class NoteDeletedSuccess extends NoteScannerState {
  const NoteDeletedSuccess();
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class NoteScannerBloc extends Bloc<NoteScannerEvent, NoteScannerState> {
  final ScanNoteUsecase _scanNoteUsecase;
  final GetFlashcardsUsecase _getFlashcardsUsecase;
  final GetSummaryUsecase _getSummaryUsecase;
  final DatabaseService _databaseService;

  NoteScannerBloc({
    required ScanNoteUsecase scanNoteUsecase,
    required GetFlashcardsUsecase getFlashcardsUsecase,
    required GetSummaryUsecase getSummaryUsecase,
    required DatabaseService databaseService,
  })  : _scanNoteUsecase = scanNoteUsecase,
        _getFlashcardsUsecase = getFlashcardsUsecase,
        _getSummaryUsecase = getSummaryUsecase,
        _databaseService = databaseService,
        super(const NoteScannerInitial()) {
    on<ScanNoteRequested>(_onScanNote);
    on<LoadNotesRequested>(_onLoadNotes);
    on<LoadFlashcardsRequested>(_onLoadFlashcards);
    on<LoadSummaryRequested>(_onLoadSummary);
    on<DeleteNoteRequested>(_onDeleteNote);
  }

  Future<void> _onScanNote(
    ScanNoteRequested event,
    Emitter<NoteScannerState> emit,
  ) async {
    emit(const NoteScannerLoading(message: 'Scanning note...'));

    final result = await _scanNoteUsecase(event.imagePath);

    result.fold(
      (failure) => emit(NoteScannerError(message: failure.message)),
      (note) {
        // Check if OCR returned a low confidence result
        if (note.rawText.startsWith('[Low confidence:')) {
          emit(LowConfidenceWarning(
            partialNote: note,
            confidence: 0.5, // approximate
          ));
        } else {
          emit(NoteScanSuccess(note: note));
        }
      },
    );
  }

  Future<void> _onLoadNotes(
    LoadNotesRequested event,
    Emitter<NoteScannerState> emit,
  ) async {
    emit(const NoteScannerLoading(message: 'Loading notes...'));

    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'notes',
        orderBy: 'created_at DESC',
      );

      final notes = results.map((map) {
        final model = NoteModel.fromMap(map);
        return NoteEntity(
          id: model.id,
          rawText: model.rawText,
          summaryText: model.summaryText,
          flashcards: model.flashcardJson
              .map((m) => Flashcard.fromMap(m))
              .toList(),
          imagePath: model.imagePath,
          createdAt: model.createdAt,
          isSynced: model.isSynced,
          detectedDeadline: model.detectedDeadline != null
              ? DateTime.tryParse(model.detectedDeadline!)
              : null,
          detectedAmount: model.detectedAmount != null
              ? double.tryParse(model.detectedAmount!)
              : null,
        );
      }).toList();

      emit(NotesLoaded(notes: notes));
    } catch (e) {
      emit(NoteScannerError(message: 'Failed to load notes: $e'));
    }
  }

  Future<void> _onLoadFlashcards(
    LoadFlashcardsRequested event,
    Emitter<NoteScannerState> emit,
  ) async {
    emit(const NoteScannerLoading(message: 'Loading flashcards...'));

    final result = await _getFlashcardsUsecase(event.noteId);

    result.fold(
      (failure) => emit(NoteScannerError(message: failure.message)),
      (flashcards) => emit(FlashcardsLoaded(
        flashcards: flashcards,
        noteId: event.noteId,
      )),
    );
  }

  Future<void> _onLoadSummary(
    LoadSummaryRequested event,
    Emitter<NoteScannerState> emit,
  ) async {
    emit(const NoteScannerLoading(message: 'Loading summary...'));

    final result = await _getSummaryUsecase(event.noteId);

    result.fold(
      (failure) => emit(NoteScannerError(message: failure.message)),
      (summary) => emit(SummaryLoaded(
        summary: summary,
        noteId: event.noteId,
      )),
    );
  }

  Future<void> _onDeleteNote(
    DeleteNoteRequested event,
    Emitter<NoteScannerState> emit,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.delete('notes', where: 'id = ?', whereArgs: [event.noteId]);
      emit(const NoteDeletedSuccess());
      add(const LoadNotesRequested());
    } catch (e) {
      emit(NoteScannerError(message: 'Failed to delete note: $e'));
    }
  }
}
