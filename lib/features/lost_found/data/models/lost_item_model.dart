/// SQLite + Supabase data model for Lost & Found items.
class LostItemModel {
  final int? id;
  final String supabaseId;
  final String title;
  final String description;
  final String imagePath; // local cache path
  final String postedByUserId;
  final String? claimedByUserId;
  final String location;
  final String status; // 'active' | 'claimed' | 'resolved'
  final DateTime createdAt;
  final bool isOwnPost;

  const LostItemModel({
    this.id,
    this.supabaseId = '',
    required this.title,
    this.description = '',
    this.imagePath = '',
    this.postedByUserId = '',
    this.claimedByUserId,
    required this.location,
    this.status = 'active',
    required this.createdAt,
    this.isOwnPost = false,
  });

  bool get isActive => status == 'active';
  bool get isClaimed => status == 'claimed';

  LostItemModel copyWith({
    int? id,
    String? supabaseId,
    String? title,
    String? description,
    String? imagePath,
    String? postedByUserId,
    String? claimedByUserId,
    String? location,
    String? status,
    DateTime? createdAt,
    bool? isOwnPost,
  }) {
    return LostItemModel(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isOwnPost: isOwnPost ?? this.isOwnPost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supabase_id': supabaseId,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'posted_by_user_id': postedByUserId,
      'claimed_by_user_id': claimedByUserId,
      'location': location,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'is_own_post': isOwnPost ? 1 : 0,
    };
  }

  factory LostItemModel.fromMap(Map<String, dynamic> map) {
    return LostItemModel(
      id: map['id'] as int?,
      supabaseId: map['supabase_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imagePath: map['image_path'] as String? ?? '',
      postedByUserId: map['posted_by_user_id'] as String? ?? '',
      claimedByUserId: map['claimed_by_user_id'] as String?,
      location: map['location'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      isOwnPost: (map['is_own_post'] as int?) == 1,
    );
  }

  /// Convert from Supabase row format.
  factory LostItemModel.fromSupabase(
      Map<String, dynamic> map, String currentUserId) {
    return LostItemModel(
      supabaseId: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imagePath: map['image_url'] as String? ?? '',
      postedByUserId: map['posted_by'] as String? ?? '',
      claimedByUserId: map['claimed_by'] as String?,
      location: map['location'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      isOwnPost: (map['posted_by'] as String?) == currentUserId,
    );
  }

  /// Convert to Supabase insert format.
  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'image_url': imagePath,
      'posted_by': postedByUserId,
      'location': location,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
