import '../entities/reading_session.dart';

abstract class ProgressRepository {
  Future<void> saveReadingSession({
    required String userId,
    required String bookId,
    required int startPage,
    required int endPage,
    required int durationSecs,
    String? notes,
  });
  
  Future<List<ReadingSession>> getReadingSessions(String userId, String bookId);
  Future<double> getReadingSpeed(String userId); // pages per hour
  Future<void> logXp(String userId, String action, int xpEarned);
}