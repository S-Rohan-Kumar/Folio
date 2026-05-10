import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. PROVIDERS
# ==========================================

w('lib/features/community/presentation/providers/community_providers.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/thread.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../../../reviews/data/repositories/review_repository_impl.dart';

final clubRepositoryProvider = Provider((ref) => ClubRepositoryImpl(ref.watch(supabaseClientProvider)));
final threadRepositoryProvider = Provider((ref) => ThreadRepositoryImpl(ref.watch(supabaseClientProvider)));

// Clubs
final myClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getMyClubs(user.id);
});

final discoverClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getDiscoverClubs(user.id);
});

final clubDetailsProvider = FutureProvider.family<Club, String>((ref, clubId) async {
  return ref.watch(clubRepositoryProvider).getClubDetails(clubId);
});

final clubMembersProvider = FutureProvider.family<List<ClubMember>, String>((ref, clubId) async {
  return ref.watch(clubRepositoryProvider).getClubMembers(clubId);
});

// Threads
final clubThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, clubId) async {
  return ref.watch(threadRepositoryProvider).getThreads(clubId: clubId);
});

final bookPublicThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, bookId) async {
  return ref.watch(threadRepositoryProvider).getThreads(bookId: bookId);
});

final threadDetailsProvider = FutureProvider.family<Thread, String>((ref, threadId) async {
  return ref.watch(threadRepositoryProvider).getThreadDetails(threadId);
});

// CRITICAL: Realtime Stream Provider
final threadRepliesProvider = StreamProvider.family<List<ThreadReply>, String>((ref, threadId) {
  return ref.watch(threadRepositoryProvider).watchReplies(threadId);
});

// Actions (Use Cases via Riverpod)
class CreateClubParams {
  final String name;
  final String? description;
  final bool isPublic;
  final String? inviteCode;
  final String? currentBookId;

  CreateClubParams({required this.name, this.description, required this.isPublic, this.inviteCode, this.currentBookId});
}

final createClubUseCaseProvider = Provider((ref) {
  return (CreateClubParams params) async {
    final user = ref.read(currentUserProvider)!;
    final club = Club(
      id: '', name: params.name, description: params.description,
      ownerId: user.id, isPublic: params.isPublic, inviteCode: params.inviteCode,
      currentBookId: params.currentBookId, memberCount: 1, createdAt: DateTime.now(),
    );
    return ref.read(clubRepositoryProvider).createClub(club);
  };
});

final joinClubUseCaseProvider = Provider((ref) {
  return (String clubId, {String? inviteCode}) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(clubRepositoryProvider).joinClub(user.id, clubId, inviteCode: inviteCode);
  };
});

final leaveClubUseCaseProvider = Provider((ref) {
  return (String clubId) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(clubRepositoryProvider).leaveClub(user.id, clubId);
  };
});

class CreateThreadParams {
  final String? bookId;
  final String? clubId;
  final String title;
  final String body;
  final bool hasSpoilers;

  CreateThreadParams({this.bookId, this.clubId, required this.title, required this.body, required this.hasSpoilers});
}

final createThreadUseCaseProvider = Provider((ref) {
  return (CreateThreadParams params) async {
    final user = ref.read(currentUserProvider)!;
    final thread = Thread(
      id: '', authorId: user.id, bookId: params.bookId, clubId: params.clubId,
      title: params.title, body: params.body, hasSpoilers: params.hasSpoilers,
      replyCount: 0, createdAt: DateTime.now(),
    );
    await ref.read(threadRepositoryProvider).createThread(thread);
  };
});

class CreateReplyParams {
  final String threadId;
  final String body;
  final String? parentReplyId;
  final bool hasSpoilers;

  CreateReplyParams({required this.threadId, required this.body, this.parentReplyId, required this.hasSpoilers});
}

final createReplyUseCaseProvider = Provider((ref) {
  return (CreateReplyParams params) async {
    final user = ref.read(currentUserProvider)!;
    final reply = ThreadReply(
      id: '', threadId: params.threadId, authorId: user.id, body: params.body,
      hasSpoilers: params.hasSpoilers, parentReplyId: params.parentReplyId, createdAt: DateTime.now(),
    );
    await ref.read(threadRepositoryProvider).createReply(reply);
  };
});

final incrementReplyCountUseCaseProvider = Provider((ref) {
  return (String threadId) async {
    await ref.read(threadRepositoryProvider).incrementReplyCount(threadId);
  };
});

