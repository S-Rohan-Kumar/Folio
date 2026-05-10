import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/thread.dart';
import '../../domain/repositories/thread_repository.dart';

class ThreadRepositoryImpl implements ThreadRepository {
  final SupabaseClient _client;
  ThreadRepositoryImpl(this._client);

  @override
  Future<List<Thread>> getThreads({String? clubId, String? bookId, int limit = 20, int offset = 0}) async {
    var query = _client.from('threads').select('*, users!inner(username, full_name, avatar_url), books(title)');
    
    if (clubId != null) {
      query = query.eq('club_id', clubId);
    } else {
      query = query.isFilter('club_id', null);
    }
    
    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }
    
    final data = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
        
    return (data as List).map((row) => _mapThread(row)).toList();
  }

  @override
  Future<Thread> getThreadDetails(String threadId) async {
    final data = await _client
        .from('threads')
        .select('*, users!inner(username, full_name, avatar_url), books(title)')
        .eq('id', threadId)
        .single();
    return _mapThread(data);
  }

  @override
  Future<void> createThread(Thread thread) async {
    await _client.from('threads').insert({
      'book_id': thread.bookId,
      'club_id': thread.clubId,
      'author_id': thread.authorId,
      'title': thread.title,
      'body': thread.body,
      'has_spoilers': thread.hasSpoilers,
      'reply_count': 0,
    });
  }

  @override
  Future<void> createReply(ThreadReply reply) async {
    await _client.from('thread_replies').insert({
      'thread_id': reply.threadId,
      'author_id': reply.authorId,
      'body': reply.body,
      'has_spoilers': reply.hasSpoilers,
      'parent_reply_id': reply.parentReplyId,
    });
  }

  @override
  Future<void> incrementReplyCount(String threadId) async {
    // To safely increment without RPC, we can read then write, or rely on a DB trigger.
    // The prompt explicitly asks to increment. We'll use a simple approach here.
    // Or we can create an RPC. Let's assume we can just rely on the stream or an RPC.
    await _client.rpc('increment_reply_count', params: {'thread_id_param': threadId});
  }

  @override
  Stream<List<ThreadReply>> watchReplies(String threadId) {
    // CRITICAL: Supabase Realtime Stream Implementation
    return _client
        .from('thread_replies')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          // Stream gives us raw thread_replies. We need to fetch user data for them.
          // In a production app, we'd use a database view or replicate user data into the table.
          // For this prompt, we'll fetch the user data in dart to map to the entity properly.
          
          if (data.isEmpty) return [];
          
          final userIds = data.map((e) => e['author_id'] as String).toSet().toList();
          final usersData = await _client.from('users').select('id, username, full_name, avatar_url').inFilter('id', userIds);
          final userMap = {for (var u in usersData) u['id'] as String: u};
          
          return data.map((row) {
            final user = userMap[row['author_id']];
            row['users'] = user; // inject user data into json
            return ThreadReply.fromJson(row);
          }).toList();
        });
  }

  Thread _mapThread(Map<String, dynamic> row) {
    return Thread(
      id: row['id'],
      bookId: row['book_id'],
      clubId: row['club_id'],
      authorId: row['author_id'],
      title: row['title'],
      body: row['body'],
      hasSpoilers: row['has_spoilers'] ?? false,
      replyCount: row['reply_count'] ?? 0,
      createdAt: DateTime.parse(row['created_at']),
      authorUsername: row['users']['username'] ?? row['users']['full_name'],
      authorAvatarUrl: row['users']['avatar_url'],
      bookTitle: row['books']?['title'],
    );
  }
}