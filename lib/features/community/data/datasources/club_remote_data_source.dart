import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/club_model.dart';
import '../../domain/entities/club.dart';

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
  }
}

final clubRemoteDataSourceProvider = Provider<ClubRemoteDataSource>((ref) {
  return ClubRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});