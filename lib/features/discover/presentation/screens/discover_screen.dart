import 'dart:async';
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
import '../../../book_search/domain/entities/book.dart';
import '../../../book_search/presentation/providers/book_search_provider.dart';
import '../../../book_search/data/repositories/book_search_repository_impl.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.isEmpty) {
      ref.read(bookSearchNotifierProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(bookSearchNotifierProvider.notifier).search(q);
    });
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
            _buildSearchBar(),
            const SizedBox(height: Spacing.sm),
            Expanded(child: _buildBody()),
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
                Text('Discover', style: AppTextStyles.displayMedium),
                Text('Find your next great read', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          _ScanButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.lg,
          border: Border.all(
            color: _focused ? AppColors.amber.withOpacity(0.6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _controller,
          onChanged: _onSearch,
          onTap: () => setState(() => _focused = true),
          onTapOutside: (_) => setState(() => _focused = false),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search books, authors, ISBN…',
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 22),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                    onPressed: () {
                      _controller.clear();
                      ref.read(bookSearchNotifierProvider.notifier).clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final searchState = ref.watch(bookSearchNotifierProvider);
    final query = _controller.text.trim();

    if (query.isEmpty) return _buildDefaultState();

    return searchState.when(
      loading: () => const BookGridShimmer(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(bookSearchNotifierProvider.notifier).search(query),
      ),
      data: (books) => books.isEmpty ? _buildNoResults(query) : _buildResults(books),
    );
  }

  Widget _buildDefaultState() {
    final recents = ref.watch(recentSearchesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTextStyles.titleLarge),
                TextButton(
                  onPressed: () {
                    ref.read(bookLocalCacheProvider).clearRecentSearches();
                    ref.invalidate(recentSearchesProvider);
                  },
                  child: const Text('Clear', style: TextStyle(color: AppColors.textHint)),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ...recents.map((q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppColors.textHint, size: 20),
              title: Text(q, style: AppTextStyles.bodyLarge),
              trailing: const Icon(Icons.north_west, color: AppColors.textHint, size: 16),
              onTap: () {
                _controller.text = q;
                _onSearch(q);
              },
            )),
            const SizedBox(height: Spacing.lg),
          ],
          Text('Browse Genres', style: AppTextStyles.titleLarge),
          const SizedBox(height: Spacing.sm),
          _GenreGrid(
            onGenreSelected: (genreQuery) {
              _controller.text = genreQuery;
              _onSearch(genreQuery);
              setState(() => _focused = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.md,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) => BookCard(
        book: books[i],
        animationIndex: i,
        onTap: () => context.push('/book/${books[i].id}', extra: books[i]),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return EmptyStateView(
      icon: Icons.search_off,
      title: 'No results for "$query"',
      subtitle: 'Try a different title, author, or ISBN',
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scan'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.md,
          border: Border.all(color: AppColors.amber.withOpacity(0.3)),
        ),
        child: const Icon(Icons.qr_code_scanner, color: AppColors.amber, size: 22),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  final ValueChanged<String> onGenreSelected;

  const _GenreGrid({required this.onGenreSelected});

  final _genres = const [
    ('Fantasy', '🧙', Color(0xFF3D2E60)),
    ('Science Fiction', '🚀', Color(0xFF1A2E4A)),
    ('Mystery', '🔍', Color(0xFF2E1A1A)),
    ('Romance', '💕', Color(0xFF3D1A2E)),
    ('Non-Fiction', '📚', Color(0xFF1A3D2E)),
    ('Thriller', '⚡', Color(0xFF2E2E1A)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
        childAspectRatio: 2.5,
      ),
      itemCount: _genres.length,
      itemBuilder: (context, i) {
        final (name, emoji, color) = _genres[i];
        return GestureDetector(
          onTap: () => onGenreSelected('subject:$name'),
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: RadiusSize.md),
            child: Row(
              children: [
                const SizedBox(width: Spacing.md),
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: Spacing.sm),
                Text(name, style: AppTextStyles.titleLarge),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }
}