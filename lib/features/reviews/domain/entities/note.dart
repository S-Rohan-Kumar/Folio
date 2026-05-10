enum NoteType { note, quote, highlight }

class Note {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final int? pageNumber;
  final NoteType type;
  final bool isPublic;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    this.pageNumber,
    required this.type,
    required this.isPublic,
    required this.createdAt,
  });
}