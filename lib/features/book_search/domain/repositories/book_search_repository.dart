import '../entities/book.dart';

abstract class BookSearchRepository {
  Future<List<Book>> searchBooks(String query);
  Future<Book?> fetchBookByIsbn(String isbn);
}