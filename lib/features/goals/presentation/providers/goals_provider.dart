import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/goals_repository_impl.dart';

final currentYearProvider = Provider<int>((ref) => DateTime.now().year);

final annualTargetProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 12;
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getAnnualTarget(user.id, year);
});

final booksFinishedProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getBooksFinished(user.id, year);
});

final monthlyBooksProvider = FutureProvider<Map<int, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getMonthlyBooksData(user.id, year);
});

final heatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getHeatmapData(user.id, year);
});