// Export XP log
final logXpUseCaseProvider = Provider((ref) {
  return (String action, int xp) async {
    final user = ref.read(currentUserProvider)!;
    await ref.read(reviewRepositoryProvider).logXp(user.id, action, xp);
  };
});
""".strip())

# ==========================================
# 2. COMMUNITY SCREEN & TABS
# ==========================================

w('lib/features/community/presentation/screens/community_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/my_clubs_tab.dart';
import '../widgets/discover_clubs_tab.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text('Community', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
                pinned: true,
                backgroundColor: AppColors.background,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.amber),
                    onPressed: () => context.push('/club/create'),
                  ),
                ],
                bottom: const TabBar(
                  tabs: [Tab(text: "My Clubs"), Tab(text: "Discover")],
                  indicatorColor: AppColors.amber,
                  labelColor: AppColors.amber,
                  unselectedLabelColor: AppColors.textSecondary,
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              MyClubsTab(),
              DiscoverClubsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
""".strip())

w('lib/features/community/presentation/widgets/my_clubs_tab.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
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
""".strip())

w('lib/features/community/presentation/widgets/discover_clubs_tab.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/community_providers.dart';

class DiscoverClubsTab extends ConsumerStatefulWidget {
  const DiscoverClubsTab({super.key});

  @override
  ConsumerState<DiscoverClubsTab> createState() => _DiscoverClubsTabState();
}

class _DiscoverClubsTabState extends ConsumerState<DiscoverClubsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showJoinPrivateClubDialog() {
    final codeCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceVariant,
          title: Text("Join Private Club", style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter the 8-character invite code:", style: AppTextStyles.bodyMedium),
              const SizedBox(height: Spacing.md),
              AppTextField(
                label: "Invite Code",
                controller: codeCtrl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            ),
            AppButton(
              label: "Join",
              compact: true,
              isLoading: isLoading,
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;

                setState(() => isLoading = true);
                try {
                  // Wait, to join by code we need the clubId. 
                  // In this spec, the prompt says JoinClubUseCase takes code. But we don't know the ID!
                  // Let's modify join logic to look up by code if no ID is passed.
                  // For now, let's use supabase direct to find club ID by code
                  final client = ref.read(supabaseClientProvider);
                  final data = await client.from('clubs').select('id, name').eq('invite_code', code).eq('is_public', false).maybeSingle();
                  
                  if (data == null) {
                    throw Exception("Invalid invite code. Check with the club owner.");
                  }
                  
                  await ref.read(joinClubUseCaseProvider)(data['id'], inviteCode: code);
                  ref.invalidate(myClubsProvider);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined ${data['name']}! 🎉"), backgroundColor: AppColors.success));
                    context.push('/club/${data['id']}');
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(discoverClubsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: "Search clubs",
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              OutlinedAppButton(
                label: "Code",
                compact: true,
                onPressed: _showJoinPrivateClubDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: clubsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (clubs) {
              final filtered = clubs.where((c) => c.name.toLowerCase().contains(_query)).toList();
              
              if (filtered.isEmpty) {
                return const Center(child: Text("No public clubs found."));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final club = filtered[index];
                  return _DiscoverClubCard(club: club);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoverClubCard extends ConsumerStatefulWidget {
  final Club club;
  const _DiscoverClubCard({required this.club});

  @override
  ConsumerState<_DiscoverClubCard> createState() => _DiscoverClubCardState();
}

class _DiscoverClubCardState extends ConsumerState<_DiscoverClubCard> {
  bool _isJoining = false;
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Spacing.sm),
        leading: ClipRRect(
          borderRadius: RadiusSize.sm,
          child: CachedNetworkImage(
            imageUrl: widget.club.coverUrl ?? '',
            width: 48, height: 48, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: AppColors.amberMuted, width: 48, height: 48, child: const Icon(Icons.groups, color: AppColors.amber)),
          ),
        ),
        title: Text(widget.club.name, style: AppTextStyles.titleLarge),
        subtitle: Text("${widget.club.memberCount} members", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        trailing: _joined
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : OutlinedAppButton(
                label: "Join",
                compact: true,
                onPressed: _isJoining ? null : () async {
                  setState(() => _isJoining = true);
                  try {
                    await ref.read(joinClubUseCaseProvider)(widget.club.id);
                    ref.invalidate(myClubsProvider);
                    ref.invalidate(discoverClubsProvider);
                    
                    if (mounted) {
                      setState(() { _isJoining = false; _joined = true; });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined ${widget.club.name}! 🎉"), backgroundColor: AppColors.success));
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isJoining = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
                    }
                  }
                },
              ),
        onTap: () => context.push('/club/${widget.club.id}', extra: widget.club),
      ),
    );
  }
}
""".strip())

print("Phase 5 providers and community screen generated successfully")
