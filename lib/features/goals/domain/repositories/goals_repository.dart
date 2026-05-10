abstract class GoalsRepository {
  Future<int> getAnnualTarget(String userId, int year);
  Future<void> setAnnualTarget(String userId, int year, int target);
  Future<int> getBooksFinished(String userId, int year);
  Future<Map<int, int>> getMonthlyBooksData(String userId, int year);
  Future<Map<DateTime, int>> getHeatmapData(String userId, int year);
}