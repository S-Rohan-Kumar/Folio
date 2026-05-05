import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/google_books_data_source.dart';
import '../datasources/book_local_cache.dart';
import '../models/google_book_model.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  final GoogleBooksDataSource _remote;
  final BookLocalCache _cache;

  const BookSearchRepositoryImpl(this._remote, this._cache);

  @override
  Future<List<Book>> searchBooks(String query) async {
    final books = await _remote.searchBooks(query);
    for (final book in books) {
      _cache.cacheBook(book);
    }
    _cache.addRecentSearch(query);
    return books;
  }

  @override
  Future<Book?> fetchBookByIsbn(String isbn) async {
    final book = await _remote.fetchByIsbn(isbn);
    if (book != null) _cache.cacheBook(book);
    return book;
  }
}

final bookLocalCacheProvider = Provider<BookLocalCache>((ref) => BookLocalCache());

final bookSearchRepositoryProvider = Provider<BookSearchRepository>((ref) {
  return BookSearchRepositoryImpl(
    ref.watch(googleBooksDataSourceProvider),
    ref.watch(bookLocalCacheProvider),
  );
});