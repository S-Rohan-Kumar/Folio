import '../entities/thread.dart';

abstract class ThreadRepository {
  Future<List<Thread>> getThreads({String? clubId, String? bookId, int limit = 20, int offset = 0});
  Future<Thread> getThreadDetails(String threadId);
  Future<void> createThread(Thread thread);
  Future<void> createReply(ThreadReply reply);
  Future<void> incrementReplyCount(String threadId);
  Stream<List<ThreadReply>> watchReplies(String threadId);
}