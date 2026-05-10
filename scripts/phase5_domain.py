import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. ENTITIES
# ==========================================

w('lib/features/community/domain/entities/club.dart', r"""
import '../../../book_search/domain/entities/book.dart';

class Club {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String ownerId;
  final bool isPublic;
  final String? inviteCode;
  final String? currentBookId;
  final int memberCount;
  final DateTime createdAt;

  // Joined fields
  final Book? currentBook;

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    required this.isPublic,
    this.inviteCode,
    this.currentBookId,
    required this.memberCount,
    required this.createdAt,
    this.currentBook,
  });
}

class ClubMember {
  final String clubId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  
  // Joined fields
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const ClubMember({
    required this.clubId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });
}
""".strip())

w('lib/features/community/domain/entities/thread.dart', r"""
class Thread {
  final String id;
  final String? bookId;
  final String? clubId;
  final String authorId;
  final String title;
  final String body;
  final bool hasSpoilers;
  final int replyCount;
  final DateTime createdAt;

  // Joined
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? bookTitle;

  const Thread({
    required this.id,
    this.bookId,
    this.clubId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.hasSpoilers,
    required this.replyCount,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.bookTitle,
  });
}

class ThreadReply {
  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final bool hasSpoilers;
  final String? parentReplyId;
  final DateTime createdAt;

  // Joined
  final String? authorUsername;
  final String? authorAvatarUrl;

  const ThreadReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.hasSpoilers,
    this.parentReplyId,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory ThreadReply.fromJson(Map<String, dynamic> json) {
    return ThreadReply(
      id: json['id'],
      threadId: json['thread_id'],
      authorId: json['author_id'],
      body: json['body'],
      hasSpoilers: json['has_spoilers'] ?? false,
      parentReplyId: json['parent_reply_id'],
      createdAt: DateTime.parse(json['created_at']),
      authorUsername: json['users']?['username'] ?? json['users']?['full_name'], // Join might use full_name depending on schema
      authorAvatarUrl: json['users']?['avatar_url'],
    );
  }
}
""".strip())

# ==========================================
# 2. REPOSITORIES
# ==========================================

w('lib/features/community/domain/repositories/club_repository.dart', r"""
import '../entities/club.dart';

abstract class ClubRepository {
  Future<List<Club>> getMyClubs(String userId);
  Future<List<Club>> getDiscoverClubs(String userId);
  Future<Club> getClubDetails(String clubId);
  Future<List<ClubMember>> getClubMembers(String clubId);
  
  Future<Club> createClub(Club club);
  Future<void> joinClub(String userId, String clubId, {String? inviteCode});
  Future<void> leaveClub(String userId, String clubId);
  Future<void> deleteClub(String clubId);
  Future<void> updateClub(String clubId, Map<String, dynamic> updates);
}
""".strip())

