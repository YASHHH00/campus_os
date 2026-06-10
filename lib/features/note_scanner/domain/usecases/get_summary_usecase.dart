import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/note_model.dart';

/// Use case to retrieve or generate a summary for a specific note.
///
/// If the note already has a summary (from a previous laptop sync),
/// it returns it directly. If no summary exists and the laptop is
/// not connected, it returns a prompt to connect.
class GetSummaryUsecase {
  final DatabaseService _databaseService;

  GetSummaryUsecase({required DatabaseService databaseService})
      : _databaseService = databaseService;

  Future<Either<Failure, String>> call(int noteId) async {
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

      if (note.summaryText.isNotEmpty) {
        return Right(note.summaryText);
      }

      // No summary available yet — need laptop connection
      return const Left(WebRtcFailure(
        message:
            'Summary not yet generated. Connect to your laptop to generate an AI summary.',
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to load summary: $e',
      ));
    }
  }
}
