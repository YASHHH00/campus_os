import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// WebRTC peer connection manager for LAN-only laptop sync.
///
/// Handles:
/// - RTCPeerConnection lifecycle with LAN-only ICE (no STUN/TURN)
/// - RTCDataChannel for bidirectional JSON messaging
/// - Heartbeat (ping/pong every 15s, timeout at 5s)
/// - Large payload chunking (64KB frames with sequence numbers)
/// - Request/response matching via requestId map
/// - Auto-reconnect on channel close
class WebRtcService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer;

  bool _isConnected = false;
  bool _isInitiator = false;

  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<String, _ChunkedMessage> _incomingChunks = {};

  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream that emits `true` when connected, `false` when disconnected.
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Stream of incoming messages (already reassembled if chunked).
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Whether the DataChannel is currently open.
  bool get isConnected => _isConnected;

  // ── Connection Lifecycle ───────────────────────────────────────────────────

  /// Create a peer connection as the initiator (phone side).
  /// Returns the SDP offer to send to the laptop via signaling.
  Future<RTCSessionDescription> createOffer() async {
    _isInitiator = true;
    await _createPeerConnection();

    _dataChannel = await _peerConnection!.createDataChannel(
      AppConstants.dataChannelLabel,
      RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30,
    );
    _setupDataChannelListeners(_dataChannel!);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// Accept an SDP offer from the laptop and return an answer.
  Future<RTCSessionDescription> createAnswer(
      RTCSessionDescription offer) async {
    _isInitiator = false;
    await _createPeerConnection();

    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  /// Set the remote SDP answer (called by the initiator after receiving answer).
  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  /// Add a remote ICE candidate.
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(AppConstants.iceConfig);

    _peerConnection!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _handleDisconnect();
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannelListeners(channel);
    };
  }

  void _setupDataChannelListeners(RTCDataChannel channel) {
    channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _isConnected = true;
        _connectionStateController.add(true);
        _startHeartbeat();
      } else if (state == RTCDataChannelState.RTCDataChannelClosing ||
          state == RTCDataChannelState.RTCDataChannelClosed) {
        _handleDisconnect();
      }
    };

    channel.onMessage = (RTCDataChannelMessage message) {
      _handleIncomingMessage(message);
    };
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  /// Send a request and wait for a response matched by [requestId].
  ///
  /// Throws [WebRtcException] if not connected or response times out.
  Future<Map<String, dynamic>> sendRequest({
    required String type,
    required Map<String, dynamic> payload,
    required String requestId,
    Duration timeout = const Duration(seconds: AppConstants.webrtcTimeoutSeconds),
  }) async {
    if (!_isConnected || _dataChannel == null) {
      throw const WebRtcException(
        message: 'WebRTC not connected. Please pair with your laptop first.',
        code: 'NOT_CONNECTED',
      );
    }

    final message = jsonEncode({
      'type': type,
      'requestId': requestId,
      'payload': payload,
    });

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    _sendRaw(message);

    try {
      return await completer.future.timeout(timeout, onTimeout: () {
        _pendingRequests.remove(requestId);
        throw const WebRtcException(
          message: 'Laptop did not respond within timeout. Using offline mode.',
          code: 'TIMEOUT',
        );
      });
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  /// Fire-and-forget message send (for sync, ack, etc.).
  void sendMessage({
    required String type,
    required Map<String, dynamic> payload,
    String? requestId,
  }) {
    if (!_isConnected || _dataChannel == null) return;

    final message = jsonEncode({
      'type': type,
      if (requestId != null) 'requestId': requestId,
      'payload': payload,
    });

    _sendRaw(message);
  }

  void _sendRaw(String message) {
    final bytes = utf8.encode(message);

    if (bytes.length > AppConstants.largePayloadThreshold) {
      _sendChunked(bytes);
    } else {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  // ── Chunked Transfer ──────────────────────────────────────────────────────

  void _sendChunked(List<int> bytes) {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final totalChunks =
        (bytes.length / AppConstants.maxChunkSizeBytes).ceil();

    for (var i = 0; i < totalChunks; i++) {
      final start = i * AppConstants.maxChunkSizeBytes;
      final end = min(start + AppConstants.maxChunkSizeBytes, bytes.length);
      final chunk = bytes.sublist(start, end);

      final envelope = jsonEncode({
        'type': '_chunk',
        'messageId': messageId,
        'seq': i,
        'total': totalChunks,
        'data': base64Encode(chunk),
      });

      _dataChannel!.send(RTCDataChannelMessage(envelope));
    }
  }

  void _handleIncomingMessage(RTCDataChannelMessage message) {
    try {
      final data = jsonDecode(message.text) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == '_chunk') {
        _handleChunk(data);
        return;
      }

      if (type == 'pong') {
        _heartbeatTimeoutTimer?.cancel();
        return;
      }

      if (type == 'ping') {
        sendMessage(type: 'pong', payload: {});
        return;
      }

      // Check if this is a response to a pending request
      final requestId = data['requestId'] as String?;
      if (requestId != null && _pendingRequests.containsKey(requestId)) {
        _pendingRequests.remove(requestId)!.complete(
          data['payload'] as Map<String, dynamic>? ?? data,
        );
        return;
      }

      // Broadcast as a general incoming message
      _messageController.add(data);
    } catch (e) {
      // Malformed message — ignore silently
    }
  }

  void _handleChunk(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    final seq = data['seq'] as int;
    final total = data['total'] as int;
    final chunkData = base64Decode(data['data'] as String);

    _incomingChunks.putIfAbsent(
      messageId,
      () => _ChunkedMessage(total: total),
    );

    final chunked = _incomingChunks[messageId]!;
    chunked.chunks[seq] = chunkData;

    if (chunked.isComplete) {
      _incomingChunks.remove(messageId);
      final fullBytes = <int>[];
      for (var i = 0; i < total; i++) {
        fullBytes.addAll(chunked.chunks[i]!);
      }

      try {
        final fullMessage =
            jsonDecode(utf8.decode(fullBytes)) as Map<String, dynamic>;
        _handleIncomingMessage(
          RTCDataChannelMessage(jsonEncode(fullMessage)),
        );
      } catch (_) {
        // Reassembly failed — discard
      }
    }
  }

  // ── Heartbeat ──────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.heartbeatIntervalSeconds),
      (_) {
        if (!_isConnected) return;

        sendMessage(type: 'ping', payload: {});

        _heartbeatTimeoutTimer?.cancel();
        _heartbeatTimeoutTimer = Timer(
          const Duration(seconds: AppConstants.heartbeatTimeoutSeconds),
          () {
            _handleDisconnect();
          },
        );
      },
    );
  }

  // ── Disconnect & Cleanup ───────────────────────────────────────────────────

  void _handleDisconnect() {
    if (!_isConnected) return;
    _isConnected = false;
    _connectionStateController.add(false);
    _heartbeatTimer?.cancel();
    _heartbeatTimeoutTimer?.cancel();

    // Fail all pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const WebRtcException(
            message: 'WebRTC disconnected.',
            code: 'DISCONNECTED',
          ),
        );
      }
    }
    _pendingRequests.clear();
  }

  Future<void> disconnect() async {
    _handleDisconnect();
    await _dataChannel?.close();
    await _peerConnection?.close();
    _dataChannel = null;
    _peerConnection = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _messageController.close();
  }
}

/// Internal helper for reassembling chunked messages.
class _ChunkedMessage {
  final int total;
  final Map<int, Uint8List> chunks = {};

  _ChunkedMessage({required this.total});

  bool get isComplete => chunks.length == total;
}
