import '../../../book_search/domain/entities/book.dart';

class Club {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String ownerId;
  final bool isPublic;
  final String? inviteCode;
  final String? currentBookId;
  final int memberCount;
  final DateTime createdAt;

  // Joined fields
  final Book? currentBook;

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    required this.isPublic,
    this.inviteCode,
    this.currentBookId,
    required this.memberCount,
    required this.createdAt,
    this.currentBook,
  });
}

class ClubMember {
  final String clubId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  
  // Joined fields
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const ClubMember({
    required this.clubId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });
}