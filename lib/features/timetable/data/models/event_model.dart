/// SQLite-backed data model for timetable events.
class EventModel {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String source; // 'manual' | 'ocr_note' | 'whatsapp_screenshot'
  final bool isCompleted;
  final int? linkedNoteId;
  final DateTime createdAt;

  const EventModel({
    this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.source = 'manual',
    this.isCompleted = false,
    this.linkedNoteId,
    required this.createdAt,
  });

  bool get isOverdue =>
      !isCompleted && startTime.isBefore(DateTime.now());

  EventModel copyWith({
    int? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? source,
    bool? isCompleted,
    int? linkedNoteId,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      source: source ?? this.source,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedNoteId: linkedNoteId ?? this.linkedNoteId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'source': source,
      'is_completed': isCompleted ? 1 : 0,
      'linked_note_id': linkedNoteId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      source: map['source'] as String? ?? 'manual',
      isCompleted: (map['is_completed'] as int?) == 1,
      linkedNoteId: map['linked_note_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
