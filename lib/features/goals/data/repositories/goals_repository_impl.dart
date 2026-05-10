import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/goals_repository.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final SupabaseClient _client;
  GoalsRepositoryImpl(this._client);

  @override
  Future<int> getAnnualTarget(String userId, int year) async {
    final data = await _client.from('annual_goals').select('target_books').eq('user_id', userId).eq('year', year).maybeSingle();
    return (data?['target_books'] as int?) ?? 12;
  }

  @override
  Future<void> setAnnualTarget(String userId, int year, int target) async {
    await _client.from('annual_goals').upsert({
      'user_id': userId,
      'year': year,
      'target_books': target,
    }, onConflict: 'user_id,year');
  }

  @override
  Future<int> getBooksFinished(String userId, int year) async {
    final data = await _client.from('annual_goals').select('books_finished').eq('user_id', userId).eq('year', year).maybeSingle();
    return (data?['books_finished'] as int?) ?? 0;
  }

  @override
  Future<Map<int, int>> getMonthlyBooksData(String userId, int year) async {
    // Basic implementation since we don't have a direct EXTRACT query without RPC
    // We fetch all finished books for the year and group in dart
    final start = DateTime(year, 1, 1).toIso8601String();
    final end = DateTime(year, 12, 31).toIso8601String();
    
    final data = await _client
        .from('user_books')
        .select('finish_date')
        .eq('user_id', userId)
        .eq('status', 'finished')
        .gte('finish_date', start)
        .lte('finish_date', end);

    final map = <int, int>{};
    for (var row in data) {
      if (row['finish_date'] != null) {
        final month = DateTime.parse(row['finish_date']).month;
        map[month] = (map[month] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<Map<DateTime, int>> getHeatmapData(String userId, int year) async {
    final start = DateTime(year, 1, 1).toIso8601String();
    final end = DateTime(year, 12, 31).toIso8601String();
    
    final data = await _client
        .from('reading_sessions')
        .select('session_date, pages_read')
        .eq('user_id', userId)
        .gte('session_date', start)
        .lte('session_date', end);

    final map = <DateTime, int>{};
    for (var row in data) {
      final date = DateTime.parse(row['session_date']);
      // normalize to midnight
      final normalized = DateTime(date.year, date.month, date.day);
      map[normalized] = (map[normalized] ?? 0) + (row['pages_read'] as num).toInt();
    }
    return map;
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepositoryImpl(ref.watch(supabaseClientProvider));
});