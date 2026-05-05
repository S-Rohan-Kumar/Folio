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

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    this.isPublic = true,
    this.inviteCode,
    this.currentBookId,
    this.memberCount = 1,
    required this.createdAt,
  });
}

class ClubMember {
  final String clubId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  const ClubMember({
    required this.clubId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });
}