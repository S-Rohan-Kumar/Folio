import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/thread_model.dart';
import '../../domain/entities/thread.dart';

abstract class ThreadRemoteDataSource {
  Future<List<Thread>> getRecentThreads({int limit = 20});
  Future<List<Thread>> getClubThreads(String clubId);
  Future<List<ThreadReply>> getThreadReplies(String threadId);
  Future<Thread> createThread(String bookId, String? clubId, String authorId, String title, String body, bool hasSpoilers);
  Future<ThreadReply> createReply(String threadId, String authorId, String body, bool hasSpoilers);
}

class ThreadRemoteDataSourceImpl implements ThreadRemoteDataSource {
  final SupabaseClient _client;
  const ThreadRemoteDataSourceImpl(this._client);

  @override
  Future<List<Thread>> getRecentThreads({int limit = 20}) async {
    final data = await _client
        .from('threads')
        .select()
        .isFilter('club_id', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => ThreadModel.fromJson(e)).toList();
  }

  @override
  Future<List<Thread>> getClubThreads(String clubId) async {
    final data = await _client
        .from('threads')
        .select()
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ThreadModel.fromJson(e)).toList();
  }

  @override
  Future<List<ThreadReply>> getThreadReplies(String threadId) async {
    final data = await _client
        .from('thread_replies')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ThreadModel.replyFromJson(e)).toList();
  }

  @override
  Future<Thread> createThread(String bookId, String? clubId, String authorId, String title, String body, bool hasSpoilers) async {
    final data = await _client.from('threads').insert({
      'book_id': bookId,
      'club_id': clubId,
      'author_id': authorId,
      'title': title,
      'body': body,
      'has_spoilers': hasSpoilers,
    }).select().single();
    return ThreadModel.fromJson(data);
  }

  @override
  Future<ThreadReply> createReply(String threadId, String authorId, String body, bool hasSpoilers) async {
    final data = await _client.from('thread_replies').insert({
      'thread_id': threadId,
      'author_id': authorId,
      'body': body,
      'has_spoilers': hasSpoilers,
    }).select().single();
    return ThreadModel.replyFromJson(data);
  }
}

final threadRemoteDataSourceProvider = Provider<ThreadRemoteDataSource>((ref) {
  return ThreadRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});