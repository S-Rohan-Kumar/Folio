class Thread {
  final String id;
  final String bookId;
  final String? clubId;
  final String authorId;
  final String title;
  final String body;
  final bool hasSpoilers;
  final int replyCount;
  final DateTime createdAt;

  const Thread({
    required this.id,
    required this.bookId,
    this.clubId,
    required this.authorId,
    required this.title,
    required this.body,
    this.hasSpoilers = false,
    this.replyCount = 0,
    required this.createdAt,
  });
}

class ThreadReply {
  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final bool hasSpoilers;
  final DateTime createdAt;

  const ThreadReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    this.hasSpoilers = false,
    required this.createdAt,
  });
}