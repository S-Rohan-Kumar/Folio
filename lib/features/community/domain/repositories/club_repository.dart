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