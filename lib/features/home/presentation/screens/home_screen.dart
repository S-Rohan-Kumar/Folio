import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/providers/library_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final readingAsync = ref.watch(libraryReadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user?.email),
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          SliverToBoxAdapter(child: _buildSectionHeader('Currently Reading', onSeeAll: () => context.go('/library'))),
          SliverToBoxAdapter(
            child: readingAsync.when(
              loading: () => SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: Spacing.sm),
                  itemBuilder: (_, __) => const SizedBox(
                    width: 120,
                    child: BookCardShimmer(),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (books) => books.isEmpty
                  ? _buildEmptyReadingState(context)
                  : _buildReadingList(context, books),
            ),
          ),
          SliverToBoxAdapter(child: _buildSectionHeader('Reading Goal', onSeeAll: null)),
          SliverToBoxAdapter(child: _buildGoalPlaceholder()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildAppBar(String? email) {
    final name = email?.split('@').first ?? 'Reader';
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '👋 Hey, ', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textSecondary)),
                TextSpan(text: name, style: AppTextStyles.headlineMedium),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.1),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Spacing.sm),
          child: CircleAvatar(
            backgroundColor: AppColors.amberMuted,
            radius: 18,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/discover'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.lg,
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Text('Search books, authors…', style: AppTextStyles.bodyMedium),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all', style: TextStyle(color: AppColors.amber)),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingList(BuildContext context, List<UserBook> books) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.md),
        itemCount: books.length,
        itemBuilder: (context, i) {
          final ub = books[i];
          return SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  height: 185,
                  child: BookCard(
                    book: ub.book,
                    userBook: ub,
                    animationIndex: i,
                    onTap: () => context.push('/book/${ub.book.id}', extra: ub.book),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: ub.progressPercent,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(_progressColor(ub.progressPercent)),
                  minHeight: 3,
                  borderRadius: RadiusSize.pill,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(ub.progressPercent * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _progressColor(double p) {
    if (p < 0.33) return AppColors.amber;
    if (p < 0.66) return AppColors.success;
    return AppColors.purple;
  }

  Widget _buildEmptyReadingState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: RadiusSize.lg,
        border: Border.all(color: AppColors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('📚', style: TextStyle(fontSize: 36)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start your first book', style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text('Search for a book and start reading', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.go('/discover'),
                  child: Text('Browse books →', style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGoalPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.amberMuted.withOpacity(0.3), AppColors.purpleMuted.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: RadiusSize.lg,
        border: Border.all(color: AppColors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: _GoalRing(progress: 0, label: '0 / 12'),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2026 Reading Goal', style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text('Set your goal and track your pace', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: RadiusSize.pill),
                  child: Text('On track 🎯', style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _GoalRing extends StatelessWidget {
  final double progress;
  final String label;
  const _GoalRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(progress: progress),
      child: Center(
        child: Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    paint.color = AppColors.surfaceVariant;
    canvas.drawCircle(center, radius, paint);

    paint.color = AppColors.amber;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 6.2832,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}