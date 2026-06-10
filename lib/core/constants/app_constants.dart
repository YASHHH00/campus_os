/// Application-wide constants for Campus OS.
///
/// All magic strings, URLs, keys, and configuration values are centralized here
/// to avoid duplication and make configuration changes straightforward.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'Campus OS';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'com.campusos.app';

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://zodonxxsapwbirmnrnwo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZG9ueHhzYXB3YmlybW5ybndvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2Nzc2MjksImV4cCI6MjA5NjI1MzYyOX0.EzkZBVEhF16P-CHQMNWUVmunChme0452eOiZ2RwQ2ss';

  // ── Supabase Tables ───────────────────────────────────────────────────────
  static const String tableLostItems = 'lost_items';
  static const String tableSignaling = 'signaling';

  // ── Supabase Storage Buckets ──────────────────────────────────────────────
  static const String bucketLostFound = 'lost-found-images';

  // ── WebRTC Configuration ──────────────────────────────────────────────────
  static const String dataChannelLabel = 'campus-os-sync';
  static const int webrtcTimeoutSeconds = 10;
  static const int heartbeatIntervalSeconds = 15;
  static const int heartbeatTimeoutSeconds = 5;
  static const int maxChunkSizeBytes = 64 * 1024; // 64KB frames
  static const int largePayloadThreshold = 2 * 1024 * 1024; // 2MB
  static const int pinLength = 6;

  // ── WebRTC ICE (LAN-only, no STUN/TURN) ───────────────────────────────────
  static const Map<String, dynamic> iceConfig = {
    'iceServers': <Map<String, dynamic>>[],
    'sdpSemantics': 'unified-plan',
  };

  // ── OCR / ML ──────────────────────────────────────────────────────────────
  static const double ocrConfidenceThreshold = 0.6;
  static const int maxImageCompressedSizeKb = 500;
  static const int maxImageUploadSizeMb = 5;

  // ── Laptop Endpoints (via WebRTC DataChannel) ─────────────────────────────
  static const String endpointOcr = '/ocr';
  static const String endpointExtractDeadline = '/extract_deadline';
  static const String endpointParseReceipt = '/parse_receipt';

  // ── Notification Channels ─────────────────────────────────────────────────
  static const String notifChannelDeadlines = 'deadlines_channel';
  static const String notifChannelDeadlinesName = 'Assignment Deadlines';
  static const String notifChannelLostFound = 'lost_found_channel';
  static const String notifChannelLostFoundName = 'Lost & Found Alerts';

  // ── SharedPreferences Keys ────────────────────────────────────────────────
  static const String prefNotifPermissionAsked = 'notif_permission_asked';
  static const String prefDarkMode = 'dark_mode';
  static const String prefUserId = 'user_id';
  static const String prefCollegeId = 'college_id';
  static const String prefLastSyncTimestamp = 'last_sync_timestamp';
  static const String prefWebrtcPairedDeviceId = 'webrtc_paired_device_id';

  // ── Database ──────────────────────────────────────────────────────────────
  static const String dbName = 'campus_os.db';
  static const int dbVersion = 1;

  // ── Reconnection ──────────────────────────────────────────────────────────
  static const int reconnectBaseDelayMs = 1000;
  static const int reconnectMaxDelayMs = 30000;

  // ── Validation ────────────────────────────────────────────────────────────
  static const int minTitleLength = 1;
  static const int maxTitleLength = 200;
  static const double minExpenseAmount = 0.01;
  static const int minParticipants = 2;
}
