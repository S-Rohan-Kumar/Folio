import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── core/errors/failures.dart ──────────────────────────────────────────
w('lib/core/errors/failures.dart', """
sealed class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure extends Failure { const NetworkFailure() : super('No internet connection'); }
class ServerFailure extends Failure { const ServerFailure(String msg) : super(msg); }
class CacheFailure extends Failure { const CacheFailure() : super('Local data unavailable'); }
class BookNotFoundFailure extends Failure { const BookNotFoundFailure() : super('Book not found for this ISBN'); }
class GeminiFailure extends Failure { const GeminiFailure(String msg) : super(msg); }
class AuthFailure extends Failure { const AuthFailure(String msg) : super(msg); }
""".strip())

# ── core/errors/exceptions.dart ────────────────────────────────────────
w('lib/core/errors/exceptions.dart', """
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override String toString() => 'ServerException: \$message';
}
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
  @override String toString() => 'CacheException: \$message';
}
class BookNotFoundException implements Exception {
  @override String toString() => 'BookNotFoundException';
}
""".strip())

# ── core/network/dio_client.dart ───────────────────────────────────────
w('lib/core/network/dio_client.dart', """
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  );
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (o) => debugPrint(o.toString()),
    ));
  }
  return dio;
});
""".strip())

# ── book_search/domain/entities/book.dart ─────────────────────────────
w('lib/features/book_search/domain/entities/book.dart', """
class Book {
  final String id;
  final String? isbn10;
  final String? isbn13;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final int? pageCount;
  final List<String> categories;
  final String? thumbnailUrl;
  final String language;
  final double? averageRating;

  const Book({
    required this.id,
    this.isbn10,
    this.isbn13,
    required this.title,
    required this.authors,
    this.publisher,
    this.publishedDate,
    this.description,
    this.pageCount,
    required this.categories,
    this.thumbnailUrl,
    this.language = 'en',
    this.averageRating,
  });

  String get authorsDisplay => authors.join(', ');
  String get coverUrl => thumbnailUrl ?? '';

  Book copyWith({
    String? id, String? isbn10, String? isbn13, String? title,
    List<String>? authors, String? publisher, String? publishedDate,
    String? description, int? pageCount, List<String>? categories,
    String? thumbnailUrl, String? language, double? averageRating,
  }) => Book(
    id: id ?? this.id, isbn10: isbn10 ?? this.isbn10, isbn13: isbn13 ?? this.isbn13,
    title: title ?? this.title, authors: authors ?? this.authors,
    publisher: publisher ?? this.publisher, publishedDate: publishedDate ?? this.publishedDate,
    description: description ?? this.description, pageCount: pageCount ?? this.pageCount,
    categories: categories ?? this.categories, thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    language: language ?? this.language, averageRating: averageRating ?? this.averageRating,
  );

  @override bool operator ==(Object other) => other is Book && other.id == id;
  @override int get hashCode => id.hashCode;
}
""".strip())

# ── book_search/domain/repositories/book_search_repository.dart ────────
w('lib/features/book_search/domain/repositories/book_search_repository.dart', """
import '../entities/book.dart';

abstract class BookSearchRepository {
  Future<List<Book>> searchBooks(String query);
  Future<Book?> fetchBookByIsbn(String isbn);
}
""".strip())

# ── book_search/domain/usecases/search_books_usecase.dart ─────────────
w('lib/features/book_search/domain/usecases/search_books_usecase.dart', """
import '../entities/book.dart';
import '../repositories/book_search_repository.dart';

class SearchBooksUseCase {
  final BookSearchRepository _repo;
  const SearchBooksUseCase(this._repo);
  Future<List<Book>> call(String query) => _repo.searchBooks(query);
}
""".strip())

# ── book_search/domain/usecases/fetch_book_by_isbn_usecase.dart ────────
w('lib/features/book_search/domain/usecases/fetch_book_by_isbn_usecase.dart', """
import '../entities/book.dart';
import '../repositories/book_search_repository.dart';

class FetchBookByIsbnUseCase {
  final BookSearchRepository _repo;
  const FetchBookByIsbnUseCase(this._repo);
  Future<Book?> call(String isbn) => _repo.fetchBookByIsbn(isbn);
}
""".strip())

