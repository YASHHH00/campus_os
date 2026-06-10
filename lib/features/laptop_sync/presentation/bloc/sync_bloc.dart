import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/webrtc_sync_service.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

final class InitPairingRequested extends SyncEvent {
  const InitPairingRequested();
}

final class DisconnectRequested extends SyncEvent {
  const DisconnectRequested();
}

final class SyncNotesRequested extends SyncEvent {
  const SyncNotesRequested();
}

final class CheckConnectionStatus extends SyncEvent {
  const CheckConnectionStatus();
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

final class SyncInitial extends SyncState {
  const SyncInitial();
}

final class SyncPairing extends SyncState {
  final String pin;
  final String sessionId;
  const SyncPairing({required this.pin, required this.sessionId});
  @override
  List<Object?> get props => [pin, sessionId];
}

final class SyncConnected extends SyncState {
  const SyncConnected();
}

final class SyncDisconnected extends SyncState {
  const SyncDisconnected();
}

final class SyncInProgress extends SyncState {
  final String message;
  const SyncInProgress({this.message = 'Syncing...'});
  @override
  List<Object?> get props => [message];
}

final class SyncCompleted extends SyncState {
  final int notesSynced;
  const SyncCompleted({required this.notesSynced});
  @override
  List<Object?> get props => [notesSynced];
}

final class SyncError extends SyncState {
  final String message;
  const SyncError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final WebRtcSyncService _syncService;
  StreamSubscription<bool>? _connectionSubscription;

  SyncBloc({required WebRtcSyncService syncService})
      : _syncService = syncService,
        super(const SyncInitial()) {
    on<InitPairingRequested>(_onInitPairing);
    on<DisconnectRequested>(_onDisconnect);
    on<SyncNotesRequested>(_onSyncNotes);
    on<CheckConnectionStatus>(_onCheckConnection);

    // Listen to connection state changes
    _connectionSubscription =
        _syncService.connectionState.listen((connected) {
      if (connected) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(const SyncConnected());
      } else if (state is SyncConnected) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(const SyncDisconnected());
      }
    });
  }

  Future<void> _onInitPairing(
    InitPairingRequested event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final pin = await _syncService.initiatePairing();
      emit(SyncPairing(
        pin: pin,
        sessionId: _syncService.sessionId ?? '',
      ));
    } catch (e) {
      emit(SyncError(message: 'Failed to start pairing: $e'));
    }
  }

  Future<void> _onDisconnect(
    DisconnectRequested event,
    Emitter<SyncState> emit,
  ) async {
    await _syncService.disconnect();
    emit(const SyncDisconnected());
  }

  Future<void> _onSyncNotes(
    SyncNotesRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!_syncService.isConnected) {
      emit(const SyncError(
        message: 'Not connected to laptop. Pair first.',
      ));
      return;
    }

    emit(const SyncInProgress(message: 'Syncing notes...'));

    try {
      final count = await _syncService.syncUnsyncedNotes();
      emit(SyncCompleted(notesSynced: count));
    } catch (e) {
      emit(SyncError(message: 'Sync failed: $e'));
    }
  }

  Future<void> _onCheckConnection(
    CheckConnectionStatus event,
    Emitter<SyncState> emit,
  ) async {
    if (_syncService.isConnected) {
      emit(const SyncConnected());
    } else {
      emit(const SyncDisconnected());
    }
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    return super.close();
  }
}
