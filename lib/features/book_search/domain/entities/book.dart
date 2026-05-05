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