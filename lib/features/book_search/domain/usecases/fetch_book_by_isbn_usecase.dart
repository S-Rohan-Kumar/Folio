import '../entities/book.dart';
import '../repositories/book_search_repository.dart';

class FetchBookByIsbnUseCase {
  final BookSearchRepository _repo;
  const FetchBookByIsbnUseCase(this._repo);
  Future<Book?> call(String isbn) => _repo.fetchBookByIsbn(isbn);
}