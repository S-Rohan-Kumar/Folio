import '../../domain/entities/thread.dart';

class ThreadModel {
  static Thread fromJson(Map<String, dynamic> json) => Thread(
    id: json['id'] as String,
    bookId: json['book_id'] as String,
    clubId: json['club_id'] as String?,
    authorId: json['author_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    hasSpoilers: json['has_spoilers'] as bool? ?? false,
    replyCount: json['reply_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static ThreadReply replyFromJson(Map<String, dynamic> json) => ThreadReply(
    id: json['id'] as String,
    threadId: json['thread_id'] as String,
    authorId: json['author_id'] as String,
    body: json['body'] as String,
    hasSpoilers: json['has_spoilers'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}