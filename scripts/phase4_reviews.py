import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. DOMAIN & DATA
# ==========================================

w('lib/features/reviews/domain/entities/review.dart', r"""
class Review {
  final String id;
  final String userId;
  final String bookId;
  final double rating;
  final String? reviewText;
  final bool isSpoiler;
  final bool isPublic;
  final DateTime createdAt;
  
  // Joined fields
  final String? userDisplayName;

  const Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.rating,
    this.reviewText,
    required this.isSpoiler,
    required this.isPublic,
    required this.createdAt,
    this.userDisplayName,
  });
}
""".strip())

w('lib/features/reviews/domain/entities/note.dart', r"""
enum NoteType { note, quote, highlight }

class Note {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final int? pageNumber;
  final NoteType type;
  final bool isPublic;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    this.pageNumber,
    required this.type,
    required this.isPublic,
    required this.createdAt,
  });
}
""".strip())

w('lib/features/reviews/domain/repositories/review_repository.dart', r"""
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
""".strip())

w('lib/features/reviews/data/repositories/review_repository_impl.dart', r"""
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
""".strip())

w('lib/features/reviews/presentation/providers/review_provider.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/review_repository_impl.dart';

final bookReviewsProvider = FutureProvider.family<List<Review>, String>((ref, bookId) async {
  return ref.watch(reviewRepositoryProvider).getBookReviews(bookId);
});

final userReviewProvider = FutureProvider.family<Review?, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(reviewRepositoryProvider).getUserReview(user.id, bookId);
});

final bookNotesProvider = FutureProvider.family<List<Note>, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reviewRepositoryProvider).getBookNotes(user.id, bookId);
});
""".strip())

# ==========================================
# 2. REVIEW & NOTES SCREENS
# ==========================================

w('lib/features/reviews/presentation/screens/review_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/review.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReviewScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 0;
  final _reviewCtrl = TextEditingController();
  bool _isSpoiler = false;
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userReview = await ref.read(userReviewProvider(widget.bookId).future);
      if (userReview != null && mounted) {
        setState(() {
          _rating = userReview.rating;
          _reviewCtrl.text = userReview.reviewText ?? '';
          _isSpoiler = userReview.isSpoiler;
          _isPublic = userReview.isPublic;
        });
      }
    });
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating first')));
      return;
    }

    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider)!;
    
    final review = Review(
      id: '', // Will be generated or updated via upsert
      userId: user.id,
      bookId: widget.bookId,
      rating: _rating,
      reviewText: _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      isSpoiler: _isSpoiler,
      isPublic: _isPublic,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(reviewRepositoryProvider).saveReview(review);
      // Log XP if they wrote a text review
      if (review.reviewText != null) {
        await ref.read(reviewRepositoryProvider).logXp(user.id, 'wrote_review', 20);
      }
      
      ref.invalidate(bookReviewsProvider(widget.bookId));
      ref.invalidate(userReviewProvider(widget.bookId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved! (+20 XP)')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving review: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Write a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What did you think?', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.lg),
            
            // STAR RATING
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating.floor() ? Icons.star : (index < _rating ? Icons.star_half : Icons.star_border),
                    color: AppColors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: Spacing.lg),

            AppTextField(
              label: 'Your review (optional)',
              controller: _reviewCtrl,
              maxLines: 8,
              hint: 'What did you like or dislike? Would you recommend this book?',
            ),
            const SizedBox(height: Spacing.md),

            SwitchListTile(
              title: const Text('Contains spoilers', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Hide this review behind a warning', style: TextStyle(color: AppColors.textSecondary)),
              value: _isSpoiler,
              activeColor: AppColors.amber,
              onChanged: (val) => setState(() => _isSpoiler = val),
            ),
            SwitchListTile(
              title: const Text('Public review', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Allow others to see this review', style: TextStyle(color: AppColors.textSecondary)),
              value: _isPublic,
              activeColor: AppColors.amber,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            
            const SizedBox(height: Spacing.xl),
            AppButton(
              label: 'Save Review',
              isLoading: _isSaving,
              onPressed: _saveReview,
            ),
          ],
        ),
      ),
    );
  }
}
""".strip())

