import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/book_search_provider.dart';
import '../widgets/book_found_bottom_sheet.dart';

class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      ref.read(bookSearchNotifierProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(bookSearchNotifierProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(bookSearchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by title, author, or ISBN',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textHint),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _searchCtrl.text.isEmpty
          ? const EmptyStateView(
              icon: Icons.search,
              title: 'Search Books',
              subtitle: 'Find your next great read by title, author, or ISBN',
            )
          : searchState.when(
              loading: () => const BookGridShimmer(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => _onSearchChanged(_searchCtrl.text),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No results found',
                    subtitle: 'No books found for "${_searchCtrl.text}"',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(Spacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: Spacing.md,
                    mainAxisSpacing: Spacing.md,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      animationIndex: index,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BookFoundBottomSheet(book: book),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.qr_code_scanner, color: AppColors.background),
      ),
    );
  }
}