import '../../domain/entities/club.dart';

class ClubModel {
  static Club fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    coverUrl: json['cover_url'] as String?,
    ownerId: json['owner_id'] as String,
    isPublic: json['is_public'] as bool? ?? true,
    inviteCode: json['invite_code'] as String?,
    currentBookId: json['current_book_id'] as String?,
    memberCount: json['member_count'] as int? ?? 1,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}