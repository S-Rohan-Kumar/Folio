import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final SupabaseClient _client;
  ProgressRepositoryImpl(this._client);

  @override
  Future<void> saveReadingSession({
    required String userId,
    required String bookId,
    required int startPage,
    required int endPage,
    required int durationSecs,
    String? notes,
  }) async {
    // 1. Save session
    await _client.from('reading_sessions').insert({
      'user_id': userId,
      'book_id': bookId,
      'start_page': startPage,
      'end_page': endPage,
      'duration_secs': durationSecs,
      'notes': notes,
      'session_date': DateTime.now().toIso8601String().split('T').first,
    });

    // 2. Update user_books
    // Check if finished
    final ub = await _client.from('user_books').select('total_pages, books(page_count)').eq('user_id', userId).eq('book_id', bookId).single();
    final total = (ub['total_pages'] as int?) ?? (ub['books']['page_count'] as int?) ?? 9999;
    
    final isFinished = endPage >= total;
    
    await _client.from('user_books').update({
      'current_page': endPage,
      'updated_at': DateTime.now().toIso8601String(),
      if (isFinished) 'status': 'finished',
      if (isFinished) 'finish_date': DateTime.now().toIso8601String().split('T').first,
    }).eq('user_id', userId).eq('book_id', bookId);
  }

  @override
  Future<List<ReadingSession>> getReadingSessions(String userId, String bookId) async {
    final data = await _client
        .from('reading_sessions')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
        
    return (data as List).map((row) => ReadingSession(
      id: row['id'],
      userId: row['user_id'],
      bookId: row['book_id'],
      startPage: row['start_page'],
      endPage: row['end_page'],
      pagesRead: row['pages_read'],
      durationSecs: row['duration_secs'],
      sessionDate: DateTime.parse(row['session_date']),
      notes: row['notes'],
    )).toList();
  }

  @override
  Future<double> getReadingSpeed(String userId) async {
    final data = await _client
        .from('reading_sessions')
        .select('pages_read, duration_secs')
        .eq('user_id', userId);
        
    if (data.isEmpty) return 0.0;
    
    int totalPages = 0;
    int totalSecs = 0;
    for (var row in data) {
      totalPages += (row['pages_read'] as num).toInt();
      totalSecs += (row['duration_secs'] as num).toInt();
    }
    
    if (totalSecs == 0) return 0.0;
    return (totalPages / (totalSecs / 3600));
  }

  @override
  Future<void> logXp(String userId, String action, int xpEarned) async {
    await _client.from('xp_log').insert({
      'user_id': userId,
      'action': action,
      'xp_earned': xpEarned,
    });
    
    // Increment user XP
    await _client.rpc('increment_user_xp', params: {'user_id_param': userId, 'amount': xpEarned});
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepositoryImpl(ref.watch(supabaseClientProvider));
});