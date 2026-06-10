/// Custom exception hierarchy for the data layer.
///
/// These exceptions are thrown in repositories and data sources, then caught
/// and mapped to [Failure] types before crossing into the domain/presentation
/// layers. Raw platform exceptions should never leak past the data layer.

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ServerException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class StorageException implements Exception {
  final String message;
  final String? code;

  const StorageException({required this.message, this.code});

  @override
  String toString() => 'StorageException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class WebRtcException implements Exception {
  final String message;
  final String? code;

  const WebRtcException({required this.message, this.code});

  @override
  String toString() => 'WebRtcException: $message';
}

class OcrException implements Exception {
  final String message;
  final double? confidence;

  const OcrException({required this.message, this.confidence});

  @override
  String toString() => 'OcrException: $message (confidence: $confidence)';
}

class ImageProcessingException implements Exception {
  final String message;

  const ImageProcessingException({required this.message});

  @override
  String toString() => 'ImageProcessingException: $message';
}

class PermissionDeniedException implements Exception {
  final String permissionType;
  final String message;

  const PermissionDeniedException({
    required this.permissionType,
    required this.message,
  });

  @override
  String toString() =>
      'PermissionDeniedException($permissionType): $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'ValidationException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}
