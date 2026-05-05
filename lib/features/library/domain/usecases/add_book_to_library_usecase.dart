import '../../../book_search/domain/entities/book.dart';
import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class AddBookToLibraryUseCase {
  final LibraryRepository _repo;
  const AddBookToLibraryUseCase(this._repo);

  Future<void> call(String userId, Book book, ReadingStatus status) =>
      _repo.addBookToLibrary(userId, book, status);
}