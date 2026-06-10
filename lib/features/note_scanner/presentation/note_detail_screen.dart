import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../domain/entities/note_entity.dart';
import 'bloc/note_scanner_bloc.dart';

/// Detail screen for a scanned note.
///
/// Shows the scanned image, raw OCR text, AI summary, and navigation
/// to flashcards. Supports summary loading from laptop via BLoC.
class NoteDetailScreen extends StatelessWidget {
  final NoteEntity note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CampusAppBar(
        title: 'Note Detail',
        actions: [
          if (note.hasFlashcards)
            IconButton(
              icon: const Icon(Icons.style_rounded),
              tooltip: 'View Flashcards',
              onPressed: () {
                if (note.id != null) {
                  context.read<NoteScannerBloc>().add(
                        LoadFlashcardsRequested(noteId: note.id!),
                      );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanned image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: note.imagePath.isNotEmpty &&
                        File(note.imagePath).existsSync()
                    ? Image.file(
                        File(note.imagePath),
                        fit: BoxFit.cover,
                        semanticLabel: 'Scanned note image',
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata row
            Row(
              children: [
                Icon(
                  note.isSynced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  size: 16,
                  color: note.isSynced
                      ? AppColors.connectedGreen
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  note.isSynced ? 'Synced' : 'Not synced',
                  style: TextStyle(
                    color: note.isSynced
                        ? AppColors.connectedGreen
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  AppDateUtils.fullDateTime(note.createdAt),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI Summary section
            _SectionHeader(
              title: 'AI Summary',
              icon: Icons.auto_awesome_rounded,
              trailing: note.hasSummary
                  ? null
                  : TextButton(
                      onPressed: () {
                        if (note.id != null) {
                          context.read<NoteScannerBloc>().add(
                                LoadSummaryRequested(noteId: note.id!),
                              );
                        }
                      },
                      child: const Text('Generate'),
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                note.hasSummary
                    ? note.summaryText
                    : 'No summary available yet. Connect to your laptop to generate an AI summary.',
                style: TextStyle(
                  color: note.hasSummary
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detected info chips
            if (note.hasDeadline || note.hasAmount) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (note.hasDeadline)
                    _InfoChip(
                      icon: Icons.event_rounded,
                      label:
                          'Deadline: ${AppDateUtils.dayMonthYear(note.detectedDeadline!)}',
                      color: AppColors.accentAmber,
                    ),
                  if (note.hasAmount)
                    _InfoChip(
                      icon: Icons.currency_rupee_rounded,
                      label:
                          'Amount: ₹${note.detectedAmount!.toStringAsFixed(2)}',
                      color: AppColors.accentGreen,
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Raw OCR Text section
            const _SectionHeader(
              title: 'Raw Text (OCR)',
              icon: Icons.text_snippet_rounded,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                note.rawText.isNotEmpty
                    ? note.rawText
                    : 'No text detected in this image.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Flashcards button
            if (note.hasFlashcards)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (note.id != null) {
                      context.read<NoteScannerBloc>().add(
                            LoadFlashcardsRequested(noteId: note.id!),
                          );
                    }
                  },
                  icon: const Icon(Icons.style_rounded),
                  label: Text('Study ${note.flashcards.length} Flashcards'),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
