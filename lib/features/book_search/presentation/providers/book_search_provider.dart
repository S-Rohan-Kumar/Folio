import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/book_local_cache.dart';
import '../../data/repositories/book_search_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/search_books_usecase.dart';
import '../../domain/usecases/fetch_book_by_isbn_usecase.dart';

final searchBooksUseCaseProvider = Provider<SearchBooksUseCase>((ref) {
  return SearchBooksUseCase(ref.watch(bookSearchRepositoryProvider));
});

final fetchBookByIsbnUseCaseProvider = Provider<FetchBookByIsbnUseCase>((ref) {
  return FetchBookByIsbnUseCase(ref.watch(bookSearchRepositoryProvider));
});

class BookSearchNotifier extends AsyncNotifier<List<Book>> {
  @override
  FutureOr<List<Book>> build() => [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(searchBooksUseCaseProvider).call(query.trim());
    });
  }

  void clear() => state = const AsyncValue.data([]);
}

final bookSearchNotifierProvider =
    AsyncNotifierProvider<BookSearchNotifier, List<Book>>(BookSearchNotifier.new);

final recentSearchesProvider = Provider<List<String>>((ref) {
  return ref.watch(bookLocalCacheProvider).getRecentSearches();
});

// Used to look up a single book by ID from cache
final bookByIdProvider = Provider.family<Book?, String>((ref, id) {
  return ref.watch(bookLocalCacheProvider).getCachedBook(id);
});