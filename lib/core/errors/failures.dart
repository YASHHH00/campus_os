import 'package:equatable/equatable.dart';

/// Sealed failure hierarchy for typed error handling across the app.
///
/// Every use case returns `Either<Failure, T>` — raw exceptions are caught
/// in the data layer and mapped to one of these typed failures before
/// reaching the presentation layer.
sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server-side errors from Supabase or laptop backend.
final class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Local database (sqflite) read/write failures.
final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

/// Camera, notification, or file system permission denied.
final class PermissionFailure extends Failure {
  final String permissionType;

  const PermissionFailure({
    required super.message,
    required this.permissionType,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, permissionType];
}

/// No internet connection or Supabase unreachable.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// WebRTC connection issues — timeout, disconnect, channel failure.
final class WebRtcFailure extends Failure {
  const WebRtcFailure({required super.message, super.code});
}

/// Input validation errors — invalid amounts, empty fields, etc.
final class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.code,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// OCR confidence too low — image blurry or too dark.
final class OcrConfidenceFailure extends Failure {
  final double confidence;

  const OcrConfidenceFailure({
    required super.message,
    required this.confidence,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, confidence];
}

/// Image processing failures — too large, corrupt, compression failed.
final class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({required super.message, super.code});
}

/// Item already claimed by another user in Lost & Found.
final class ItemAlreadyClaimedFailure extends Failure {
  final String claimedByUserId;

  const ItemAlreadyClaimedFailure({
    required super.message,
    required this.claimedByUserId,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, claimedByUserId];
}

/// Malformed response from laptop LLM — JSON parse failed.
final class MalformedResponseFailure extends Failure {
  const MalformedResponseFailure({required super.message, super.code});
}

/// Cache miss or expired data.
final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}
