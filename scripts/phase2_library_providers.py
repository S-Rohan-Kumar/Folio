import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── library/presentation/providers/library_provider.dart ──────────────
w('lib/features/library/presentation/providers/library_provider.dart', """
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/user_book.dart';
import '../../domain/usecases/add_book_to_library_usecase.dart';
import '../../domain/usecases/get_user_library_usecase.dart';
import '../../domain/usecases/update_reading_status_usecase.dart';

final addBookToLibraryUseCaseProvider = Provider<AddBookToLibraryUseCase>((ref) {
  return AddBookToLibraryUseCase(ref.watch(libraryRepositoryProvider));
});

final getUserLibraryUseCaseProvider = Provider<GetUserLibraryUseCase>((ref) {
  return GetUserLibraryUseCase(ref.watch(libraryRepositoryProvider));
});

final updateReadingStatusUseCaseProvider = Provider<UpdateReadingStatusUseCase>((ref) {
  return UpdateReadingStatusUseCase(ref.watch(libraryRepositoryProvider));
});

// Per-status library notifier
class LibraryNotifier extends AsyncNotifier<List<UserBook>> {
  final ReadingStatus? status;
  LibraryNotifier(this.status);

  @override
  FutureOr<List<UserBook>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(getUserLibraryUseCaseProvider).call(user.id, status: status);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => future);
  }

  Future<void> addBook(Book book, ReadingStatus s) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(addBookToLibraryUseCaseProvider).call(user.id, book, s);
    // Invalidate all library tabs
    ref.invalidate(libraryReadingProvider);
    ref.invalidate(libraryWantToReadProvider);
    ref.invalidate(libraryFinishedProvider);
    ref.invalidate(libraryDnfProvider);
    ref.invalidate(libraryOnHoldProvider);
  }

  Future<void> updateStatus(String userBookId, ReadingStatus s) async {
    await ref.read(updateReadingStatusUseCaseProvider).call(userBookId, s);
    ref.invalidate(libraryReadingProvider);
    ref.invalidate(libraryWantToReadProvider);
    ref.invalidate(libraryFinishedProvider);
    ref.invalidate(libraryDnfProvider);
    ref.invalidate(libraryOnHoldProvider);
  }
}

final libraryReadingProvider = AsyncNotifierProvider<LibraryNotifier, List<UserBook>>(
  () => LibraryNotifier(ReadingStatus.reading));

final libraryWantToReadProvider = AsyncNotifierProvider<LibraryNotifier, List<UserBook>>(
  () => LibraryNotifier(ReadingStatus.wantToRead));

final libraryFinishedProvider = AsyncNotifierProvider<LibraryNotifier, List<UserBook>>(
  () => LibraryNotifier(ReadingStatus.finished));

final libraryDnfProvider = AsyncNotifierProvider<LibraryNotifier, List<UserBook>>(
  () => LibraryNotifier(ReadingStatus.dnf));

final libraryOnHoldProvider = AsyncNotifierProvider<LibraryNotifier, List<UserBook>>(
  () => LibraryNotifier(ReadingStatus.onHold));

// Check if a specific book is in the user's library
final userBookByBookIdProvider = FutureProvider.family<UserBook?, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(libraryRepositoryProvider).getUserBook(user.id, bookId);
});
""".strip())

print("✅ Library providers created.")
