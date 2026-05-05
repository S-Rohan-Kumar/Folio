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