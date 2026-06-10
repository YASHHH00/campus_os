import 'package:equatable/equatable.dart';

/// Pure domain entity for a scanned note.
///
/// No framework imports — this is part of the domain layer and should
/// contain only business-relevant fields. Maps 1:1 from [NoteModel]
/// in the data layer.
class NoteEntity extends Equatable {
  final int? id;
  final String rawText;
  final String summaryText;
  final List<Flashcard> flashcards;
  final String imagePath;
  final DateTime createdAt;
  final bool isSynced;
  final DateTime? detectedDeadline;
  final double? detectedAmount;

  const NoteEntity({
    this.id,
    required this.rawText,
    this.summaryText = '',
    this.flashcards = const [],
    required this.imagePath,
    required this.createdAt,
    this.isSynced = false,
    this.detectedDeadline,
    this.detectedAmount,
  });

  bool get hasDeadline => detectedDeadline != null;
  bool get hasAmount => detectedAmount != null;
  bool get hasSummary => summaryText.isNotEmpty;
  bool get hasFlashcards => flashcards.isNotEmpty;

  NoteEntity copyWith({
    int? id,
    String? rawText,
    String? summaryText,
    List<Flashcard>? flashcards,
    String? imagePath,
    DateTime? createdAt,
    bool? isSynced,
    DateTime? detectedDeadline,
    double? detectedAmount,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      summaryText: summaryText ?? this.summaryText,
      flashcards: flashcards ?? this.flashcards,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      detectedDeadline: detectedDeadline ?? this.detectedDeadline,
      detectedAmount: detectedAmount ?? this.detectedAmount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        rawText,
        summaryText,
        flashcards,
        imagePath,
        createdAt,
        isSynced,
        detectedDeadline,
        detectedAmount,
      ];
}

/// A single flashcard with a question and answer.
class Flashcard extends Equatable {
  final String question;
  final String answer;

  const Flashcard({required this.question, required this.answer});

  factory Flashcard.fromMap(Map<String, String> map) {
    return Flashcard(
      question: map['q'] ?? map['question'] ?? '',
      answer: map['a'] ?? map['answer'] ?? '',
    );
  }

  Map<String, String> toMap() => {'q': question, 'a': answer};

  @override
  List<Object?> get props => [question, answer];
}
