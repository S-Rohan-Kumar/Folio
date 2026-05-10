import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/club.dart';
import '../providers/community_providers.dart';
import '../widgets/threads_list.dart';
import '../widgets/create_thread_sheet.dart';

class ClubDetailScreen extends ConsumerWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(clubDetailsProvider(club.id));
    final membersAsync = ref.watch(clubMembersProvider(club.id));
    final user = ref.watch(currentUserProvider);
    
    final displayClub = detailsAsync.value ?? club;
    final isOwner = user != null && displayClub.ownerId == user.id;
    final membersList = membersAsync.value ?? [];
    final isMember = membersList.any((m) => m.userId == user?.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // Show ClubSettingsSheet (simplified for spec)
                    _showSettings(context, displayClub, ref);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(displayClub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (displayClub.coverUrl != null)
                    CachedNetworkImage(imageUrl: displayClub.coverUrl!, fit: BoxFit.cover)
                  else
                    Container(color: AppColors.amberMuted, child: const Icon(Icons.groups, size: 64, color: AppColors.amber)),
                  Container(color: Colors.black.withOpacity(0.5)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayClub.description != null && displayClub.description!.isNotEmpty) ...[
                        Text(displayClub.description!, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: Spacing.sm),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text("${displayClub.memberCount} members", style: AppTextStyles.labelLarge),
                          const SizedBox(width: Spacing.md),
                          if (!displayClub.isPublic) ...[
                            const Icon(Icons.lock, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text("Private", style: AppTextStyles.labelLarge),
                          ] else ...[
                            const Icon(Icons.public, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text("Public", style: AppTextStyles.labelLarge),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // CURRENT BOOK
                if (displayClub.currentBook != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CURRENTLY READING", style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: RadiusSize.sm,
                              child: CachedNetworkImage(
                                imageUrl: displayClub.currentBook!.thumbnailUrl ?? '',
                                width: 40, height: 60, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, width: 40, height: 60),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayClub.currentBook!.title, style: AppTextStyles.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text(displayClub.currentBook!.authors.join(', '), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // MEMBERS
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Text("Members", style: AppTextStyles.headlineMedium),
                ),
                membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const SizedBox(),
                  data: (members) {
                    return SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        itemCount: members.length > 8 ? 9 : members.length,
                        itemBuilder: (context, i) {
                          if (i == 8) {
                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.surfaceVariant,
                              child: Text("+${members.length - 8}", style: const TextStyle(color: AppColors.amber, fontSize: 12)),
                            );
                          }
                          final m = members[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: m.displayName ?? m.username ?? 'Member',
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.purpleMuted,
                                backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                                child: m.avatarUrl == null ? Text((m.displayName ?? m.username ?? 'M')[0].toUpperCase(), style: const TextStyle(color: AppColors.purple)) : null,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: Spacing.md),

                // JOIN / LEAVE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: !isMember
                      ? AppButton(
                          label: "Join Club",
                          onPressed: () async {
                            if (!displayClub.isPublic) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Use the code button on Discover tab to join private clubs")));
                               return;
                            }
                            try {
                              await ref.read(joinClubUseCaseProvider)(displayClub.id);
                              ref.invalidate(clubMembersProvider(displayClub.id));
                              ref.invalidate(myClubsProvider);
                            } catch(e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          },
                        )
                      : (!isOwner ? OutlinedAppButton(
                          label: "Leave Club",
                          onPressed: () async {
                            try {
                              await ref.read(leaveClubUseCaseProvider)(displayClub.id);
                              ref.invalidate(clubMembersProvider(displayClub.id));
                              ref.invalidate(myClubsProvider);
                              if (context.mounted) context.pop();
                            } catch(e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          },
                        ) : const SizedBox()),
                ),
                const SizedBox(height: Spacing.md),
                const Divider(color: AppColors.surfaceVariant),

                // THREADS
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      Text("Discussions", style: AppTextStyles.headlineMedium),
                      const Spacer(),
                      if (isMember)
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.amber),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CreateThreadSheet(clubId: displayClub.id),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                ThreadsList(clubId: displayClub.id),
                const SizedBox(height: Spacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, Club c, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!c.isPublic && c.inviteCode != null)
              ListTile(
                leading: const Icon(Icons.key, color: AppColors.amber),
                title: const Text("Show Invite Code"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCodeDialog(context, c.inviteCode!);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text("Delete Club", style: TextStyle(color: AppColors.error)),
              onTap: () async {
                // Simplified for spec
                Navigator.pop(ctx);
                await ref.read(clubRepositoryProvider).deleteClub(c.id);
                ref.invalidate(myClubsProvider);
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text("Invite Code"),
        content: Text(code, style: AppTextStyles.displayMedium.copyWith(color: AppColors.amber, letterSpacing: 8)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
            },
            child: const Text("Copy"),
          ),
        ],
      ),
    );
  }
}