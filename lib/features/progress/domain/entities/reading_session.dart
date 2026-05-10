class ReadingSession {
  final String id;
  final String userId;
  final String bookId;
  final int startPage;
  final int endPage;
  final int pagesRead;
  final int durationSecs;
  final DateTime sessionDate;
  final String? notes;

  const ReadingSession({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.startPage,
    required this.endPage,
    required this.pagesRead,
    required this.durationSecs,
    required this.sessionDate,
    this.notes,
  });
}