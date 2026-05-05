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