# ── book_search/data/models/google_book_model.dart ────────────────────
w('lib/features/book_search/data/models/google_book_model.dart', """
import 'package:collection/collection.dart';
import '../../domain/entities/book.dart';

class GoogleBookModel {
  static Book fromJson(Map<String, dynamic> json) {
    final info = (json['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final ids = (info['industryIdentifiers'] as List<dynamic>?) ?? [];
    final imgLinks = info['imageLinks'] as Map<String, dynamic>?;

    String? thumbnail = imgLinks?['thumbnail'] as String?;
    thumbnail = thumbnail?.replaceFirst('http://', 'https://');

    return Book(
      id: json['id'] as String,
      isbn10: ids.firstWhereOrNull((i) => i['type'] == 'ISBN_10')?['identifier'] as String?,
      isbn13: ids.firstWhereOrNull((i) => i['type'] == 'ISBN_13')?['identifier'] as String?,
      title: info['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(info['authors'] as List? ?? ['Unknown Author']),
      publisher: info['publisher'] as String?,
      publishedDate: info['publishedDate'] as String?,
      description: info['description'] as String?,
      pageCount: info['pageCount'] as int?,
      categories: List<String>.from(info['categories'] as List? ?? []),
      thumbnailUrl: thumbnail,
      language: info['language'] as String? ?? 'en',
      averageRating: (info['averageRating'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> toSupabaseJson(Book book) => {
    'id': book.id,
    'isbn_10': book.isbn10,
    'isbn_13': book.isbn13,
    'title': book.title,
    'authors': book.authors,
    'publisher': book.publisher,
    'published_date': book.publishedDate,
    'description': book.description,
    'page_count': book.pageCount,
    'categories': book.categories,
    'thumbnail_url': book.thumbnailUrl,
    'language': book.language,
    'average_rating': book.averageRating,
  };
}
""".strip())

# ── book_search/data/datasources/google_books_data_source.dart ─────────
w('lib/features/book_search/data/datasources/google_books_data_source.dart', """
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/book.dart';
import '../models/google_book_model.dart';

abstract class GoogleBooksDataSource {
  Future<List<Book>> searchBooks(String query);
  Future<Book?> fetchByIsbn(String isbn);
}

class GoogleBooksDataSourceImpl implements GoogleBooksDataSource {
  final Dio _dio;
  static const _baseUrl = 'https://www.googleapis.com/books/v1';
  static const _fields =
      'items(id,volumeInfo(title,authors,publisher,publishedDate,description,pageCount,categories,imageLinks,industryIdentifiers,averageRating,language))';

  const GoogleBooksDataSourceImpl(this._dio);

  @override
  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _dio.get('$_baseUrl/volumes', queryParameters: {
        'q': query,
        'maxResults': 20,
        'fields': _fields,
      });
      final items = response.data['items'] as List<dynamic>? ?? [];
      return items.map((e) => GoogleBookModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Google Books API error');
    }
  }

  @override
  Future<Book?> fetchByIsbn(String isbn) async {
    try {
      final response = await _dio.get('$_baseUrl/volumes', queryParameters: {
        'q': 'isbn:$isbn',
        'maxResults': 1,
      });
      final items = response.data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;
      return GoogleBookModel.fromJson(items.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Google Books API error');
    }
  }
}

final googleBooksDataSourceProvider = Provider<GoogleBooksDataSource>((ref) {
  return GoogleBooksDataSourceImpl(ref.watch(dioProvider));
});
""".strip())

# ── book_search/data/datasources/book_local_cache.dart ─────────────────
w('lib/features/book_search/data/datasources/book_local_cache.dart', """
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/book.dart';
import '../models/google_book_model.dart';

class BookLocalCache {
  static const _boxName = 'book_cache';
  static const _maxSize = 50;

  Box get _box => Hive.box(_boxName);

  void cacheBook(Book book) {
    final json = GoogleBookModel.toSupabaseJson(book);
    _box.put(book.id, jsonEncode(json));
    _trimCache();
  }

  Book? getCachedBook(String id) {
    final raw = _box.get(id) as String?;
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Book(
        id: map['id'] as String,
        isbn10: map['isbn_10'] as String?,
        isbn13: map['isbn_13'] as String?,
        title: map['title'] as String,
        authors: List<String>.from(map['authors'] as List? ?? []),
        publisher: map['publisher'] as String?,
        publishedDate: map['published_date'] as String?,
        description: map['description'] as String?,
        pageCount: map['page_count'] as int?,
        categories: List<String>.from(map['categories'] as List? ?? []),
        thumbnailUrl: map['thumbnail_url'] as String?,
        language: map['language'] as String? ?? 'en',
        averageRating: (map['average_rating'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> getRecentSearches() {
    return List<String>.from(_box.get('recent_searches', defaultValue: []) as List? ?? []);
  }

  void addRecentSearch(String query) {
    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 8) searches.removeLast();
    _box.put('recent_searches', searches);
  }

  void _trimCache() {
    final keys = _box.keys.where((k) => k != 'recent_searches').toList();
    if (keys.length > _maxSize) {
      for (var i = _maxSize; i < keys.length; i++) {
        _box.delete(keys[i]);
      }
    }
  }
}
""".strip())

# ── book_search/data/repositories/book_search_repository_impl.dart ─────
w('lib/features/book_search/data/repositories/book_search_repository_impl.dart', """
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
""".strip())

# ── book_search/presentation/providers/book_search_provider.dart ───────
w('lib/features/book_search/presentation/providers/book_search_provider.dart', """
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
""".strip())

print("✅ Phase 2 core + book_search data layer created.")
