import '../entities/review.dart';
import '../entities/note.dart';

abstract class ReviewRepository {
  Future<void> saveReview(Review review);
  Future<List<Review>> getBookReviews(String bookId);
  Future<Review?> getUserReview(String userId, String bookId);
  
  Future<void> saveNote(Note note);
  Future<List<Note>> getBookNotes(String userId, String bookId);
  
  Future<void> logXp(String userId, String action, int xpEarned);
}