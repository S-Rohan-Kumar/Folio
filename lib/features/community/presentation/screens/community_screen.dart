import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ClubsTab(),
                  _DiscussionsTab(),
                  _BattlesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.amber,
        onPressed: () => _showCreateClubDialog(context),
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('Create Club', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.amber,
        onPressed: () => _showCreateThreadDialog(context),
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('New Thread', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  void _showCreateClubDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Create a Club', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Club Name', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null || nameCtrl.text.isEmpty) return;
                await ref.read(clubRepositoryProvider).createClub(nameCtrl.text, descCtrl.text, user.id, true);
                ref.invalidate(publicClubsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateThreadDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    // In a real app, you'd select a book to attach the thread to. Using a placeholder for now.
    final bookId = 'placeholder_book_id';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Start Discussion', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Body', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null || titleCtrl.text.isEmpty) return;
                await ref.read(threadRepositoryProvider).createThread(bookId, null, user.id, titleCtrl.text, bodyCtrl.text, false);
                ref.invalidate(recentThreadsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Post', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Text('Community', style: AppTextStyles.displayMedium),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.amber,
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: 'Clubs'),
          Tab(text: 'Discussions'),
          Tab(text: 'Battles'),
        ],
      ),
    );
  }
}

class _ClubsTab extends ConsumerWidget {
  const _ClubsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(publicClubsProvider);

    return clubsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(publicClubsProvider)),
      data: (clubs) {
        if (clubs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.groups,
            title: 'No Clubs Found',
            subtitle: 'Be the first to start a reading club!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: clubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, i) {
            final c = clubs[i];
            return ListTile(
              contentPadding: const EdgeInsets.all(Spacing.sm),
              shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
              tileColor: AppColors.surfaceVariant,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.purpleMuted, borderRadius: RadiusSize.sm),
                child: const Icon(Icons.menu_book, color: AppColors.purple),
              ),
              title: Text(c.name, style: AppTextStyles.titleLarge),
              subtitle: Text('${c.memberCount} members', style: AppTextStyles.bodyMedium),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => context.push('/club/${c.id}', extra: c),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1);
          },
        );
      },
    );
  }
}

class _DiscussionsTab extends ConsumerWidget {
  const _DiscussionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(recentThreadsProvider);

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(recentThreadsProvider)),
      data: (threads) {
        if (threads.isEmpty) {
          return const EmptyStateView(
            icon: Icons.forum,
            title: 'No Discussions',
            subtitle: 'Start a conversation about a book!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceVariant),
          itemBuilder: (context, i) {
            final t = threads[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.title, style: AppTextStyles.titleLarge),
              subtitle: Text('${t.replyCount} replies', style: AppTextStyles.bodyMedium),
              onTap: () => context.push('/thread/${t.id}', extra: t),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
          },
        );
      },
    );
  }
}

class _BattlesTab extends ConsumerWidget {
  const _BattlesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battlesAsync = ref.watch(userBattlesProvider);

    return battlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(userBattlesProvider)),
      data: (battles) {
        if (battles.isEmpty) {
          return const EmptyStateView(
            icon: Icons.sports_martial_arts,
            title: 'No Active Battles',
            subtitle: 'Challenge a friend to a reading race!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: battles.length,
          itemBuilder: (context, i) {
            final b = battles[i];
            return Card(
              color: AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Battle vs ${b.rivalId.substring(0, 5)}...', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: b.challengerPage / (b.challengerPage + b.rivalPage + 1),
                      backgroundColor: AppColors.purpleMuted,
                      color: AppColors.amber,
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