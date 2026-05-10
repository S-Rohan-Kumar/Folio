import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

w('lib/features/library/presentation/screens/library_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../domain/entities/user_book.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    (ReadingStatus.reading, 'Reading Now', Icons.menu_book),
    (ReadingStatus.wantToRead, 'Want to Read', Icons.bookmark),
    (ReadingStatus.finished, 'Finished', Icons.check_circle),
    (ReadingStatus.dnf, 'DNF', Icons.cancel),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
              child: Text('My Library', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
            ),
            Container(
              margin: const EdgeInsets.only(top: Spacing.md),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.amber,
                labelColor: AppColors.amber,
                unselectedLabelColor: AppColors.textHint,
                labelStyle: AppTextStyles.labelLarge,
                tabAlignment: TabAlignment.start,
                tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((t) => _LibraryTab(status: t.$1)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTab extends ConsumerWidget {
  final ReadingStatus status;
  const _LibraryTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _providerFor(status);
    final state = ref.watch(provider);

    return RefreshIndicator(
      color: AppColors.amber,
      backgroundColor: AppColors.surface,
      onRefresh: () async => ref.invalidate(provider),
      child: state.when(
        loading: () => const BookGridShimmer(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (books) => books.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmpty(context, status),
                ),
              )
            : GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Spacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: Spacing.sm,
                  mainAxisSpacing: Spacing.md,
                  childAspectRatio: 0.58,
                ),
                itemCount: books.length,
                itemBuilder: (context, i) => GestureDetector(
                  onLongPress: () {
                    // Show context menu here
                  },
                  child: BookCard(
                    book: books[i].book,
                    userBook: books[i],
                    animationIndex: i,
                    onTap: () => context.push('/book/${books[i].book.id}', extra: books[i].book),
                  ),
                ),
              ),
      ),
    );
  }

  AsyncNotifierProvider<LibraryNotifier, List<UserBook>> _providerFor(ReadingStatus s) {
    switch (s) {
      case ReadingStatus.reading: return libraryReadingProvider;
      case ReadingStatus.wantToRead: return libraryWantToReadProvider;
      case ReadingStatus.finished: return libraryFinishedProvider;
      case ReadingStatus.dnf: return libraryDnfProvider;
      default: return libraryReadingProvider;
    }
  }

  Widget _buildEmpty(BuildContext context, ReadingStatus status) {
    final (icon, title, subtitle) = switch (status) {
      ReadingStatus.reading => (Icons.menu_book_outlined, 'Nothing in progress', 'Find your next book 📖'),
      ReadingStatus.wantToRead => (Icons.bookmark_border, 'Your to-read list is empty', 'Add some books!'),
      ReadingStatus.finished => (Icons.emoji_events_outlined, 'No finished books yet', 'Keep reading! 🎉'),
      ReadingStatus.dnf => (Icons.cancel_outlined, 'Nothing here', 'You finish every book you start!'),
      _ => (Icons.book, 'Empty', 'No books found'),
    };

    return EmptyStateView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: status == ReadingStatus.reading || status == ReadingStatus.wantToRead
          ? TextButton.icon(
              onPressed: () => context.push('/discover'),
              icon: const Icon(Icons.search, color: AppColors.amber),
              label: const Text('Find a book', style: TextStyle(color: AppColors.amber)),
            )
          : null,
    );
  }
}
""".strip())

w('lib/features/library/presentation/screens/book_detail_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../book_search/domain/entities/book.dart';
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
              // Tab 2: Reviews (Stub until Phase 4)
              const Center(child: Text('Reviews (Phase 4)', style: TextStyle(color: AppColors.textHint))),
              // Tab 3: Notes (Stub until Phase 4)
              const Center(child: Text('Notes (Phase 4)', style: TextStyle(color: AppColors.textHint))),
              // Tab 4: Community (Placeholder)
              const Center(child: Text('Community discussions coming soon!', style: TextStyle(color: AppColors.textHint))),
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
""".strip())

print("Phase 2 library scripts generated successfully")
