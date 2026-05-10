import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/community_providers.dart';

class MyClubsTab extends ConsumerWidget {
  const MyClubsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(myClubsProvider);

    return clubsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clubs) {
        if (clubs.isEmpty) {
          return EmptyStateView(
            icon: Icons.groups_outlined,
            title: "No clubs yet",
            subtitle: "Create one or discover clubs to join",
            action: AppButton(
              label: "Discover Clubs",
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: Spacing.sm),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
              child: ListTile(
                contentPadding: const EdgeInsets.all(Spacing.sm),
                leading: ClipRRect(
                  borderRadius: RadiusSize.sm,
                  child: CachedNetworkImage(
                    imageUrl: club.coverUrl ?? '',
                    width: 48, height: 48, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.amberMuted, width: 48, height: 48, child: const Icon(Icons.groups, color: AppColors.amber)),
                  ),
                ),
                title: Text(club.name, style: AppTextStyles.titleLarge),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${club.memberCount} members", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    if (club.currentBook != null)
                      Text("Reading: ${club.currentBook!.title}", style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                onTap: () => context.push('/club/${club.id}', extra: club),
              ),
            );
          },
        );
      },
    );
  }
}