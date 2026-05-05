import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

class GetUserLibraryUseCase {
  final LibraryRepository _repo;
  const GetUserLibraryUseCase(this._repo);

  Future<List<UserBook>> call(String userId, {ReadingStatus? status, int offset = 0, int limit = 20}) =>
      _repo.getUserLibrary(userId, status: status, offset: offset, limit: limit);
}