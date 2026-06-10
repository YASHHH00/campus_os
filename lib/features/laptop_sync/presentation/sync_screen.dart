import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../../../shared/widgets/error_snackbar.dart';
import 'bloc/sync_bloc.dart';

/// QR pairing and sync management screen for laptop continuity.
///
/// Shows:
/// - QR code + PIN for pairing when disconnected
/// - Connection status when paired
/// - Manual sync trigger button
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Laptop Sync',
        showConnectionStatus: true,
      ),
      body: BlocConsumer<SyncBloc, SyncState>(
        listener: (context, state) {
          switch (state) {
            case SyncCompleted(notesSynced: final count):
              ErrorSnackbar.showSuccess(
                context,
                count > 0
                    ? '$count note(s) synced to laptop!'
                    : 'All notes already synced.',
              );
            case SyncError(message: final msg):
              ErrorSnackbar.showError(context, msg);
            case SyncConnected():
              ErrorSnackbar.showSuccess(context, 'Connected to laptop!');
            case SyncDisconnected():
              ErrorSnackbar.showWarning(context, 'Laptop disconnected.');
            default:
              break;
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusCard(context, state),
                const SizedBox(height: 24),
                _buildActionArea(context, state),
                const SizedBox(height: 32),
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SyncState state) {
    final (icon, label, color) = switch (state) {
      SyncConnected() => (
          Icons.link_rounded,
          'Connected to Laptop',
          AppColors.connectedGreen,
        ),
      SyncPairing() => (
          Icons.qr_code_2_rounded,
          'Waiting for Laptop...',
          AppColors.accentAmber,
        ),
      SyncInProgress() => (
          Icons.sync_rounded,
          'Syncing...',
          AppColors.accentCyan,
        ),
      _ => (
          Icons.link_off_rounded,
          'Not Connected',
          AppColors.textTertiary,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, SyncState state) {
    return switch (state) {
      SyncPairing(pin: final pin, sessionId: final sessionId) =>
        _buildPairingUI(pin, sessionId),
      SyncConnected() => _buildConnectedActions(context),
      SyncInProgress(message: final msg) => Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primaryPurple),
            const SizedBox(height: 16),
            Text(
              msg,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      _ => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<SyncBloc>().add(const InitPairingRequested());
            },
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('Start Pairing'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
    };
  }

  Widget _buildPairingUI(String pin, String sessionId) {
    return Column(
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: 'campusos://$sessionId/$pin',
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            semanticsLabel: 'Pairing QR code',
          ),
        ),
        const SizedBox(height: 20),

        // PIN display
        const Text(
          'Or enter this PIN on your laptop:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
          ),
          child: Text(
            pin.split('').join(' '),
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<SyncBloc>().add(const SyncNotesRequested());
            },
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sync Notes Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SyncBloc>().add(const DisconnectRequested());
            },
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to pair',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _InstructionStep(
            number: '1',
            text: 'Make sure phone and laptop are on the same WiFi network',
          ),
          _InstructionStep(
            number: '2',
            text: 'Open Campus OS Desktop on your laptop',
          ),
          _InstructionStep(
            number: '3',
            text: 'Scan the QR code or enter the PIN shown above',
          ),
          _InstructionStep(
            number: '4',
            text: 'Once connected, your notes will sync automatically',
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withValues(alpha: 0.15),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
