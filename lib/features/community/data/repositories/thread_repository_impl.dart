import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/thread_remote_data_source.dart';
import '../../domain/entities/thread.dart';

class ThreadRepository {
  final ThreadRemoteDataSource _remote;
  const ThreadRepository(this._remote);

  Future<List<Thread>> getRecentThreads() => _remote.getRecentThreads();
  Future<List<Thread>> getClubThreads(String clubId) => _remote.getClubThreads(clubId);
  Future<List<ThreadReply>> getThreadReplies(String threadId) => _remote.getThreadReplies(threadId);
  Future<Thread> createThread(String bookId, String? clubId, String authorId, String title, String body, bool hasSpoilers) =>
      _remote.createThread(bookId, clubId, authorId, title, body, hasSpoilers);
  Future<ThreadReply> createReply(String threadId, String authorId, String body, bool hasSpoilers) =>
      _remote.createReply(threadId, authorId, body, hasSpoilers);
}

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ThreadRepository(ref.watch(threadRemoteDataSourceProvider));
});