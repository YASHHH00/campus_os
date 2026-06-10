import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/network/webrtc_service.dart';
import '../../../core/storage/isar_service.dart';
import '../../note_scanner/data/models/note_model.dart';

/// High-level WebRTC sync service for laptop pairing and note synchronization.
///
/// Manages:
/// - PIN/QR-based pairing via Supabase signaling
/// - SDP offer/answer exchange
/// - Note sync protocol (bulk send unsynced notes)
/// - Pending extraction retry on reconnect
class WebRtcSyncService {
  final WebRtcService _webRtcService;
  final SupabaseClientService _supabaseService;
  final DatabaseService _databaseService;
  static const _uuid = Uuid();

  String? _sessionId;
  String? _pairingPin;
  StreamSubscription? _signalingSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  WebRtcSyncService({
    required WebRtcService webRtcService,
    required SupabaseClientService supabaseService,
    required DatabaseService databaseService,
  })  : _webRtcService = webRtcService,
        _supabaseService = supabaseService,
        _databaseService = databaseService {
    _webRtcService.connectionState.listen(_onConnectionStateChanged);
    _webRtcService.messages.listen(_onMessage);
  }

  /// Current pairing PIN for display / QR encoding.
  String? get pairingPin => _pairingPin;

  /// Current session ID for the pairing flow.
  String? get sessionId => _sessionId;

  /// Whether laptop is connected.
  bool get isConnected => _webRtcService.isConnected;

  /// Connection state stream.
  Stream<bool> get connectionState => _webRtcService.connectionState;

  // ── Pairing Flow ───────────────────────────────────────────────────────────

  /// Generate a 6-digit PIN and start listening for the laptop's SDP answer.
  /// Returns the PIN for display as text or QR code.
  Future<String> initiatePairing() async {
    _sessionId = _uuid.v4();
    _pairingPin = _generatePin();

    // Create SDP offer
    final offer = await _webRtcService.createOffer();

    // Post offer to Supabase signaling channel
    await _supabaseService.postSignal(
      sessionId: _sessionId!,
      type: 'offer',
      sdp: jsonEncode({
        'sdp': offer.sdp,
        'type': offer.type,
        'pin': _pairingPin,
      }),
    );

    // Listen for answer
    _supabaseService.listenForSignals(
      sessionId: _sessionId!,
      onSignal: _handleSignalingMessage,
    );

    return _pairingPin!;
  }

  /// Accept a pairing with a given session ID and PIN.
  Future<void> acceptPairing(String sessionId, String pin) async {
    _sessionId = sessionId;
    _pairingPin = pin;

    // Listen for the offer
    _supabaseService.listenForSignals(
      sessionId: sessionId,
      onSignal: _handleSignalingMessage,
    );
  }

  void _handleSignalingMessage(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    final sdpData = payload['sdp'] as String?;

    if (sdpData == null) return;

    try {
      final decoded = jsonDecode(sdpData) as Map<String, dynamic>;

      if (type == 'answer') {
        final answer = RTCSessionDescription(decoded['sdp'], decoded['type']);
        await _webRtcService.setRemoteAnswer(answer);

        // Clean up signaling data
        if (_sessionId != null) {
          await _supabaseService.deleteSignalingSession(_sessionId!);
        }
      }
    } catch (_) {
      // Invalid signaling message
    }
  }

  // ── Note Sync ──────────────────────────────────────────────────────────────

  /// Sync all unsynced notes to the connected laptop.
  Future<int> syncUnsyncedNotes() async {
    if (!_webRtcService.isConnected) return 0;

    try {
      final db = await _databaseService.database;
      final unsynced = await db.query(
        'notes',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) return 0;

      final notes = unsynced.map((m) => NoteModel.fromMap(m)).toList();
      final notesJson = notes.map((n) => n.toJson()).toList();

      _webRtcService.sendMessage(
        type: 'note_sync',
        payload: {'notes': notesJson},
        requestId: _uuid.v4(),
      );

      return notes.length;
    } catch (_) {
      return 0;
    }
  }

  /// Retry pending deadline extractions that failed when offline.
  Future<void> retryPendingExtractions() async {
    if (!_webRtcService.isConnected) return;

    try {
      final db = await _databaseService.database;
      final pending = await db.query('pending_extractions');

      for (final row in pending) {
        final text = row['raw_text'] as String;
        _webRtcService.sendMessage(
          type: 'extract_deadline',
          payload: {'text': text},
          requestId: _uuid.v4(),
        );
      }

      // Clear pending (responses will come via message stream)
      if (pending.isNotEmpty) {
        await db.delete('pending_extractions');
      }
    } catch (_) {
      // Best-effort retry
    }
  }

  // ── Connection Lifecycle ───────────────────────────────────────────────────

  void _onConnectionStateChanged(bool connected) {
    if (connected) {
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      // Auto-sync on reconnect
      syncUnsyncedNotes();
      retryPendingExtractions();
    } else {
      _scheduleReconnect();
    }
  }

  void _onMessage(Map<String, dynamic> message) async {
    final type = message['type'] as String?;

    switch (type) {
      case 'sync_ack':
        final syncedIds = message['payload']?['syncedIds'] as List<dynamic>?;
        if (syncedIds != null) {
          await _markNotesSynced(syncedIds.cast<int>());
        }
      case 'ocr_response':
        // Handled by OcrRemoteSource via requestId matching
        break;
      default:
        break;
    }
  }

  Future<void> _markNotesSynced(List<int> ids) async {
    try {
      final db = await _databaseService.database;
      for (final id in ids) {
        await db.update(
          'notes',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // Best-effort update
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delay = min(
      AppConstants.reconnectBaseDelayMs *
          (1 << _reconnectAttempts),
      AppConstants.reconnectMaxDelayMs,
    );

    _reconnectTimer = Timer(
      Duration(milliseconds: delay),
      () {
        _reconnectAttempts++;
        if (_sessionId != null) {
          initiatePairing();
        }
      },
    );
  }

  /// Disconnect and clean up all resources.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _signalingSubscription?.cancel();
    await _webRtcService.disconnect();
    _sessionId = null;
    _pairingPin = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _webRtcService.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generatePin() {
    final random = Random.secure();
    return List.generate(
      AppConstants.pinLength,
      (_) => random.nextInt(10),
    ).join();
  }
}
