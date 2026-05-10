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