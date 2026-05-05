import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── Clubs Domain & Data ────────────────────────────────────────────────
w('lib/features/community/domain/entities/club.dart', r"""
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

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    this.isPublic = true,
    this.inviteCode,
    this.currentBookId,
    this.memberCount = 1,
    required this.createdAt,
  });
}

class ClubMember {
  final String clubId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  const ClubMember({
    required this.clubId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });
}
""".strip())

w('lib/features/community/data/models/club_model.dart', r"""
import '../domain/entities/club.dart';

class ClubModel {
  static Club fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    coverUrl: json['cover_url'] as String?,
    ownerId: json['owner_id'] as String,
    isPublic: json['is_public'] as bool? ?? true,
    inviteCode: json['invite_code'] as String?,
    currentBookId: json['current_book_id'] as String?,
    memberCount: json['member_count'] as int? ?? 1,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
""".strip())

w('lib/features/community/data/datasources/club_remote_data_source.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/club_model.dart';
import '../domain/entities/club.dart';

abstract class ClubRemoteDataSource {
  Future<List<Club>> getPublicClubs({int offset = 0, int limit = 20});
  Future<List<Club>> getUserClubs(String userId);
  Future<Club> createClub(String name, String description, String ownerId, bool isPublic);
  Future<void> joinClub(String clubId, String userId);
}

class ClubRemoteDataSourceImpl implements ClubRemoteDataSource {
  final SupabaseClient _client;
  const ClubRemoteDataSourceImpl(this._client);

  @override
  Future<List<Club>> getPublicClubs({int offset = 0, int limit = 20}) async {
    final data = await _client
        .from('clubs')
        .select()
        .eq('is_public', true)
        .order('member_count', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((e) => ClubModel.fromJson(e)).toList();
  }

  @override
  Future<List<Club>> getUserClubs(String userId) async {
    final memberships = await _client
        .from('club_members')
        .select('clubs(*)')
        .eq('user_id', userId);
    return (memberships as List)
        .map((e) => ClubModel.fromJson(e['clubs'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Club> createClub(String name, String description, String ownerId, bool isPublic) async {
    final data = await _client.from('clubs').insert({
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'is_public': isPublic,
    }).select().single();
    
    // Auto-join the creator as owner
    await _client.from('club_members').insert({
      'club_id': data['id'],
      'user_id': ownerId,
      'role': 'owner',
    });
    
    return ClubModel.fromJson(data);
  }

  @override
  Future<void> joinClub(String clubId, String userId) async {
    await _client.from('club_members').insert({
      'club_id': clubId,
      'user_id': userId,
      'role': 'member',
    });
    
    // update member count
    await _client.rpc('increment_club_members', params: {'row_id': clubId});
  }
}

final clubRemoteDataSourceProvider = Provider<ClubRemoteDataSource>((ref) {
  return ClubRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});
""".strip())

w('lib/features/community/data/repositories/club_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/club_remote_data_source.dart';
import '../domain/entities/club.dart';

class ClubRepository {
  final ClubRemoteDataSource _remote;
  const ClubRepository(this._remote);

  Future<List<Club>> getPublicClubs({int offset = 0, int limit = 20}) =>
      _remote.getPublicClubs(offset: offset, limit: limit);

  Future<List<Club>> getUserClubs(String userId) =>
      _remote.getUserClubs(userId);

  Future<Club> createClub(String name, String description, String ownerId, bool isPublic) =>
      _remote.createClub(name, description, ownerId, isPublic);

  Future<void> joinClub(String clubId, String userId) =>
      _remote.joinClub(clubId, userId);
}

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(ref.watch(clubRemoteDataSourceProvider));
});
""".strip())

# ── Threads Domain & Data ─────────────────────────────────────────────
w('lib/features/community/domain/entities/thread.dart', r"""
class Thread {
  final String id;
  final String bookId;
  final String? clubId;
  final String authorId;
  final String title;
  final String body;
  final bool hasSpoilers;
  final int replyCount;
  final DateTime createdAt;

  const Thread({
    required this.id,
    required this.bookId,
    this.clubId,
    required this.authorId,
    required this.title,
    required this.body,
    this.hasSpoilers = false,
    this.replyCount = 0,
    required this.createdAt,
  });
}

class ThreadReply {
  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final bool hasSpoilers;
  final DateTime createdAt;

  const ThreadReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    this.hasSpoilers = false,
    required this.createdAt,
  });
}
""".strip())

w('lib/features/community/data/models/thread_model.dart', r"""
import '../domain/entities/thread.dart';

class ThreadModel {
  static Thread fromJson(Map<String, dynamic> json) => Thread(
    id: json['id'] as String,
    bookId: json['book_id'] as String,
    clubId: json['club_id'] as String?,
    authorId: json['author_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    hasSpoilers: json['has_spoilers'] as bool? ?? false,
    replyCount: json['reply_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static ThreadReply replyFromJson(Map<String, dynamic> json) => ThreadReply(
    id: json['id'] as String,
    threadId: json['thread_id'] as String,
    authorId: json['author_id'] as String,
    body: json['body'] as String,
    hasSpoilers: json['has_spoilers'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
""".strip())

w('lib/features/community/data/datasources/thread_remote_data_source.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/thread_model.dart';
import '../domain/entities/thread.dart';

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
""".strip())

w('lib/features/community/data/repositories/thread_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/thread_remote_data_source.dart';
import '../domain/entities/thread.dart';

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
""".strip())

# ── Battles Domain & Data ─────────────────────────────────────────────
w('lib/features/community/domain/entities/battle.dart', r"""
enum BattleStatus { pending, active, completed, cancelled }

class Battle {
  final String id;
  final String challengerId;
  final String rivalId;
  final String bookId;
  final BattleStatus status;
  final int challengerPage;
  final int rivalPage;
  final String? winnerId;
  final DateTime createdAt;

  const Battle({
    required this.id,
    required this.challengerId,
    required this.rivalId,
    required this.bookId,
    required this.status,
    this.challengerPage = 0,
    this.rivalPage = 0,
    this.winnerId,
    required this.createdAt,
  });
}
""".strip())

w('lib/features/community/data/models/battle_model.dart', r"""
import '../domain/entities/battle.dart';

class BattleModel {
  static Battle fromJson(Map<String, dynamic> json) => Battle(
    id: json['id'] as String,
    challengerId: json['challenger_id'] as String,
    rivalId: json['rival_id'] as String,
    bookId: json['book_id'] as String,
    status: _parseStatus(json['status'] as String),
    challengerPage: json['challenger_page'] as int? ?? 0,
    rivalPage: json['rival_page'] as int? ?? 0,
    winnerId: json['winner_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static BattleStatus _parseStatus(String s) {
    switch (s) {
      case 'active': return BattleStatus.active;
      case 'completed': return BattleStatus.completed;
      case 'cancelled': return BattleStatus.cancelled;
      default: return BattleStatus.pending;
    }
  }
}
""".strip())

w('lib/features/community/data/datasources/battle_remote_data_source.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/battle_model.dart';
import '../domain/entities/battle.dart';

abstract class BattleRemoteDataSource {
  Future<List<Battle>> getUserBattles(String userId);
}

class BattleRemoteDataSourceImpl implements BattleRemoteDataSource {
  final SupabaseClient _client;
  const BattleRemoteDataSourceImpl(this._client);

  @override
  Future<List<Battle>> getUserBattles(String userId) async {
    final data = await _client
        .from('battles')
        .select()
        .or('challenger_id.eq.$userId,rival_id.eq.$userId')
        .order('created_at', ascending: false);
    return (data as List).map((e) => BattleModel.fromJson(e)).toList();
  }
}

final battleRemoteDataSourceProvider = Provider<BattleRemoteDataSource>((ref) {
  return BattleRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});
""".strip())

w('lib/features/community/data/repositories/battle_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/battle_remote_data_source.dart';
import '../domain/entities/battle.dart';

class BattleRepository {
  final BattleRemoteDataSource _remote;
  const BattleRepository(this._remote);

  Future<List<Battle>> getUserBattles(String userId) => _remote.getUserBattles(userId);
}

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return BattleRepository(ref.watch(battleRemoteDataSourceProvider));
});
""".strip())

print("Phase 3 data layer generated successfully")
