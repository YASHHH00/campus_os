import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/webrtc_service.dart';

/// Remote data source that sends images to the laptop via WebRTC DataChannel
/// for OCR processing, summary generation, flashcard creation, and
/// deadline/amount extraction.
class OcrRemoteSource {
  final WebRtcService _webRtcService;
  static const _uuid = Uuid();

  OcrRemoteSource({required WebRtcService webRtcService})
      : _webRtcService = webRtcService;

  /// Whether the WebRTC connection to the laptop is active.
  bool get isConnected => _webRtcService.isConnected;

  /// Send an image to the laptop for OCR + AI processing.
  ///
  /// Returns a parsed response map:
  /// ```json
  /// {
  ///   "summary": "...",
  ///   "flashcards": [{"q": "...", "a": "..."}],
  ///   "deadline": "2025-06-15T23:59:00" | null,
  ///   "amount": "150.00" | null
  /// }
  /// ```
  ///
  /// Throws [WebRtcException] if not connected or times out.
  /// Throws [ServerException] if the laptop returns an error.
  Future<Map<String, dynamic>> processImage(Uint8List imageBytes) async {
    if (!_webRtcService.isConnected) {
      throw const WebRtcException(
        message: 'Not connected to laptop. Image saved for offline sync.',
        code: 'NOT_CONNECTED',
      );
    }

    final requestId = _uuid.v4();
    final payload = {
      'imageBase64': base64Encode(imageBytes),
      'requestId': requestId,
    };

    try {
      final response = await _webRtcService.sendRequest(
        type: 'ocr_request',
        payload: payload,
        requestId: requestId,
      );

      _validateResponse(response);
      return response;
    } on WebRtcException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to process image on laptop: $e',
      );
    }
  }

  /// Send extracted text to the laptop for deadline extraction.
  Future<List<Map<String, dynamic>>> extractDeadlines(String text) async {
    if (!_webRtcService.isConnected) {
      throw const WebRtcException(
        message: 'Not connected to laptop.',
        code: 'NOT_CONNECTED',
      );
    }

    final requestId = _uuid.v4();

    try {
      final response = await _webRtcService.sendRequest(
        type: 'extract_deadline',
        payload: {'text': text, 'requestId': requestId},
        requestId: requestId,
      );

      final events = response['events'] as List<dynamic>?;
      if (events == null) return [];

      return events.cast<Map<String, dynamic>>();
    } on WebRtcException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to extract deadlines: $e',
      );
    }
  }

  /// Send receipt text to the laptop for parsing.
  Future<Map<String, dynamic>> parseReceipt(String text) async {
    if (!_webRtcService.isConnected) {
      throw const WebRtcException(
        message: 'Not connected to laptop.',
        code: 'NOT_CONNECTED',
      );
    }

    final requestId = _uuid.v4();

    try {
      final response = await _webRtcService.sendRequest(
        type: 'parse_receipt',
        payload: {'text': text, 'requestId': requestId},
        requestId: requestId,
      );

      return response;
    } on WebRtcException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to parse receipt: $e',
      );
    }
  }

  void _validateResponse(Map<String, dynamic> response) {
    if (response.containsKey('error')) {
      throw ServerException(
        message: response['error'] as String? ?? 'Unknown laptop error',
        code: 'LAPTOP_ERROR',
      );
    }
  }
}
