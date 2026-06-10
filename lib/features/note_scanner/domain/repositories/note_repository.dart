import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/note_entity.dart';

/// Abstract repository contract for note operations.
///
/// Domain layer depends only on this interface — the data layer provides
/// the concrete implementation using sqflite + WebRTC remote source.
abstract class NoteRepository {
  /// Scan a note from an image file path.
  /// Runs local OCR, sends to laptop if connected, persists to DB.
  Future<Either<Failure, NoteEntity>> scanNote(String imagePath);

  /// Get all saved notes ordered by creation date (newest first).
  Future<Either<Failure, List<NoteEntity>>> getAllNotes();

  /// Get a single note by ID.
  Future<Either<Failure, NoteEntity>> getNoteById(int id);

  /// Get flashcards for a specific note.
  Future<Either<Failure, List<Flashcard>>> getFlashcards(int noteId);

  /// Get or generate a summary for a note.
  Future<Either<Failure, String>> getSummary(int noteId);

  /// Delete a note by ID.
  Future<Either<Failure, void>> deleteNote(int id);

  /// Sync all unsynced notes to the laptop.
  Future<Either<Failure, int>> syncUnsyncedNotes();

  /// Get count of unsynced notes.
  Future<Either<Failure, int>> getUnsyncedCount();
}
