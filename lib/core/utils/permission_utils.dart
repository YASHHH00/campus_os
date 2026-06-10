import 'package:permission_handler/permission_handler.dart';

/// Utility for requesting and checking runtime permissions.
///
/// Wraps [permission_handler] with app-specific logic:
/// - Returns typed results instead of raw PermissionStatus
/// - Handles "permanently denied" by directing to app settings
/// - Tracks whether notification permission has been asked before
class PermissionUtils {
  PermissionUtils._();

  /// Request camera permission. Returns `true` if granted.
  static Future<bool> requestCamera() async {
    return _requestPermission(Permission.camera);
  }

  /// Request notification permission (Android 13+). Returns `true` if granted.
  static Future<bool> requestNotifications() async {
    return _requestPermission(Permission.notification);
  }

  /// Request storage permission for saving images.
  /// On Android 13+, uses granular media permissions.
  static Future<bool> requestStorage() async {
    // Android 13+ uses granular photo permissions
    if (await Permission.photos.isGranted) return true;

    final status = await Permission.photos.request();
    if (status.isGranted) return true;

    // Fallback for older Android
    return _requestPermission(Permission.storage);
  }

  /// Request microphone permission (needed for WebRTC).
  static Future<bool> requestMicrophone() async {
    return _requestPermission(Permission.microphone);
  }

  /// Check if camera permission is currently granted.
  static Future<bool> get isCameraGranted => Permission.camera.isGranted;

  /// Check if notification permission is currently granted.
  static Future<bool> get isNotificationGranted =>
      Permission.notification.isGranted;

  /// Open the system app settings page (for permanently denied permissions).
  static Future<bool> openSettings() => openAppSettings();

  /// Check if a permission is permanently denied (user chose "Don't ask again").
  static Future<bool> isPermanentlyDenied(Permission permission) =>
      permission.isPermanentlyDenied;

  static Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      return false;
    }

    final result = await permission.request();
    return result.isGranted;
  }
}
