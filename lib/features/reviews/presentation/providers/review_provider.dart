import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/review_repository_impl.dart';

final bookReviewsProvider = FutureProvider.family<List<Review>, String>((ref, bookId) async {
  return ref.watch(reviewRepositoryProvider).getBookReviews(bookId);
});

final userReviewProvider = FutureProvider.family<Review?, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(reviewRepositoryProvider).getUserReview(user.id, bookId);
});

final bookNotesProvider = FutureProvider.family<List<Note>, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reviewRepositoryProvider).getBookNotes(user.id, bookId);
});