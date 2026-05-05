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