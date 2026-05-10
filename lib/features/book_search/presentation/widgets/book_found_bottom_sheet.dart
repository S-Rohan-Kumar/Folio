import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../library/presentation/widgets/shelf_picker_bottom_sheet.dart';
import '../../domain/entities/book.dart';

class BookFoundBottomSheet extends StatelessWidget {
  final Book book;

  const BookFoundBottomSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: RadiusSize.md,
                    child: CachedNetworkImage(
                      imageUrl: book.thumbnailUrl ?? '',
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        height: 150,
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
                          book.title,
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          book.authors.isNotEmpty ? book.authors.join(', ') : 'Unknown Author',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.amber),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: [
                            if (book.pageCount != null) ...[
                              const Icon(Icons.menu_book, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${book.pageCount} p', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(width: Spacing.md),
                            ],
                            if (book.averageRating != null) ...[
                              const Icon(Icons.star, size: 14, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text('${book.averageRating}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              if (book.description != null && book.description!.isNotEmpty) ...[
                Text(
                  book.description!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.lg),
              ],
              AppButton(
                label: 'Add to Shelf',
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShelfPickerBottomSheet(book: book),
                  );
                },
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedAppButton(
                label: 'View Details',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/book/${book.id}', extra: book);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}