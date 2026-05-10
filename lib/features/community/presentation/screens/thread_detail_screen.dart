import 'dart:ui';
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