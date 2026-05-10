import 'package:flutter/material.dart';
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