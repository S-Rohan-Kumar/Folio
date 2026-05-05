import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/book_card.dart';
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
    (ReadingStatus.reading, 'Reading', Icons.menu_book),
    (ReadingStatus.wantToRead, 'Want to Read', Icons.bookmark),
    (ReadingStatus.finished, 'Finished', Icons.check_circle),
    (ReadingStatus.dnf, 'DNF', Icons.cancel),
    (ReadingStatus.onHold, 'On Hold', Icons.pause_circle),
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
            _buildHeader(),
            _buildTabBar(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Library', style: AppTextStyles.displayMedium),
                Text('Your reading journey', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/discover'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: RadiusSize.md),
              child: const Icon(Icons.add, color: AppColors.amber, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      height: 42,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.amber,
        indicatorWeight: 2,
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
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

    return state.when(
      loading: () => const BookGridShimmer(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
      data: (books) => books.isEmpty
          ? _buildEmpty(context, status)
          : GridView.builder(
              padding: const EdgeInsets.all(Spacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: Spacing.sm,
                mainAxisSpacing: Spacing.md,
                childAspectRatio: 0.58,
              ),
              itemCount: books.length,
              itemBuilder: (context, i) => BookCard(
                book: books[i].book,
                userBook: books[i],
                animationIndex: i,
                onTap: () => context.push('/book/${books[i].book.id}', extra: books[i].book),
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
      case ReadingStatus.onHold: return libraryOnHoldProvider;
    }
  }

  Widget _buildEmpty(BuildContext context, ReadingStatus status) {
    final (icon, title, subtitle) = switch (status) {
      ReadingStatus.reading => (Icons.menu_book_outlined, 'Nothing here yet', 'Start a book and track your progress'),
      ReadingStatus.wantToRead => (Icons.bookmark_border, 'Your wishlist is empty', 'Add books you want to read'),
      ReadingStatus.finished => (Icons.emoji_events_outlined, 'No finished books yet', 'Finish your first book!'),
      ReadingStatus.dnf => (Icons.cancel_outlined, 'No abandoned books', 'Great — you finish everything you start!'),
      ReadingStatus.onHold => (Icons.pause_circle_outline, 'Nothing on hold', 'Taking a break? Put a book on hold here'),
    };

    return EmptyStateView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: TextButton.icon(
        onPressed: () => context.push('/discover'),
        icon: const Icon(Icons.search, color: AppColors.amber),
        label: const Text('Find a book', style: TextStyle(color: AppColors.amber)),
      ),
    );
  }
}