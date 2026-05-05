import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class UpdateReadingStatusUseCase {
  final LibraryRepository _repo;
  const UpdateReadingStatusUseCase(this._repo);

  Future<void> call(String userBookId, ReadingStatus status) =>
      _repo.updateReadingStatus(userBookId, status);
}