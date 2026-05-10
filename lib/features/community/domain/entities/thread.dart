class Thread {
  final String id;
  final String? bookId;
  final String? clubId;
  final String authorId;
  final String title;
  final String body;
  final bool hasSpoilers;
  final int replyCount;
  final DateTime createdAt;

  // Joined
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? bookTitle;

  const Thread({
    required this.id,
    this.bookId,
    this.clubId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.hasSpoilers,
    required this.replyCount,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.bookTitle,
  });
}

class ThreadReply {
  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final bool hasSpoilers;
  final String? parentReplyId;
  final DateTime createdAt;

  // Joined
  final String? authorUsername;
  final String? authorAvatarUrl;

  const ThreadReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.hasSpoilers,
    this.parentReplyId,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory ThreadReply.fromJson(Map<String, dynamic> json) {
    return ThreadReply(
      id: json['id'],
      threadId: json['thread_id'],
      authorId: json['author_id'],
      body: json['body'],
      hasSpoilers: json['has_spoilers'] ?? false,
      parentReplyId: json['parent_reply_id'],
      createdAt: DateTime.parse(json['created_at']),
      authorUsername: json['users']?['username'] ?? json['users']?['full_name'], // Join might use full_name depending on schema
      authorAvatarUrl: json['users']?['avatar_url'],
    );
  }
}