w('lib/features/community/data/repositories/club_repository_impl.dart', r"""
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';

class ClubRepositoryImpl implements ClubRepository {
  final SupabaseClient _client;
  ClubRepositoryImpl(this._client);

  @override
  Future<List<Club>> getMyClubs(String userId) async {
    final data = await _client
        .from('clubs')
        .select('*, club_members!inner(user_id, joined_at), books(*)')
        .eq('club_members.user_id', userId)
        .order('joined_at', foreignTable: 'club_members', ascending: false);
        
    return (data as List).map((row) => _mapClub(row)).toList();
  }

  @override
  Future<List<Club>> getDiscoverClubs(String userId) async {
    // Basic implementation: get all public clubs, we'll filter out joined ones in dart or via a complex query
    // To do it in one query: 
    // SELECT * FROM clubs WHERE is_public = true AND id NOT IN (SELECT club_id FROM club_members WHERE user_id = userId)
    // Supabase doesn't have a direct 'NOT IN' subquery via SDK easily, so we use RPC or filter in Dart for now.
    
    // First get user's club IDs
    final myClubsData = await _client.from('club_members').select('club_id').eq('user_id', userId);
    final myClubIds = (myClubsData as List).map((e) => e['club_id'] as String).toSet();
    
    final data = await _client
        .from('clubs')
        .select('*, books(*)')
        .eq('is_public', true)
        .order('member_count', ascending: false)
        .limit(20);
        
    final allPublic = (data as List).map((row) => _mapClub(row)).toList();
    return allPublic.where((c) => !myClubIds.contains(c.id)).toList();
  }

  @override
  Future<Club> getClubDetails(String clubId) async {
    final data = await _client
        .from('clubs')
        .select('*, books(*)')
        .eq('id', clubId)
        .single();
    return _mapClub(data);
  }

  @override
  Future<List<ClubMember>> getClubMembers(String clubId) async {
    final data = await _client
        .from('club_members')
        .select('*, users(username, full_name, avatar_url)')
        .eq('club_id', clubId)
        .order('joined_at', ascending: true);
        
    return (data as List).map((row) => ClubMember(
      clubId: row['club_id'],
      userId: row['user_id'],
      role: row['role'],
      joinedAt: DateTime.parse(row['joined_at']),
      username: row['users']['username'],
      displayName: row['users']['full_name'],
      avatarUrl: row['users']['avatar_url'],
    )).toList();
  }

  @override
  Future<Club> createClub(Club club) async {
    final data = await _client.from('clubs').insert({
      'name': club.name,
      'description': club.description,
      'owner_id': club.ownerId,
      'is_public': club.isPublic,
      'invite_code': club.inviteCode,
      'current_book_id': club.currentBookId,
      'member_count': 1, // Owner is first member
    }).select().single();
    
    final newClub = _mapClub(data);
    
    // Add owner as member
    await _client.from('club_members').insert({
      'club_id': newClub.id,
      'user_id': club.ownerId,
      'role': 'owner',
    });
    
    return newClub;
  }

  @override
  Future<void> joinClub(String userId, String clubId, {String? inviteCode}) async {
    if (inviteCode != null) {
      final club = await _client.from('clubs').select('invite_code, is_public').eq('id', clubId).single();
      if (!club['is_public'] && club['invite_code'] != inviteCode) {
        throw Exception('Invalid invite code');
      }
    }
    
    await _client.from('club_members').insert({
      'club_id': clubId,
      'user_id': userId,
      'role': 'member',
    });
    
    // Note: The prompt assumes member_count increment is done in app or via trigger.
    // I will trigger it manually via rpc or simple update to be safe, though a DB trigger is better.
    // The previous Phase 1-3 fix added `update_club_member_count` trigger to DB, so we don't need to manually increment here!
  }

  @override
  Future<void> leaveClub(String userId, String clubId) async {
    await _client.from('club_members').delete().eq('club_id', clubId).eq('user_id', userId);
  }

  @override
  Future<void> deleteClub(String clubId) async {
    await _client.from('clubs').delete().eq('id', clubId);
  }

  @override
  Future<void> updateClub(String clubId, Map<String, dynamic> updates) async {
    await _client.from('clubs').update(updates).eq('id', clubId);
  }

  Club _mapClub(Map<String, dynamic> row) {
    Book? book;
    if (row['books'] != null) {
      final b = row['books'];
      book = Book(
        id: b['id'],
        title: b['title'],
        authors: b['authors'] != null ? List<String>.from(b['authors']) : [],
        thumbnailUrl: b['thumbnail_url'],
        categories: b['categories'] != null ? List<String>.from(b['categories']) : [],
      );
    }
    
    return Club(
      id: row['id'],
      name: row['name'],
      description: row['description'],
      coverUrl: row['cover_url'],
      ownerId: row['owner_id'],
      isPublic: row['is_public'],
      inviteCode: row['invite_code'],
      currentBookId: row['current_book_id'],
      memberCount: row['member_count'],
      createdAt: DateTime.parse(row['created_at']),
      currentBook: book,
    );
  }
}
""".strip())

w('lib/features/community/domain/repositories/thread_repository.dart', r"""
import '../entities/thread.dart';

abstract class ThreadRepository {
  Future<List<Thread>> getThreads({String? clubId, String? bookId, int limit = 20, int offset = 0});
  Future<Thread> getThreadDetails(String threadId);
  Future<void> createThread(Thread thread);
  Future<void> createReply(ThreadReply reply);
  Future<void> incrementReplyCount(String threadId);
  Stream<List<ThreadReply>> watchReplies(String threadId);
}
""".strip())

w('lib/features/community/data/repositories/thread_repository_impl.dart', r"""
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
      query = query.is_('club_id', null);
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
""".strip())

w('supabase/fix_community.sql', r"""
CREATE OR REPLACE FUNCTION increment_reply_count(thread_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.threads 
  SET reply_count = reply_count + 1
  WHERE id = thread_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""".strip())

print("Phase 5 domain and repository layer created")
