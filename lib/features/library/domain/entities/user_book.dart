import '../../../book_search/domain/entities/book.dart';

enum ReadingStatus {
  wantToRead,
  reading,
  finished,
  dnf,
  onHold;

  String get value {
    switch (this) {
      case ReadingStatus.wantToRead: return 'want_to_read';
      case ReadingStatus.reading: return 'reading';
      case ReadingStatus.finished: return 'finished';
      case ReadingStatus.dnf: return 'dnf';
      case ReadingStatus.onHold: return 'on_hold';
    }
  }

  String get label {
    switch (this) {
      case ReadingStatus.wantToRead: return 'Want to Read';
      case ReadingStatus.reading: return 'Reading Now';
      case ReadingStatus.finished: return 'Finished';
      case ReadingStatus.dnf: return 'Did Not Finish';
      case ReadingStatus.onHold: return 'On Hold';
    }
  }

  static ReadingStatus fromValue(String v) {
    switch (v) {
      case 'want_to_read': return ReadingStatus.wantToRead;
      case 'reading': return ReadingStatus.reading;
      case 'finished': return ReadingStatus.finished;
      case 'dnf': return ReadingStatus.dnf;
      case 'on_hold': return ReadingStatus.onHold;
      default: return ReadingStatus.wantToRead;
    }
  }
}

class UserBook {
  final String id;
  final String userId;
  final String bookId;
  final Book book;
  final ReadingStatus status;
  final int currentPage;
  final int? totalPages;
  final DateTime? startDate;
  final DateTime? finishDate;
  final bool isPublic;
  final int shelfPosition;
  final DateTime createdAt;

  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.book,
    required this.status,
    this.currentPage = 0,
    this.totalPages,
    this.startDate,
    this.finishDate,
    this.isPublic = true,
    this.shelfPosition = 0,
    required this.createdAt,
  });

  int get effectiveTotalPages => totalPages ?? book.pageCount ?? 0;
  double get progressPercent {
    final total = effectiveTotalPages;
    if (total == 0) return 0;
    return (currentPage / total).clamp(0.0, 1.0);
  }

  UserBook copyWith({
    String? id, String? userId, String? bookId, Book? book,
    ReadingStatus? status, int? currentPage, int? totalPages,
    DateTime? startDate, DateTime? finishDate, bool? isPublic,
    int? shelfPosition, DateTime? createdAt,
  }) => UserBook(
    id: id ?? this.id, userId: userId ?? this.userId, bookId: bookId ?? this.bookId,
    book: book ?? this.book, status: status ?? this.status,
    currentPage: currentPage ?? this.currentPage, totalPages: totalPages ?? this.totalPages,
    startDate: startDate ?? this.startDate, finishDate: finishDate ?? this.finishDate,
    isPublic: isPublic ?? this.isPublic, shelfPosition: shelfPosition ?? this.shelfPosition,
    createdAt: createdAt ?? this.createdAt,
  );
}