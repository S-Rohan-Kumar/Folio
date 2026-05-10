import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/thread.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../../../reviews/data/repositories/review_repository_impl.dart';

final clubRepositoryProvider = Provider((ref) => ClubRepositoryImpl(ref.watch(supabaseClientProvider)));
final threadRepositoryProvider = Provider((ref) => ThreadRepositoryImpl(ref.watch(supabaseClientProvider)));

// Clubs
final myClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getMyClubs(user.id);
});

final discoverClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getDiscoverClubs(user.id);
});

final clubDetailsProvider = FutureProvider.family<Club, String>((ref, clubId) async {
  return ref.watch(clubRepositoryProvider).getClubDetails(clubId);
});

final clubMembersProvider = FutureProvider.family<List<ClubMember>, String>((ref, clubId) async {
  return ref.watch(clubRepositoryProvider).getClubMembers(clubId);
});

// Threads
final clubThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, clubId) async {
  return ref.watch(threadRepositoryProvider).getThreads(clubId: clubId);
});

final bookPublicThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, bookId) async {
  return ref.watch(threadRepositoryProvider).getThreads(bookId: bookId);
});

final threadDetailsProvider = FutureProvider.family<Thread, String>((ref, threadId) async {
  return ref.watch(threadRepositoryProvider).getThreadDetails(threadId);
});

// CRITICAL: Realtime Stream Provider
final threadRepliesProvider = StreamProvider.family<List<ThreadReply>, String>((ref, threadId) {
  return ref.watch(threadRepositoryProvider).watchReplies(threadId);
});

// Actions (Use Cases via Riverpod)
class CreateClubParams {
  final String name;
  final String? description;
  final bool isPublic;
  final String? inviteCode;
  final String? currentBookId;

  CreateClubParams({required this.name, this.description, required this.isPublic, this.inviteCode, this.currentBookId});
}

final createClubUseCaseProvider = Provider((ref) {
  return (CreateClubParams params) async {
    final user = ref.read(currentUserProvider)!;
    final club = Club(
      id: '', name: params.name, description: params.description,
      ownerId: user.id, isPublic: params.isPublic, inviteCode: params.inviteCode,
      currentBookId: params.currentBookId, memberCount: 1, createdAt: DateTime.now(),
    );
    return ref.read(clubRepositoryProvider).createClub(club);
  };
});

final joinClubUseCaseProvider = Provider((ref) {
  return (String clubId, {String? inviteCode}) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(clubRepositoryProvider).joinClub(user.id, clubId, inviteCode: inviteCode);
  };
});

final leaveClubUseCaseProvider = Provider((ref) {
  return (String clubId) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(clubRepositoryProvider).leaveClub(user.id, clubId);
  };
});

class CreateThreadParams {
  final String? bookId;
  final String? clubId;
  final String title;
  final String body;
  final bool hasSpoilers;

  CreateThreadParams({this.bookId, this.clubId, required this.title, required this.body, required this.hasSpoilers});
}

final createThreadUseCaseProvider = Provider((ref) {
  return (CreateThreadParams params) async {
    final user = ref.read(currentUserProvider)!;
    final thread = Thread(
      id: '', authorId: user.id, bookId: params.bookId, clubId: params.clubId,
      title: params.title, body: params.body, hasSpoilers: params.hasSpoilers,
      replyCount: 0, createdAt: DateTime.now(),
    );
    await ref.read(threadRepositoryProvider).createThread(thread);
  };
});

class CreateReplyParams {
  final String threadId;
  final String body;
  final String? parentReplyId;
  final bool hasSpoilers;

  CreateReplyParams({required this.threadId, required this.body, this.parentReplyId, required this.hasSpoilers});
}

final createReplyUseCaseProvider = Provider((ref) {
  return (CreateReplyParams params) async {
    final user = ref.read(currentUserProvider)!;
    final reply = ThreadReply(
      id: '', threadId: params.threadId, authorId: user.id, body: params.body,
      hasSpoilers: params.hasSpoilers, parentReplyId: params.parentReplyId, createdAt: DateTime.now(),
    );
    await ref.read(threadRepositoryProvider).createReply(reply);
  };
});

final incrementReplyCountUseCaseProvider = Provider((ref) {
  return (String threadId) async {
    await ref.read(threadRepositoryProvider).incrementReplyCount(threadId);
  };
});

// Export XP log
final logXpUseCaseProvider = Provider((ref) {
  return (String action, int xp) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(reviewRepositoryProvider).logXp(user.id, action, xp);
  };
});