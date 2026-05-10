import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/user_book.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../providers/library_provider.dart';

class ShelfPickerBottomSheet extends ConsumerWidget {
  final Book book;

  const ShelfPickerBottomSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
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
              Text(
                'Add to Shelf',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              _buildOption(context, ref, '📖 Reading Now', ReadingStatus.reading),
              _buildOption(context, ref, '🔖 Want to Read', ReadingStatus.wantToRead),
              _buildOption(context, ref, '✅ Finished', ReadingStatus.finished),
              _buildOption(context, ref, '✗ Did Not Finish', ReadingStatus.dnf),
              const SizedBox(height: Spacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, String title, ReadingStatus status) {
    return ListTile(
      title: Text(title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
      shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
      onTap: () async {
        final user = ref.read(currentUserProvider);
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in first'), backgroundColor: AppColors.error),
          );
          return;
        }

        try {
          await ref.read(libraryRemoteDataSourceProvider).addBookToLibrary(user.id, book, status);
          
          // Log XP directly using supabase client for now
          // (Phase 3 will build proper XP UseCase)
          await ref.read(supabaseClientProvider).from('xp_log').insert({
            'user_id': user.id,
            'action': 'book_added',
            'xp_earned': 10,
          });

          // Invalidate relevant providers
          ref.invalidate(libraryWantToReadProvider);
          ref.invalidate(libraryReadingProvider);
          ref.invalidate(libraryFinishedProvider);
          ref.invalidate(libraryDnfProvider);

          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to your library ✓'), backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding to shelf: $e'), backgroundColor: AppColors.error),
            );
          }
        }
      },
    );
  }
}