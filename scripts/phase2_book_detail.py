import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── book_detail_screen.dart ────────────────────────────────────────────
w('lib/features/library/presentation/screens/book_detail_screen.dart', r"""
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/user_book.dart';
import '../providers/library_provider.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _descExpanded = false;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final userBookAsync = ref.watch(userBookByBookIdProvider(widget.book.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(),
                  const SizedBox(height: Spacing.md),
                  if (widget.book.categories.isNotEmpty) _buildGenreChips(),
                  const SizedBox(height: Spacing.md),
                  _buildDescription(),
                  const SizedBox(height: Spacing.lg),
                  userBookAsync.when(
                    loading: () => const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: AppColors.amber))),
                    error: (_, __) => _buildAddButton(null),
                    data: (userBook) => _buildAddButton(userBook),
                  ),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppColors.surface.withOpacity(0.85),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.book.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.book.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                  )
                : Container(color: AppColors.surfaceVariant),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow() {
    final b = widget.book;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.title, style: AppTextStyles.displayMedium).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 4),
        Text(b.authorsDisplay, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.amber))
            .animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 8),
        Row(
          children: [
            if (b.averageRating != null) ...[
              RatingStars(rating: b.averageRating!, size: 16),
              const SizedBox(width: 6),
              Text('${b.averageRating!.toStringAsFixed(1)}', style: AppTextStyles.bodyMedium),
              const SizedBox(width: 12),
            ],
            if (b.pageCount != null) ...[
              const Icon(Icons.menu_book, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('${b.pageCount} pages', style: AppTextStyles.bodyMedium),
              const SizedBox(width: 12),
            ],
            if (b.publishedDate != null)
              Text(b.publishedDate!.length >= 4 ? b.publishedDate!.substring(0, 4) : b.publishedDate!, style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildGenreChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.book.categories.take(4).map((cat) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.purpleMuted,
            borderRadius: RadiusSize.pill,
            border: Border.all(color: AppColors.purple.withOpacity(0.4)),
          ),
          child: Text(cat, style: AppTextStyles.labelSmall.copyWith(color: AppColors.purple)),
        );
      }).toList(),
    );
  }

  Widget _buildDescription() {
    final desc = widget.book.description ?? 'No description available.';
    final isLong = desc.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this book', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(desc.length > 220 ? '${desc.substring(0, 220)}…' : desc, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
          secondChild: Text(desc, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
          crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: 300.ms,
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _descExpanded ? 'Show less' : 'Read more',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton(UserBook? userBook) {
    if (userBook != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: RadiusSize.md,
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('In your library', style: AppTextStyles.titleLarge),
                      Text(userBook.status.label, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showStatusPicker(context, existingUserBook: userBook),
                  child: const Text('Change', style: TextStyle(color: AppColors.amber)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return AppButton(
      label: 'Add to My Shelf',
      icon: Icons.add,
      onPressed: () => _showStatusPicker(context),
      isLoading: _adding,
    );
  }

  void _showStatusPicker(BuildContext context, {UserBook? existingUserBook}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusPickerSheet(
        book: widget.book,
        existingUserBook: existingUserBook,
        onSelected: (status) async {
          Navigator.pop(context);
          setState(() => _adding = true);
          try {
            if (existingUserBook != null) {
              await ref.read(libraryReadingProvider.notifier).updateStatus(existingUserBook.id, status);
            } else {
              await ref.read(libraryReadingProvider.notifier).addBook(widget.book, status);
            }
            ref.invalidate(userBookByBookIdProvider(widget.book.id));
          } finally {
            if (mounted) setState(() => _adding = false);
          }
        },
      ),
    );
  }
}

class _StatusPickerSheet extends StatelessWidget {
  final Book book;
  final UserBook? existingUserBook;
  final ValueChanged<ReadingStatus> onSelected;

  const _StatusPickerSheet({required this.book, this.existingUserBook, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: RadiusSize.pill)),
          const SizedBox(height: Spacing.md),
          Text('Add to Shelf', style: AppTextStyles.headlineMedium),
          const SizedBox(height: Spacing.md),
          ...ReadingStatus.values.map((status) {
            final selected = existingUserBook?.status == status;
            return ListTile(
              leading: Icon(_statusIcon(status), color: selected ? AppColors.amber : AppColors.textSecondary),
              title: Text(status.label, style: AppTextStyles.bodyLarge.copyWith(color: selected ? AppColors.amber : AppColors.textPrimary)),
              trailing: selected ? const Icon(Icons.check, color: AppColors.amber, size: 20) : null,
              shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
              tileColor: selected ? AppColors.amberMuted.withOpacity(0.15) : null,
              onTap: () => onSelected(status),
            );
          }),
        ],
      ),
    );
  }

  IconData _statusIcon(ReadingStatus s) {
    switch (s) {
      case ReadingStatus.reading: return Icons.menu_book;
      case ReadingStatus.wantToRead: return Icons.bookmark_border;
      case ReadingStatus.finished: return Icons.check_circle_outline;
      case ReadingStatus.dnf: return Icons.cancel_outlined;
      case ReadingStatus.onHold: return Icons.pause_circle_outline;
    }
  }
}
""".strip())

print("✅ BookDetailScreen created.")
