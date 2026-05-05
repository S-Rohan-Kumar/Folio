import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── library/domain/entities/user_book.dart ─────────────────────────────
w('lib/features/library/domain/entities/user_book.dart', """
import '../../book_search/domain/entities/book.dart';

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
""".strip())

# ── library/domain/repositories/library_repository.dart ───────────────
w('lib/features/library/domain/repositories/library_repository.dart', """
import '../../book_search/domain/entities/book.dart';
import '../entities/user_book.dart';

abstract class LibraryRepository {
  Future<List<UserBook>> getUserLibrary(String userId, {ReadingStatus? status, int offset = 0, int limit = 20});
  Future<UserBook?> getUserBook(String userId, String bookId);
  Future<void> addBookToLibrary(String userId, Book book, ReadingStatus status);
  Future<void> updateReadingStatus(String userBookId, ReadingStatus status);
  Future<void> updateCurrentPage(String userBookId, int page);
}
""".strip())

# ── library/domain/usecases ────────────────────────────────────────────
w('lib/features/library/domain/usecases/get_user_library_usecase.dart', """
import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class GetUserLibraryUseCase {
  final LibraryRepository _repo;
  const GetUserLibraryUseCase(this._repo);

  Future<List<UserBook>> call(String userId, {ReadingStatus? status, int offset = 0, int limit = 20}) =>
      _repo.getUserLibrary(userId, status: status, offset: offset, limit: limit);
}
""".strip())

w('lib/features/library/domain/usecases/add_book_to_library_usecase.dart', """
import '../../book_search/domain/entities/book.dart';
import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class AddBookToLibraryUseCase {
  final LibraryRepository _repo;
  const AddBookToLibraryUseCase(this._repo);

  Future<void> call(String userId, Book book, ReadingStatus status) =>
      _repo.addBookToLibrary(userId, book, status);
}
""".strip())

w('lib/features/library/domain/usecases/update_reading_status_usecase.dart', """
import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class UpdateReadingStatusUseCase {
  final LibraryRepository _repo;
  const UpdateReadingStatusUseCase(this._repo);

  Future<void> call(String userBookId, ReadingStatus status) =>
      _repo.updateReadingStatus(userBookId, status);
}
""".strip())

# ── library/data/models/user_book_model.dart ───────────────────────────
w('lib/features/library/data/models/user_book_model.dart', """
import '../../book_search/domain/entities/book.dart';
import '../../book_search/data/models/google_book_model.dart';
import '../domain/entities/user_book.dart';

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
""".strip())

# ── library/data/datasources/library_remote_data_source.dart ──────────
w('lib/features/library/data/datasources/library_remote_data_source.dart', """
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../book_search/data/models/google_book_model.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/user_book.dart';
import '../models/user_book_model.dart';

abstract class LibraryRemoteDataSource {
  Future<List<UserBook>> getUserLibrary(String userId, {ReadingStatus? status, int offset = 0, int limit = 20});
  Future<UserBook?> getUserBook(String userId, String bookId);
  Future<void> upsertBook(Book book);
  Future<void> addBookToLibrary(String userId, Book book, ReadingStatus status);
  Future<void> updateReadingStatus(String userBookId, ReadingStatus status);
  Future<void> updateCurrentPage(String userBookId, int page);
}

class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final SupabaseClient _client;
  const LibraryRemoteDataSourceImpl(this._client);

  @override
  Future<List<UserBook>> getUserLibrary(String userId, {ReadingStatus? status, int offset = 0, int limit = 20}) async {
    var query = _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final data = await query
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) => UserBookModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<UserBook?> getUserBook(String userId, String bookId) async {
    final data = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
    if (data == null) return null;
    return UserBookModel.fromJson(data);
  }

  @override
  Future<void> upsertBook(Book book) async {
    await _client.from('books').upsert(GoogleBookModel.toSupabaseJson(book), onConflict: 'id');
  }

  @override
  Future<void> addBookToLibrary(String userId, Book book, ReadingStatus status) async {
    await upsertBook(book);
    await _client.from('user_books').upsert(
      UserBookModel.toInsertJson(userId, book, status),
      onConflict: 'user_id,book_id',
    );
  }

  @override
  Future<void> updateReadingStatus(String userBookId, ReadingStatus status) async {
    await _client.from('user_books').update({
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
      if (status == ReadingStatus.finished) 'finish_date': DateTime.now().toIso8601String().split('T').first,
      if (status == ReadingStatus.reading) 'start_date': DateTime.now().toIso8601String().split('T').first,
    }).eq('id', userBookId);
  }

  @override
  Future<void> updateCurrentPage(String userBookId, int page) async {
    await _client.from('user_books').update({'current_page': page, 'updated_at': DateTime.now().toIso8601String()}).eq('id', userBookId);
  }
}

final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>((ref) {
  return LibraryRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});
""".strip())

# ── library/data/repositories/library_repository_impl.dart ────────────
w('lib/features/library/data/repositories/library_repository_impl.dart', """
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/user_book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource _remote;
  const LibraryRepositoryImpl(this._remote);

  @override
  Future<List<UserBook>> getUserLibrary(String userId, {ReadingStatus? status, int offset = 0, int limit = 20}) =>
      _remote.getUserLibrary(userId, status: status, offset: offset, limit: limit);

  @override
  Future<UserBook?> getUserBook(String userId, String bookId) =>
      _remote.getUserBook(userId, bookId);

  @override
  Future<void> addBookToLibrary(String userId, Book book, ReadingStatus status) =>
      _remote.addBookToLibrary(userId, book, status);

  @override
  Future<void> updateReadingStatus(String userBookId, ReadingStatus status) =>
      _remote.updateReadingStatus(userBookId, status);

  @override
  Future<void> updateCurrentPage(String userBookId, int page) =>
      _remote.updateCurrentPage(userBookId, page);
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(ref.watch(libraryRemoteDataSourceProvider));
});
""".strip())

print("✅ Phase 2 library domain + data layer created.")
