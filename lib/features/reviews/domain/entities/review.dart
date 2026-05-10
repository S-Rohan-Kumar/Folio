class Review {
  final String id;
  final String userId;
  final String bookId;
  final double rating;
  final String? reviewText;
  final bool isSpoiler;
  final bool isPublic;
  final DateTime createdAt;
  
  // Joined fields
  final String? userDisplayName;

  const Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.rating,
    this.reviewText,
    required this.isSpoiler,
    required this.isPublic,
    required this.createdAt,
    this.userDisplayName,
  });
}