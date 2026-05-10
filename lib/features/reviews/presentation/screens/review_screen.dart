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