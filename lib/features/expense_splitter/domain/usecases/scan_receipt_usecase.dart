import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../note_scanner/data/datasources/ocr_remote_source.dart';

/// Scans a receipt image, runs OCR, and sends to laptop for AI parsing.
///
/// Returns parsed receipt data for pre-filling the expense form.
class ScanReceiptUsecase {
  final OcrRemoteSource _ocrRemoteSource;

  ScanReceiptUsecase({required OcrRemoteSource ocrRemoteSource})
      : _ocrRemoteSource = ocrRemoteSource;

  Future<Either<Failure, Map<String, dynamic>>> call(
      String imagePath) async {
    try {
      // Run local OCR first
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
          message: 'No text detected on receipt. Try a clearer photo.',
          confidence: 0.0,
        ));
      }

      // Send to laptop for AI parsing
      if (!_ocrRemoteSource.isConnected) {
        // Return raw text for manual entry
        return Right({
          'total': 0.0,
          'items': <Map<String, dynamic>>[],
          'suggested_split': <String, double>{},
          'raw_text': result.text,
        });
      }

      final response = await _ocrRemoteSource.parseReceipt(result.text);

      return Right({
        'total': (response['total'] as num?)?.toDouble() ?? 0.0,
        'items': response['items'] ?? <Map<String, dynamic>>[],
        'suggested_split': response['suggested_split'] ?? <String, double>{},
        'raw_text': result.text,
      });
    } on WebRtcException catch (e) {
      return Left(WebRtcFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to scan receipt: $e',
      ));
    }
  }
}
