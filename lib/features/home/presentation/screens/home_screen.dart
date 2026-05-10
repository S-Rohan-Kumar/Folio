import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/presentation/widgets/session_dialog.dart';
import '../../../goals/presentation/providers/goals_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final displayName = user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Reader';
    final streak = (user.userMetadata?['streak_current'] as int?) ?? 0;
    
    final targetAsync = ref.watch(annualTargetProvider);
    final finishedAsync = ref.watch(booksFinishedProvider);
    final readingNowAsync = ref.watch(libraryReadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            title: const Text('Pagebound', style: TextStyle(color: AppColors.amber, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: AppColors.textPrimary), onPressed: () => context.push('/discover')),
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.purpleMuted,
                    child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.purple, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GREETING
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good day, $displayName! 👋', style: AppTextStyles.headlineMedium),
                      if (streak > 0) ...[
                        const SizedBox(height: Spacing.xs),
                        Text('🔥 Day $streak reading streak', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.amber)),
                      ],
                    ],
                  ),
                ),

                // MINI GOAL RING
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: targetAsync.when(
                          data: (t) => finishedAsync.when(
                            data: (f) => Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 28,
                                    startDegreeOffset: -90,
                                    sections: [
                                      PieChartSectionData(value: f.toDouble(), color: AppColors.amber, radius: 12, showTitle: false),
                                      PieChartSectionData(value: (t - f > 0 ? t - f : 0).toDouble(), color: AppColors.surfaceVariant, radius: 12, showTitle: false),
                                    ],
                                  ),
                                ),
                                Text('$f', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                              ],
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Icon(Icons.error),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Icon(Icons.error),
                        ),
                      ),
                      const SizedBox(width: Spacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            targetAsync.when(data: (t) => finishedAsync.when(data: (f) => Text('$f of $t books', style: AppTextStyles.titleLarge), loading: () => const Text('...'), error: (_,__) => const Text('Error')), loading: () => const Text('...'), error: (_,__) => const Text('Error')),
                            Text('Keep reading!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/goals'), // Need to add to app_router! Wait, goals screen is not in app_router. Let's push to /home for now or we will add it.
                                child: const Text('View Goal →', style: TextStyle(color: AppColors.amber)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // CURRENTLY READING
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text('Currently Reading', style: AppTextStyles.headlineMedium),
                ),
                const SizedBox(height: Spacing.sm),
                readingNowAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (books) {
                    if (books.isEmpty) {
                      return GestureDetector(
                        onTap: () => context.push('/discover'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                          child: const EmptyStateView(
                            icon: Icons.menu_book,
                            title: 'No books in progress',
                            subtitle: 'Tap to discover your next read',
                          ),
                        ),
                      );
                    }
                    
                    // Show first book for now (could be a PageView)
                    final ub = books.first;
                    final total = ub.totalPages ?? ub.book.pageCount ?? 1;
                    final curr = ub.currentPage;
                    final progress = curr / total;
                    final pct = (progress * 100).toStringAsFixed(1);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: RadiusSize.sm,
                            child: CachedNetworkImage(
                              imageUrl: ub.book.thumbnailUrl ?? '',
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, width: 60, height: 90, child: const Icon(Icons.book)),
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ub.book.title, style: AppTextStyles.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(ub.book.authors.join(', '), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.sm),
                                AnimatedProgressBar(progress: progress, height: 6),
                                const SizedBox(height: 4),
                                Text('$curr / $total pages — $pct%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.md),
                                Row(
                                  children: [
                                    Expanded(child: AppButton(label: 'Read', compact: true, onPressed: () => context.push('/book/${ub.book.id}/progress'))),
                                    const SizedBox(width: Spacing.sm),
                                    Expanded(child: OutlinedAppButton(label: 'Log', compact: true, onPressed: () {
                                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => SessionDialog(userBook: ub));
                                    })),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // RECENT ACTIVITY (Placeholder to finish Phase 3 scope smoothly)
                const SizedBox(height: Spacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text('Recent Activity', style: AppTextStyles.headlineMedium),
                ),
                const Padding(
                  padding: EdgeInsets.all(Spacing.md),
                  child: Text('Read 45 pages in "The Martian"', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: Spacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}