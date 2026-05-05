import '../../../book_search/domain/entities/book.dart';
import '../../../book_search/data/models/google_book_model.dart';
import '../../domain/entities/user_book.dart';

class UserBookModel {
  static UserBook fromJson(Map<String, dynamic> json) {
    final bookJson = json['books'] as Map<String, dynamic>?;

    Book book;
    if (bookJson != null) {
      book = Book(
        id: bookJson['id'] as String,
        isbn10: bookJson['isbn_10'] as String?,
        isbn13: bookJson['isbn_13'] as String?,
        title: bookJson['title'] as String,
        authors: List<String>.from(bookJson['authors'] as List? ?? []),
        publisher: bookJson['publisher'] as String?,
        publishedDate: bookJson['published_date'] as String?,
        description: bookJson['description'] as String?,
        pageCount: bookJson['page_count'] as int?,
        categories: List<String>.from(bookJson['categories'] as List? ?? []),
        thumbnailUrl: bookJson['thumbnail_url'] as String?,
        language: bookJson['language'] as String? ?? 'en',
        averageRating: (bookJson['average_rating'] as num?)?.toDouble(),
      );
    } else {
      book = Book(id: json['book_id'] as String, title: 'Unknown', authors: [], categories: []);
    }

    return UserBook(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      book: book,
      status: ReadingStatus.fromValue(json['status'] as String),
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      finishDate: json['finish_date'] != null ? DateTime.tryParse(json['finish_date'] as String) : null,
      isPublic: json['is_public'] as bool? ?? true,
      shelfPosition: json['shelf_position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(String userId, Book book, ReadingStatus status) => {
    'user_id': userId,
    'book_id': book.id,
    'status': status.value,
    'current_page': 0,
    'total_pages': book.pageCount,
    'is_public': true,
  };
}