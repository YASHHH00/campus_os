import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/isar_service.dart';
import '../../../note_scanner/data/datasources/ocr_remote_source.dart';
import '../../data/models/event_model.dart';

/// Extracts deadlines from WhatsApp screenshots or other images.
///
/// Flow:
/// 1. Run ML Kit OCR on the image
/// 2. Send extracted text to laptop /extract_deadline endpoint
/// 3. Parse response: {events: [{title, datetime}]}
/// 4. Filter out past deadlines (mark as overdue)
/// 5. Batch insert into local DB
/// 6. Handle offline case: store raw text in pending_extractions
class ExtractDeadlineUsecase {
  final DatabaseService _databaseService;
  final OcrRemoteSource _ocrRemoteSource;

  ExtractDeadlineUsecase({
    required DatabaseService databaseService,
    required OcrRemoteSource ocrRemoteSource,
  })  : _databaseService = databaseService,
        _ocrRemoteSource = ocrRemoteSource;

  Future<Either<Failure, List<EventModel>>> call(String imagePath) async {
    try {
      // Step 1: Run local OCR
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText result;

      try {
        result = await textRecognizer.processImage(inputImage);
      } finally {
        await textRecognizer.close();
      }

      if (result.text.isEmpty) {
        return const Left(OcrConfidenceFailure(
          message: 'No text detected in screenshot.',
          confidence: 0.0,
        ));
      }

      final extractedText = result.text;

      // Step 2: Send to laptop for AI extraction
      if (!_ocrRemoteSource.isConnected) {
        // Offline: save to pending_extractions for later processing
        final db = await _databaseService.database;
        await db.insert('pending_extractions', {
          'raw_text': extractedText,
          'image_path': imagePath,
          'created_at': DateTime.now().toIso8601String(),
          'extraction_type': 'deadline',
        });

        return const Left(WebRtcFailure(
          message:
              'Not connected to laptop. Deadline extraction queued for when you reconnect.',
        ));
      }

      // Step 3: Get AI-extracted events
      final rawEvents = await _ocrRemoteSource.extractDeadlines(extractedText);

      if (rawEvents.isEmpty) {
        return const Left(MalformedResponseFailure(
          message: 'No deadlines found in the screenshot.',
        ));
      }

      // Step 4: Parse and filter
      final now = DateTime.now();
      final events = <EventModel>[];
      final db = await _databaseService.database;

      for (final raw in rawEvents) {
        final title = raw['title'] as String?;
        final dateStr = raw['datetime'] as String?;
        if (title == null || dateStr == null) continue;

        final dateTime = DateTime.tryParse(dateStr);
        if (dateTime == null) continue;

        final isOverdue = dateTime.isBefore(now);

        final event = EventModel(
          title: title,
          startTime: dateTime,
          source: 'whatsapp_screenshot',
          isCompleted: isOverdue, // Mark past deadlines as completed/overdue
          createdAt: DateTime.now(),
        );

        // Step 5: Insert into DB
        final eventId = await db.insert('events', event.toMap());
        events.add(event.copyWith(id: eventId));
      }

      if (events.isEmpty) {
        return const Left(MalformedResponseFailure(
          message: 'Could not parse any valid deadlines from the response.',
        ));
      }

      return Right(events);
    } on WebRtcException catch (e) {
      return Left(WebRtcFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to extract deadlines: $e',
      ));
    }
  }
}
