import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── Community Providers ────────────────────────────────────────────────
w('lib/features/community/presentation/providers/community_providers.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/battle_repository_impl.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/thread.dart';

// Clubs
final publicClubsProvider = FutureProvider<List<Club>>((ref) async {
  return ref.watch(clubRepositoryProvider).getPublicClubs();
});

final userClubsProvider = FutureProvider<List<Club>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(clubRepositoryProvider).getUserClubs(user.id);
});

// Threads
final recentThreadsProvider = FutureProvider<List<Thread>>((ref) async {
  return ref.watch(threadRepositoryProvider).getRecentThreads();
});

final clubThreadsProvider = FutureProvider.family<List<Thread>, String>((ref, clubId) async {
  return ref.watch(threadRepositoryProvider).getClubThreads(clubId);
});

final threadRepliesProvider = FutureProvider.family<List<ThreadReply>, String>((ref, threadId) async {
  return ref.watch(threadRepositoryProvider).getThreadReplies(threadId);
});

// Battles
final userBattlesProvider = FutureProvider<List<Battle>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(battleRepositoryProvider).getUserBattles(user.id);
});
""".strip())

# ── Community Screen ───────────────────────────────────────────────────
w('lib/features/community/presentation/screens/community_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/error_view.dart';
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
            icon: Icons.swords,
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
""".strip())

# ── Club Detail Screen ─────────────────────────────────────────────────
w('lib/features/community/presentation/screens/club_detail_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/club.dart';
import '../providers/community_providers.dart';

class ClubDetailScreen extends ConsumerWidget {
  final Club club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(clubThreadsProvider(club.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(club.name, style: AppTextStyles.titleLarge),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (club.description != null) ...[
                    Text(club.description!, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: Spacing.md),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.group, color: AppColors.textHint, size: 18),
                      const SizedBox(width: 8),
                      Text('${club.memberCount} members', style: AppTextStyles.labelLarge),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),
                  Text('Discussions', style: AppTextStyles.headlineMedium),
                ],
              ),
            ),
          ),
          threadsAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (threads) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => ListTile(
                  title: Text(threads[i].title, style: AppTextStyles.bodyLarge),
                  subtitle: Text('${threads[i].replyCount} replies'),
                ),
                childCount: threads.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
""".strip())

# ── Thread Detail Screen ───────────────────────────────────────────────
w('lib/features/community/presentation/screens/thread_detail_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../../domain/entities/thread.dart';
import '../providers/community_providers.dart';

class ThreadDetailScreen extends ConsumerStatefulWidget {
  final Thread thread;
  const ThreadDetailScreen({super.key, required this.thread});

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      await ref.read(threadRepositoryProvider).createReply(
        widget.thread.id,
        user.id,
        text,
        false,
      );
      _controller.clear();
      ref.invalidate(threadRepliesProvider(widget.thread.id));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(threadRepliesProvider(widget.thread.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Discussion', style: AppTextStyles.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Text(widget.thread.title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: Spacing.sm),
                Text(widget.thread.body, style: AppTextStyles.bodyLarge),
                const Divider(height: Spacing.xl, color: AppColors.surfaceVariant),
                repliesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (replies) => Column(
                    children: replies.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: RadiusSize.md),
                        child: Text(r.body, style: AppTextStyles.bodyMedium),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, MediaQuery.of(context).padding.bottom + Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Add a reply...',
                hintStyle: AppTextStyles.bodyMedium,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSending ? null : _sendReply,
            icon: _isSending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber))
                : const Icon(Icons.send, color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}
""".strip())

print("Phase 3 presentation layer generated successfully")
