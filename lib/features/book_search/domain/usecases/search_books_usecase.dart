import '../entities/book.dart';
import '../repositories/book_search_repository.dart';

class SearchBooksUseCase {
  final BookSearchRepository _repo;
  const SearchBooksUseCase(this._repo);
  Future<List<Book>> call(String query) => _repo.searchBooks(query);
}