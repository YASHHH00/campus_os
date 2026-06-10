import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/note_model.dart';
import '../entities/note_entity.dart';

/// Use case to retrieve flashcards for a specific note by ID.
///
/// Loads the note from the local database and parses the stored
/// flashcard JSON into [Flashcard] entities.
class GetFlashcardsUsecase {
  final DatabaseService _databaseService;

  GetFlashcardsUsecase({required DatabaseService databaseService})
      : _databaseService = databaseService;

  Future<Either<Failure, List<Flashcard>>> call(int noteId) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (results.isEmpty) {
        return const Left(StorageFailure(
          message: 'Note not found. It may have been deleted.',
        ));
      }

      final note = NoteModel.fromMap(results.first);
      final flashcards = note.flashcardJson
          .map((m) => Flashcard.fromMap(m))
          .toList();

      if (flashcards.isEmpty) {
        return const Left(StorageFailure(
          message:
              'No flashcards available for this note. Connect to your laptop to generate them.',
        ));
      }

      return Right(flashcards);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to load flashcards: $e',
      ));
    }
  }
}
