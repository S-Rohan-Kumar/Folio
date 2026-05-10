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