w('lib/features/reviews/presentation/widgets/add_note_bottom_sheet.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../providers/review_provider.dart';

class AddNoteBottomSheet extends ConsumerStatefulWidget {
  final String bookId;

  const AddNoteBottomSheet({super.key, required this.bookId});

  @override
  ConsumerState<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends ConsumerState<AddNoteBottomSheet> {
  final _contentCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  NoteType _type = NoteType.note;
  bool _isPublic = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter some text')));
      return;
    }

    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider)!;
    
    final note = Note(
      id: '', 
      userId: user.id,
      bookId: widget.bookId,
      content: _contentCtrl.text.trim(),
      pageNumber: int.tryParse(_pageCtrl.text),
      type: _type,
      isPublic: _isPublic,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(reviewRepositoryProvider).saveNote(note);
      
      ref.invalidate(bookNotesProvider(widget.bookId));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.elevated, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text('Add Entry', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            
            Wrap(
              spacing: Spacing.sm,
              children: NoteType.values.map((t) {
                final isSelected = _type == t;
                return ChoiceChip(
                  label: Text(t.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.amber,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(color: isSelected ? AppColors.background : AppColors.amber),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.md),

            AppTextField(
              label: 'Page number (optional)',
              controller: _pageCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Spacing.sm),
            
            AppTextField(
              label: 'Your text...',
              controller: _contentCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: Spacing.sm),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Make public', style: TextStyle(color: AppColors.textPrimary)),
              value: _isPublic,
              activeColor: AppColors.amber,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            
            const SizedBox(height: Spacing.md),
            AppButton(
              label: 'Save',
              isLoading: _isSaving,
              onPressed: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}
""".strip())

w('lib/features/reviews/presentation/widgets/reviews_tab.dart', r"""
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/review_provider.dart';

class ReviewsTab extends ConsumerWidget {
  final String bookId;

  const ReviewsTab({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userReviewAsync = ref.watch(userReviewProvider(bookId));
    final reviewsAsync = ref.watch(bookReviewsProvider(bookId));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: userReviewAsync.when(
              data: (review) {
                if (review == null) {
                  return AppButton(
                    label: 'Write a Review',
                    onPressed: () => context.push('/book/$bookId/review'),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.amber),
                    borderRadius: RadiusSize.md,
                    color: AppColors.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Review', style: AppTextStyles.titleLarge),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: AppColors.amber),
                            onPressed: () => context.push('/book/$bookId/review'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: AppColors.amber,
                          size: 16,
                        )),
                      ),
                      if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                        const SizedBox(height: Spacing.sm),
                        Text(review.reviewText!, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
            child: Text('Community Reviews', style: AppTextStyles.headlineMedium),
          ),
        ),
        reviewsAsync.when(
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No community reviews yet. Be the first!', style: TextStyle(color: AppColors.textHint))),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.purpleMuted,
                              child: Text(review.userDisplayName?[0] ?? 'R', style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(review.userDisplayName ?? 'Reader', style: AppTextStyles.labelLarge),
                            const Spacer(),
                            Text('${review.createdAt.month}/${review.createdAt.day}/${review.createdAt.year}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: AppColors.amber,
                            size: 14,
                          )),
                        ),
                        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                          const SizedBox(height: Spacing.sm),
                          if (review.isSpoiler)
                            _SpoilerWidget(text: review.reviewText!)
                          else
                            Text(review.reviewText!, style: AppTextStyles.bodyMedium),
                        ],
                      ],
                    ),
                  );
                },
                childCount: reviews.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SpoilerWidget extends StatefulWidget {
  final String text;
  const _SpoilerWidget({required this.text});

  @override
  State<_SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<_SpoilerWidget> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    if (!_isHidden) {
      return Text(widget.text, style: AppTextStyles.bodyMedium);
    }
    
    return GestureDetector(
      onTap: () => setState(() => _isHidden = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Text(widget.text, style: AppTextStyles.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
            child: const Text('SPOILER - TAP TO REVEAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
""".strip())

w('lib/features/reviews/presentation/widgets/notes_tab.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/review_provider.dart';
import 'add_note_bottom_sheet.dart';

class NotesTab extends ConsumerWidget {
  final String bookId;

  const NotesTab({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(bookNotesProvider(bookId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.', style: TextStyle(color: AppColors.textHint)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                          child: Text(note.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.amber)),
                        ),
                        const SizedBox(width: Spacing.sm),
                        if (note.pageNumber != null)
                          Text('p. ${note.pageNumber}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        if (!note.isPublic)
                          const Icon(Icons.lock, size: 12, color: AppColors.textHint),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(note.content, style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add, color: AppColors.background),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddNoteBottomSheet(bookId: bookId),
          );
        },
      ),
    );
  }
}
""".strip())

# ==========================================
# 3. ROUTER & BOOK DETAIL UPDATES
# ==========================================

w('lib/core/router/app_router.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/book_search/domain/entities/book.dart';
import '../../features/book_search/presentation/screens/barcode_scan_screen.dart';
import '../../features/community/domain/entities/club.dart';
import '../../features/community/domain/entities/thread.dart';
import '../../features/community/presentation/screens/club_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/thread_detail_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/reviews/presentation/screens/review_screen.dart';
import '../../shared/providers/supabase_provider.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      if (isGoingToSplash) return null;

      if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      if (isLoggedIn && isGoingToAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/auth/forgot_password', builder: (_, __) => const ForgotPasswordScreen()),

      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final book = state.extra as Book?;
          if (book != null) return BookDetailScreen(book: book);
          return BookDetailScreen(book: Book(id: state.pathParameters['id']!, title: 'Loading…', authors: [], categories: []));
        },
      ),
      GoRoute(
        path: '/book/:id/progress',
        builder: (context, state) => ProgressScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:id/review',
        builder: (context, state) => ReviewScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/scan', builder: (_, __) => const BarcodeScanScreen()),
      GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final club = state.extra as Club?;
          if (club != null) return ClubDetailScreen(club: club);
          return const CommunityScreen();
        },
      ),
      GoRoute(
        path: '/thread/:id',
        builder: (context, state) {
          final thread = state.extra as Thread?;
          if (thread != null) return ThreadDetailScreen(thread: thread);
          return const CommunityScreen();
        },
      ),
    ],
  );
});
""".strip())

print("Phase 4 scripts generated successfully")
