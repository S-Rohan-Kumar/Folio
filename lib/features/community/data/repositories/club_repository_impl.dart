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
        .eq('club_members.user_id', userId);
        
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