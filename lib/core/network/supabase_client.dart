import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Supabase initialization and convenience accessors.
///
/// Wraps [Supabase] singleton to provide typed access to auth, storage,
/// database, and realtime functionality used across the app.
class SupabaseClientService {
  static SupabaseClientService? _instance;

  SupabaseClientService._();

  factory SupabaseClientService() {
    _instance ??= SupabaseClientService._();
    return _instance!;
  }

  /// Initialize Supabase. Must be called once in [main] before runApp.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// The raw Supabase client.
  SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user, or null if not signed in.
  User? get currentUser => client.auth.currentUser;

  /// Current user ID, or empty string if not authenticated.
  String get currentUserId => currentUser?.id ?? '';

  /// Whether the user is authenticated.
  bool get isAuthenticated => currentUser != null;

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Sign in anonymously to enable realtime and storage access.
  Future<AuthResponse> signInAnonymously() async {
    return client.auth.signInAnonymously();
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── Database ───────────────────────────────────────────────────────────────

  /// Query builder for a given table.
  SupabaseQueryBuilder from(String table) => client.from(table);

  // ── Storage ────────────────────────────────────────────────────────────────

  /// Access a storage bucket by name.
  StorageFileApi storage(String bucket) => client.storage.from(bucket);

  /// Upload a file to a bucket and return the public URL.
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    await client.storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(contentType: contentType),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  /// Subscribe to INSERT events on a table with an optional filter.
  RealtimeChannel subscribeToInserts({
    required String table,
    required void Function(Map<String, dynamic> payload) onInsert,
    String? filterColumn,
    String? filterValue,
  }) {
    final channel = client.channel('public:$table');

    PostgresChangeFilter? filter;
    if (filterColumn != null && filterValue != null) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: filterColumn,
        value: filterValue,
      );
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: filter,
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a realtime channel.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ── Signaling (WebRTC pairing) ─────────────────────────────────────────────

  /// Post an SDP offer/answer to the signaling table.
  Future<void> postSignal({
    required String sessionId,
    required String type,
    required String sdp,
  }) async {
    await client.from(AppConstants.tableSignaling).insert({
      'session_id': sessionId,
      'type': type,
      'sdp': sdp,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Listen for signaling messages for a given session.
  RealtimeChannel listenForSignals({
    required String sessionId,
    required void Function(Map<String, dynamic> payload) onSignal,
  }) {
    return subscribeToInserts(
      table: AppConstants.tableSignaling,
      onInsert: onSignal,
      filterColumn: 'session_id',
      filterValue: sessionId,
    );
  }

  /// Clean up ephemeral signaling data after pairing.
  Future<void> deleteSignalingSession(String sessionId) async {
    await client
        .from(AppConstants.tableSignaling)
        .delete()
        .eq('session_id', sessionId);
  }
}
