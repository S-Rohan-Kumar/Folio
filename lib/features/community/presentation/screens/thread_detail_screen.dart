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