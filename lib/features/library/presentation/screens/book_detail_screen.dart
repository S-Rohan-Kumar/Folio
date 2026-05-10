import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../../reviews/presentation/widgets/reviews_tab.dart';
import '../../../reviews/presentation/widgets/notes_tab.dart';
import '../../../community/presentation/widgets/book_community_tab.dart';
import '../widgets/shelf_picker_bottom_sheet.dart';
import '../providers/library_provider.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Determine if book is in library
    final reading = ref.watch(libraryReadingProvider).value ?? [];
    final want = ref.watch(libraryWantToReadProvider).value ?? [];
    final finished = ref.watch(libraryFinishedProvider).value ?? [];
    final dnf = ref.watch(libraryDnfProvider).value ?? [];
    
    final allLibraryBooks = [...reading, ...want, ...finished, ...dnf];
    final userBook = allLibraryBooks.where((ub) => ub.book.id == widget.book.id).firstOrNull;
    final isInLibrary = userBook != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.book.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: widget.book.thumbnailUrl!,
                          fit: BoxFit.cover,
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background,
                            ],
                            stops: [0.3, 1.0],
                          ),
                        ),
                      ),
                      Container(color: Colors.black.withOpacity(0.4)), // Darken
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: RadiusSize.md,
                            child: CachedNetworkImage(
                              imageUrl: widget.book.thumbnailUrl ?? '',
                              width: 80,
                              height: 120,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 80,
                                height: 120,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.book, color: AppColors.textHint, size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book.title,
                                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  widget.book.authors.isNotEmpty ? widget.book.authors.join(', ') : 'Unknown Author',
                                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.amber),
                                ),
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  '${widget.book.publisher ?? 'Unknown Publisher'} · ${widget.book.publishedDate?.split('-').first ?? 'Year'}',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  '${widget.book.pageCount ?? '?'} pages',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      if (widget.book.categories.isNotEmpty) ...[
                        Wrap(
                          spacing: Spacing.sm,
                          runSpacing: Spacing.sm,
                          children: widget.book.categories.take(3).map((c) => Chip(
                            label: Text(c, style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: AppColors.amber),
                          )).toList(),
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                      Row(
                        children: [
                          if (!isInLibrary)
                            Expanded(
                              child: AppButton(
                                label: 'Add to Shelf',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => ShelfPickerBottomSheet(book: widget.book),
                                  );
                                },
                              ),
                            )
                          else ...[
                            Expanded(
                              child: AppButton(
                                label: 'Continue Reading',
                                onPressed: () => context.push('/book/${widget.book.id}/progress'),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: OutlinedAppButton(
                                label: 'Change Shelf',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => ShelfPickerBottomSheet(book: widget.book),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Spacing.lg),
                      if (widget.book.description != null && widget.book.description!.isNotEmpty) ...[
                        InkWell(
                          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.book.description!,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                maxLines: _isDescriptionExpanded ? null : 3,
                                overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                _isDescriptionExpanded ? 'Read less' : 'Read more',
                                style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                      const Divider(color: AppColors.surfaceVariant),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.amber,
                    labelColor: AppColors.amber,
                    unselectedLabelColor: AppColors.textHint,
                    labelStyle: AppTextStyles.labelLarge,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'Reading Progress'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Notes'),
                      Tab(text: 'Community'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Tab 1: Reading Progress (Stub until Phase 3)
              const Center(child: Text('Progress Screen (Phase 3)', style: TextStyle(color: AppColors.textHint))),
              // Tab 2: Reviews
              ReviewsTab(bookId: widget.book.id),
              // Tab 3: Notes
              NotesTab(bookId: widget.book.id),
              // Tab 4: Community
              BookCommunityTab(bookId: widget.book.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool get overscroll => false;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}