import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/session_dialog.dart';

class ProgressScreen extends ConsumerWidget {
  final String bookId;

  const ProgressScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBooksAsync = ref.watch(libraryReadingProvider);
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: userBooksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(libraryReadingProvider)),
        data: (books) {
          final userBook = books.where((b) => b.book.id == bookId).firstOrNull;
          if (userBook == null) {
            return const EmptyStateView(
              icon: Icons.error_outline,
              title: 'Book not found',
              subtitle: 'This book is not in your Reading Now shelf',
            );
          }

          final book = userBook.book;
          final totalPages = userBook.totalPages ?? book.pageCount ?? 1;
          final currentPage = userBook.currentPage;
          final progress = currentPage / totalPages;
          final percent = (progress * 100).toStringAsFixed(1);
          
          final sessionsAsync = ref.watch(readingSessionsProvider(bookId));
          final speedAsync = ref.watch(readingSpeedProvider);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.surface,
                pinned: true,
                title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notes),
                    onPressed: () => context.push('/book/$bookId/notes'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BOOK HEADER
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: RadiusSize.sm,
                            child: CachedNetworkImage(
                              imageUrl: book.thumbnailUrl ?? '',
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
                                Text(book.title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
                                Text(book.authors.join(', '), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.amberMuted.withOpacity(0.3), borderRadius: RadiusSize.sm),
                                  child: Text('Reading Now', style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PROGRESS SECTION
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Page $currentPage of $totalPages', style: AppTextStyles.bodyMedium),
                              Text('$percent%', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          AnimatedProgressBar(progress: progress),
                          const SizedBox(height: Spacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              speedAsync.when(
                                data: (s) => StatCard(label: 'Speed', value: '${s.toInt()} pg/h'),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Speed', value: '-'),
                              ),
                              speedAsync.when(
                                data: (s) {
                                  final pagesLeft = totalPages - currentPage;
                                  final hrsLeft = s > 0 ? pagesLeft / s : 0;
                                  return StatCard(label: 'Time Left', value: hrsLeft > 0 ? '${hrsLeft.toStringAsFixed(1)}h' : '-');
                                },
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Time Left', value: '-'),
                              ),
                              sessionsAsync.when(
                                data: (list) => StatCard(label: 'Sessions', value: '${list.length}'),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Sessions', value: '-'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // SESSION BUTTON
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: AppButton(
                        label: '📖 Start Reading Session',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SessionDialog(userBook: userBook),
                          );
                        },
                      ),
                    ),

                    // STREAK BANNER
                    if (user?.userMetadata?['streak_current'] != null && user!.userMetadata!['streak_current'] > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(color: AppColors.purpleMuted, borderRadius: RadiusSize.md),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: Spacing.md),
                              Text('Day ${user.userMetadata!['streak_current']} streak — keep it up!', style: AppTextStyles.titleLarge),
                            ],
                          ),
                        ),
                      ),

                    // SESSION HISTORY
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Text('Reading Sessions', style: AppTextStyles.headlineMedium),
                    ),
                    sessionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(readingSessionsProvider)),
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(Spacing.md),
                            child: Text('No sessions logged yet. Tap "Start Reading Session" to begin!'),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceVariant),
                          itemBuilder: (context, i) {
                            final session = sessions[i];
                            final date = session.sessionDate;
                            final mins = (session.durationSecs / 60).round();
                            final speed = (session.pagesRead / (session.durationSecs / 3600)).round();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${date.month}/${date.day}/${date.year}', style: AppTextStyles.titleLarge),
                                      Text('Pages ${session.startPage} - ${session.endPage}', style: AppTextStyles.labelSmall),
                                    ],
                                  ),
                                  Text('${session.pagesRead} pages', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$mins min', style: AppTextStyles.bodyMedium),
                                      Text('$speed pg/hr', style: AppTextStyles.labelSmall),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}