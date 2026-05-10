import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/review_provider.dart';
import 'add_note_bottom_sheet.dart';

class NotesTab extends ConsumerWidget {
  final String bookId;

  const NotesTab({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(bookNotesProvider(bookId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.', style: TextStyle(color: AppColors.textHint)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                          child: Text(note.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.amber)),
                        ),
                        const SizedBox(width: Spacing.sm),
                        if (note.pageNumber != null)
                          Text('p. ${note.pageNumber}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        if (!note.isPublic)
                          const Icon(Icons.lock, size: 12, color: AppColors.textHint),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(note.content, style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add, color: AppColors.background),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddNoteBottomSheet(bookId: bookId),
          );
        },
      ),
    );
  }
}