import 'dart:convert';

/// SQLite-backed data model for scanned notes.
///
/// Replaces the Isar @collection with a plain Dart class that serializes
/// to/from SQLite column maps. Same fields as the original spec.
class NoteModel {
  final int? id;
  final String rawText;
  final String summaryText;
  final List<Map<String, String>> flashcardJson;
  final String imagePath;
  final DateTime createdAt;
  final bool isSynced;
  final String? detectedDeadline;
  final String? detectedAmount;

  const NoteModel({
    this.id,
    this.rawText = '',
    this.summaryText = '',
    this.flashcardJson = const [],
    required this.imagePath,
    required this.createdAt,
    this.isSynced = false,
    this.detectedDeadline,
    this.detectedAmount,
  });

  NoteModel copyWith({
    int? id,
    String? rawText,
    String? summaryText,
    List<Map<String, String>>? flashcardJson,
    String? imagePath,
    DateTime? createdAt,
    bool? isSynced,
    String? detectedDeadline,
    String? detectedAmount,
  }) {
    return NoteModel(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      summaryText: summaryText ?? this.summaryText,
      flashcardJson: flashcardJson ?? this.flashcardJson,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      detectedDeadline: detectedDeadline ?? this.detectedDeadline,
      detectedAmount: detectedAmount ?? this.detectedAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'raw_text': rawText,
      'summary_text': summaryText,
      'flashcard_json': jsonEncode(flashcardJson),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'detected_deadline': detectedDeadline,
      'detected_amount': detectedAmount,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, String>> parseFlashcards(dynamic raw) {
      if (raw == null || raw == '') return [];
      try {
        final decoded = jsonDecode(raw as String) as List;
        return decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      } catch (_) {
        return [];
      }
    }

    return NoteModel(
      id: map['id'] as int?,
      rawText: map['raw_text'] as String? ?? '',
      summaryText: map['summary_text'] as String? ?? '',
      flashcardJson: parseFlashcards(map['flashcard_json']),
      imagePath: map['image_path'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
      detectedDeadline: map['detected_deadline'] as String?,
      detectedAmount: map['detected_amount'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      NoteModel.fromMap(json);
}
