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

    return (data as List).map((e) => UserBookModel.fromJson(e as Map<String, dynamic>)).toList().cast<UserBook>();
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