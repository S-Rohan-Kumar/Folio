import '../../../book_search/domain/entities/book.dart';
import '../entities/user_book.dart';

abstract class LibraryRepository {
  Future<List<UserBook>> getUserLibrary(String userId, {ReadingStatus? status, int offset = 0, int limit = 20});
  Future<UserBook?> getUserBook(String userId, String bookId);
  Future<void> addBookToLibrary(String userId, Book book, ReadingStatus status);
  Future<void> updateReadingStatus(String userBookId, ReadingStatus status);
  Future<void> updateCurrentPage(String userBookId, int page);
}