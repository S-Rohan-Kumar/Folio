import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../data/repositories/progress_repository_impl.dart';

final readingSessionsProvider = FutureProvider.family<List<ReadingSession>, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(progressRepositoryProvider).getReadingSessions(user.id, bookId);
});

final readingSpeedProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  return ref.watch(progressRepositoryProvider).getReadingSpeed(user.id);
});