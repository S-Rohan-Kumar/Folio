import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/book_search/domain/entities/book.dart';
import '../../features/library/domain/entities/user_book.dart';
import 'loading_shimmer.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final UserBook? userBook;
  final int animationIndex;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.userBook,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookCover(book: book, userBook: userBook),
          const SizedBox(height: 6),
          Text(
            book.title,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            book.authorsDisplay,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _BookCover extends StatefulWidget {
  final Book book;
  final UserBook? userBook;
  const _BookCover({required this.book, this.userBook});

  @override
  State<_BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<_BookCover> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: RadiusSize.md,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: widget.book.thumbnailUrl != null && widget.book.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.book.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity),
                        errorWidget: (_, __, ___) => _Placeholder(title: widget.book.title),
                      )
                    : _Placeholder(title: widget.book.title),
              ),
              // Progress overlay for currently reading books
              if (widget.userBook?.status == ReadingStatus.reading &&
                  widget.userBook!.progressPercent > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.amber,
                        AppColors.amber.withOpacity(0.6),
                      ]),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.userBook!.progressPercent,
                      child: Container(color: AppColors.amber),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}