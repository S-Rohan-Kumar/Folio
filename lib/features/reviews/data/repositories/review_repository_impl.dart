import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;
  ReviewRepositoryImpl(this._client);

  @override
  Future<void> saveReview(Review review) async {
    await _client.from('reviews').upsert({
      'user_id': review.userId,
      'book_id': review.bookId,
      'rating': review.rating,
      'review_text': review.reviewText,
      'is_spoiler': review.isSpoiler,
      'is_public': review.isPublic,
    }, onConflict: 'user_id,book_id');
  }

  @override
  Future<List<Review>> getBookReviews(String bookId) async {
    final data = await _client
        .from('reviews')
        .select('*, users(full_name)')
        .eq('book_id', bookId)
        .eq('is_public', true)
        .order('created_at', ascending: false);
        
    return (data as List).map((row) => Review(
      id: row['id'],
      userId: row['user_id'],
      bookId: row['book_id'],
      rating: (row['rating'] as num).toDouble(),
      reviewText: row['review_text'],
      isSpoiler: row['is_spoiler'] ?? false,
      isPublic: row['is_public'] ?? true,
      createdAt: DateTime.parse(row['created_at']),
      userDisplayName: row['users']?['full_name'],
    )).toList();
  }

  @override
  Future<Review?> getUserReview(String userId, String bookId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
        
    if (data == null) return null;
    
    return Review(
      id: data['id'],
      userId: data['user_id'],
      bookId: data['book_id'],
      rating: (data['rating'] as num).toDouble(),
      reviewText: data['review_text'],
      isSpoiler: data['is_spoiler'] ?? false,
      isPublic: data['is_public'] ?? true,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    await _client.from('notes').insert({
      'user_id': note.userId,
      'book_id': note.bookId,
      'content': note.content,
      'page_number': note.pageNumber,
      'type': note.type.name,
      'is_public': note.isPublic,
    });
  }

  @override
  Future<List<Note>> getBookNotes(String userId, String bookId) async {
    final data = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
        
    return (data as List).map((row) => Note(
      id: row['id'],
      userId: row['user_id'],
      bookId: row['book_id'],
      content: row['content'],
      pageNumber: row['page_number'],
      type: NoteType.values.firstWhere((e) => e.name == row['type'], orElse: () => NoteType.note),
      isPublic: row['is_public'] ?? false,
      createdAt: DateTime.parse(row['created_at']),
    )).toList();
  }

  @override
  Future<void> logXp(String userId, String action, int xpEarned) async {
    await _client.from('xp_log').insert({
      'user_id': userId,
      'action': action,
      'xp_earned': xpEarned,
    });
    await _client.rpc('increment_user_xp', params: {'user_id_param': userId, 'amount': xpEarned});
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(supabaseClientProvider));
});