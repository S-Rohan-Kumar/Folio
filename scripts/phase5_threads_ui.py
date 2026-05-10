import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. THREADS LIST & CREATE
# ==========================================

w('lib/features/community/presentation/widgets/threads_list.dart', r"""
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
""".strip())

w('lib/features/community/presentation/widgets/create_thread_sheet.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/community_providers.dart';

class CreateThreadSheet extends ConsumerStatefulWidget {
  final String? bookId;
  final String? clubId;

  const CreateThreadSheet({super.key, this.bookId, this.clubId});

  @override
  ConsumerState<CreateThreadSheet> createState() => _CreateThreadSheetState();
}

class _CreateThreadSheetState extends ConsumerState<CreateThreadSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _hasSpoilers = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createThread() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(createThreadUseCaseProvider)(CreateThreadParams(
        bookId: widget.bookId,
        clubId: widget.clubId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        hasSpoilers: _hasSpoilers,
      ));

      await ref.read(logXpUseCaseProvider)('thread_created', 10);
      
      if (widget.clubId != null) ref.invalidate(clubThreadsProvider(widget.clubId!));
      if (widget.bookId != null) ref.invalidate(bookPublicThreadsProvider(widget.bookId!));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Discussion posted ✓"), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: Spacing.md),
                decoration: BoxDecoration(color: AppColors.elevated, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text("New Discussion", style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            
            AppTextField(label: "Title *", controller: _titleController, maxLength: 100),
            const SizedBox(height: Spacing.md),
            
            AppTextField(
              label: "What's on your mind?",
              controller: _bodyController,
              maxLines: 8,
              maxLength: 5000,
            ),
            const SizedBox(height: Spacing.md),
            
            SwitchListTile(
              title: const Text("Contains spoilers", style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text("Post will be blurred for readers", style: TextStyle(color: AppColors.textSecondary)),
              value: _hasSpoilers,
              activeColor: AppColors.amber,
              onChanged: (val) => setState(() => _hasSpoilers = val),
            ),
            const SizedBox(height: Spacing.lg),
            
            AppButton(
              label: "Post Discussion",
              isLoading: _isSaving,
              onPressed: _createThread,
            ),
          ],
        ),
      ),
    );
  }
}
""".strip())

# ==========================================
# 2. THREAD DETAIL (REALTIME)
# ==========================================

w('lib/features/community/presentation/screens/thread_detail_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/thread.dart';
import '../providers/community_providers.dart';
import '../widgets/reply_card.dart';

class ThreadDetailScreen extends ConsumerStatefulWidget {
  final Thread thread; // Base data passed from list
  const ThreadDetailScreen({super.key, required this.thread});

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ThreadReply? _replyingTo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setReplyingTo(ThreadReply reply) {
    setState(() => _replyingTo = reply);
    // Focus keyboard conceptually
  }

  void _clearReplyingTo() {
    setState(() => _replyingTo = null);
  }

  Future<void> _submitReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(createReplyUseCaseProvider)(CreateReplyParams(
        threadId: widget.thread.id,
        body: body,
        parentReplyId: _replyingTo?.id,
        hasSpoilers: false, // Could add toggle
      ));

      await ref.read(incrementReplyCountUseCaseProvider)(widget.thread.id);
      
      _replyController.clear();
      _clearReplyingTo();

      // Scroll to bottom (wait a tick for Realtime to propagate)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(threadRepliesProvider(widget.thread.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.thread.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ORIGINAL POST
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(Spacing.md),
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.purpleMuted,
                              backgroundImage: widget.thread.authorAvatarUrl != null ? NetworkImage(widget.thread.authorAvatarUrl!) : null,
                              child: widget.thread.authorAvatarUrl == null ? Text((widget.thread.authorUsername ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.purple)) : null,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.thread.authorUsername ?? 'User', style: AppTextStyles.labelLarge),
                                Text(widget.thread.createdAt.toLocal().toString().split('.')[0], style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.md),
                        Text(widget.thread.title, style: AppTextStyles.headlineMedium),
                        const SizedBox(height: Spacing.sm),
                        
                        // Body
                        if (widget.thread.hasSpoilers)
                          _SpoilerThreadWidget(text: widget.thread.body)
                        else
                          Text(widget.thread.body, style: AppTextStyles.bodyLarge),
                          
                        const SizedBox(height: Spacing.md),
                        const Divider(color: AppColors.surfaceVariant),
                        Text("${widget.thread.replyCount} replies", style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ),

                // REALTIME REPLIES
                repliesAsync.when(
                  loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(Spacing.xl), child: CircularProgressIndicator()))),
                  error: (e, _) => SliverToBoxAdapter(child: ErrorView(message: e.toString())),
                  data: (replies) {
                    if (replies.isEmpty) {
                      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(Spacing.xl), child: Text("No replies yet. Be the first!", style: TextStyle(color: AppColors.textHint)))));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => ReplyCard(
                          reply: replies[i],
                          onReply: () => _setReplyingTo(replies[i]),
                        ),
                        childCount: replies.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // REPLY INPUT AREA
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.sm, Spacing.sm + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyingTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.only(left: Spacing.sm),
                    decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.amber, width: 2))),
                    child: Row(
                      children: [
                        Expanded(child: Text("Replying to @${_replyingTo!.authorUsername}", style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                          onPressed: _clearReplyingTo,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: "Add a reply...",
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _replyController.text.trim().isEmpty || _isSubmitting
                          ? const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send, color: AppColors.textHint))
                          : IconButton(
                              icon: const Icon(Icons.send, color: AppColors.amber),
                              onPressed: _submitReply,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reuse spoiler logic
import 'dart:ui';
class _SpoilerThreadWidget extends StatefulWidget {
  final String text;
  const _SpoilerThreadWidget({required this.text});
  @override
  State<_SpoilerThreadWidget> createState() => _SpoilerThreadWidgetState();
}
class _SpoilerThreadWidgetState extends State<_SpoilerThreadWidget> {
  bool _isHidden = true;
  @override
  Widget build(BuildContext context) {
    if (!_isHidden) return Text(widget.text, style: AppTextStyles.bodyLarge);
    return GestureDetector(
      onTap: () => setState(() => _isHidden = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Text(widget.text, style: AppTextStyles.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
            child: const Text('SPOILER - TAP TO REVEAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
""".strip())

