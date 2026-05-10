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