import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../domain/entities/note_entity.dart';
import 'bloc/note_scanner_bloc.dart';

/// Main screen for the Note Scanner feature.
///
/// Shows a list of scanned notes with a FAB to capture new notes.
/// Handles camera permission, low confidence warnings, and empty state.
class NoteScannerScreen extends StatefulWidget {
  const NoteScannerScreen({super.key});

  @override
  State<NoteScannerScreen> createState() => _NoteScannerScreenState();
}

class _NoteScannerScreenState extends State<NoteScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<NoteScannerBloc>().add(const LoadNotesRequested());
  }

  Future<void> _scanNote() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (image == null) return;

      if (mounted) {
        context
            .read<NoteScannerBloc>()
            .add(ScanNoteRequested(imagePath: image.path));
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Could not access camera: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Notes',
        showConnectionStatus: true,
      ),
      body: BlocConsumer<NoteScannerBloc, NoteScannerState>(
        listener: (context, state) {
          switch (state) {
            case NoteScanSuccess(note: final note):
              ErrorSnackbar.showSuccess(context, 'Note scanned successfully!');
              context.read<NoteScannerBloc>().add(const LoadNotesRequested());
            case LowConfidenceWarning():
              ErrorSnackbar.showWarning(
                context,
                'Low confidence scan. Text may be inaccurate. Try a clearer photo.',
              );
              context.read<NoteScannerBloc>().add(const LoadNotesRequested());
            case NoteScannerError(message: final msg):
              ErrorSnackbar.showError(context, msg);
            case NoteDeletedSuccess():
              ErrorSnackbar.showSuccess(context, 'Note deleted');
            default:
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            NoteScannerLoading(message: final msg) => LoadingOverlay(
                isLoading: true,
                message: msg,
                child: _buildNotesList(const []),
              ),
            NotesLoaded(notes: final notes) => _buildNotesList(notes),
            _ => _buildNotesList(const []),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNote,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Scan Note'),
        heroTag: 'scan_note_fab',
      ),
    );
  }

  Widget _buildNotesList(List<NoteEntity> notes) {
    if (notes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.document_scanner_rounded,
        title: 'No Notes Yet',
        subtitle:
            'Scan your handwritten notes to get AI summaries and flashcards.',
        ctaLabel: 'Scan First Note',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NoteScannerBloc>().add(const LoadNotesRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: notes.length,
        itemBuilder: (context, index) => _NoteCard(
          note: notes[index],
          onTap: () {
            // Navigation handled by go_router in the app
          },
          onDelete: () {
            if (notes[index].id != null) {
              context
                  .read<NoteScannerBloc>()
                  .add(DeleteNoteRequested(noteId: notes[index].id!));
            }
          },
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Note: ${note.rawText.substring(0, note.rawText.length.clamp(0, 50))}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.rawText.length > 60
                                ? '${note.rawText.substring(0, 60)}...'
                                : note.rawText,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppDateUtils.timeAgo(note.createdAt),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete note',
                    ),
                  ],
                ),
                if (note.hasSummary || note.hasFlashcards || note.hasDeadline) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (note.hasSummary)
                        _StatusChip(
                          icon: Icons.summarize_rounded,
                          label: 'Summary',
                          color: AppColors.accentCyan,
                        ),
                      if (note.hasFlashcards)
                        _StatusChip(
                          icon: Icons.style_rounded,
                          label: '${note.flashcards.length} Cards',
                          color: AppColors.accentPink,
                        ),
                      if (note.hasDeadline)
                        _StatusChip(
                          icon: Icons.event_rounded,
                          label: 'Deadline',
                          color: AppColors.accentAmber,
                        ),
                      if (!note.isSynced)
                        _StatusChip(
                          icon: Icons.cloud_off_rounded,
                          label: 'Unsynced',
                          color: AppColors.textTertiary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
