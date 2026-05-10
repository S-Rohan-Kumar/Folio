import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/community_providers.dart';

class ThreadsList extends ConsumerWidget {
  final String? clubId;
  final String? bookId;

  const ThreadsList({super.key, this.clubId, this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = clubId != null ? clubThreadsProvider(clubId!) : bookPublicThreadsProvider(bookId!);
    final threadsAsync = ref.watch(provider);

    return threadsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(Spacing.xl), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(Spacing.xl), child: Text('Error: $e'))),
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Text("No discussions yet. Start one!", style: TextStyle(color: AppColors.textHint)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          itemCount: threads.length,
          itemBuilder: (context, index) {
            final t = threads[index];
            final timeAgo = DateTime.now().difference(t.createdAt);
            final timeStr = timeAgo.inDays > 0 ? '${timeAgo.inDays}d ago' : timeAgo.inHours > 0 ? '${timeAgo.inHours}h ago' : '${timeAgo.inMinutes}m ago';

            return GestureDetector(
              onTap: () => context.push('/thread/${t.id}', extra: t),
              child: Container(
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.purpleMuted,
                          backgroundImage: t.authorAvatarUrl != null ? NetworkImage(t.authorAvatarUrl!) : null,
                          child: t.authorAvatarUrl == null ? Text((t.authorUsername ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.purple)) : null,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.authorUsername ?? 'User', style: AppTextStyles.labelLarge),
                            Text(timeStr, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                          ],
                        ),
                        const Spacer(),
                        if (t.hasSpoilers)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.amberMuted, borderRadius: BorderRadius.circular(4)),
                            child: Text("SPOILERS", style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(t.title, style: AppTextStyles.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Spacing.xs),
                    Text(t.body, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text("${t.replyCount} replies", style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}