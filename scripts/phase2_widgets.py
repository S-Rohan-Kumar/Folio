import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── shared/widgets/app_button.dart ─────────────────────────────────────
w('lib/shared/widgets/app_button.dart', r"""
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final isSecondary = variant == AppButtonVariant.secondary;

    return SizedBox(
      height: 52,
      width: width,
      child: AnimatedScale(
        scale: onPressed == null ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: isSecondary
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                child: _buildChild(AppColors.amber),
              )
            : variant == AppButtonVariant.ghost
                ? TextButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _buildChild(AppColors.amber),
                  )
                : ElevatedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _buildChild(AppColors.background),
                  ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Text(label, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold));
  }
}
""".strip())

# ── shared/widgets/rating_stars.dart ──────────────────────────────────
w('lib/shared/widgets/rating_stars.dart', r"""
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = rating >= i + 1;
        final half = !full && rating >= i + 0.5;
        final icon = full ? Icons.star : (half ? Icons.star_half : Icons.star_border);
        if (interactive) {
          return GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final local = box.globalToLocal(d.globalPosition);
                final starWidth = size + 2;
                final starIndex = (local.dx / starWidth).floor();
                final isLeft = (local.dx % starWidth) < starWidth / 2;
                onRatingChanged?.call(isLeft ? starIndex + 0.5 : starIndex + 1.0);
              }
            },
            child: Icon(icon, size: size, color: AppColors.amber),
          );
        }
        return Icon(icon, size: size, color: AppColors.amber);
      }),
    );
  }
}
""".strip())

# ── shared/widgets/loading_shimmer.dart ───────────────────────────────
w('lib/shared/widgets/loading_shimmer.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius ?? RadiusSize.md,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 1200.ms,
      color: AppColors.elevated.withOpacity(0.8),
    );
  }
}

class BookCardShimmer extends StatelessWidget {
  const BookCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: double.infinity, height: 180, borderRadius: RadiusSize.md),
        const SizedBox(height: 8),
        ShimmerBox(width: double.infinity, height: 14),
        const SizedBox(height: 4),
        ShimmerBox(width: 80, height: 12),
      ],
    );
  }
}

class BookGridShimmer extends StatelessWidget {
  final int count;
  const BookGridShimmer({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
        childAspectRatio: 0.6,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const BookCardShimmer(),
    );
  }
}
""".strip())

# ── shared/widgets/error_view.dart ─────────────────────────────────────
w('lib/shared/widgets/error_view.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textHint)
                .animate().scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(label: 'Try Again', onPressed: onRetry, icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint)
                .animate().scale(begin: const Offset(0.5, 0.5)).fadeIn(),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 200.ms),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!.animate().fadeIn(delay: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}
""".strip())

# ── shared/widgets/book_card.dart ──────────────────────────────────────
w('lib/shared/widgets/book_card.dart', r"""
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
""".strip())

print("✅ Shared widgets created.")
