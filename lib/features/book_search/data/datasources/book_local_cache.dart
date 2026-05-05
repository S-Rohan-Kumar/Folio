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

  void clearRecentSearches() {
    _box.delete('recent_searches');
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