w('lib/features/community/presentation/widgets/reply_card.dart', r"""
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/thread.dart';

class ReplyCard extends StatelessWidget {
  final ThreadReply reply;
  final VoidCallback onReply;

  const ReplyCard({super.key, required this.reply, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isNested = reply.parentReplyId != null;
    
    final timeAgo = DateTime.now().difference(reply.createdAt);
    final timeStr = timeAgo.inDays > 0 ? '${timeAgo.inDays}d' : timeAgo.inHours > 0 ? '${timeAgo.inHours}h' : '${timeAgo.inMinutes}m';

    return Padding(
      padding: EdgeInsets.only(
        top: Spacing.sm,
        bottom: Spacing.sm,
        left: isNested ? 56.0 : Spacing.md,
        right: Spacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNested)
            Container(
              width: 2,
              height: 40,
              color: AppColors.elevated,
              margin: const EdgeInsets.only(right: Spacing.sm),
            ),
            
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.purpleMuted,
            backgroundImage: reply.authorAvatarUrl != null ? NetworkImage(reply.authorAvatarUrl!) : null,
            child: reply.authorAvatarUrl == null ? Text((reply.authorUsername ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.purple)) : null,
          ),
          const SizedBox(width: Spacing.sm),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(reply.authorUsername ?? 'User', style: AppTextStyles.labelLarge),
                          const SizedBox(width: Spacing.sm),
                          Text(timeStr, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (reply.hasSpoilers)
                        _SpoilerReplyWidget(text: reply.body)
                      else
                        Text(reply.body, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: GestureDetector(
                    onTap: onReply,
                    child: Text("Reply", style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpoilerReplyWidget extends StatefulWidget {
  final String text;
  const _SpoilerReplyWidget({required this.text});
  @override
  State<_SpoilerReplyWidget> createState() => _SpoilerReplyWidgetState();
}
class _SpoilerReplyWidgetState extends State<_SpoilerReplyWidget> {
  bool _isHidden = true;
  @override
  Widget build(BuildContext context) {
    if (!_isHidden) return Text(widget.text, style: AppTextStyles.bodyMedium);
    return GestureDetector(
      onTap: () => setState(() => _isHidden = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Text(widget.text, style: AppTextStyles.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
            child: const Text('SPOILER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
""".strip())

print("Phase 5 threads UI generated successfully")
