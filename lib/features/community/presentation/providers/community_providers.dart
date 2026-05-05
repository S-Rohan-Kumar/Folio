import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/battle_repository_impl.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/thread.dart';

// Clubs
final publicClubsProvider = FutureProvider<List<Club>>((ref) async {
  return ref.watch(clubRepositoryProvider).getPublicClubs();
});

final userClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getUserClubs(user.id);
});

// Threads
final recentThreadsProvider = FutureProvider<List<Thread>>((ref) async {
  return ref.watch(threadRepositoryProvider).getRecentThreads();
});

final clubThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, clubId) async {
  return ref.watch(threadRepositoryProvider).getClubThreads(clubId);
});

final threadRepliesProvider = FutureProvider.family<List<ThreadReply>, String>((ref, threadId) async {
  return ref.watch(threadRepositoryProvider).getThreadReplies(threadId);
});

// Battles
final userBattlesProvider = FutureProvider<List<Battle>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(battleRepositoryProvider).getUserBattles(user.id);
});