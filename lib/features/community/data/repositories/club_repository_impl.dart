import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/club_remote_data_source.dart';
import '../../domain/entities/club.dart';

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