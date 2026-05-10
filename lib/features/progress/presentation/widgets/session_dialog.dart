import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../providers/session_timer_provider.dart';
import '../providers/progress_provider.dart';
import '../../data/repositories/progress_repository_impl.dart';

class SessionDialog extends ConsumerStatefulWidget {
  final UserBook userBook;

  const SessionDialog({super.key, required this.userBook});

  @override
  ConsumerState<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends ConsumerState<SessionDialog> with WidgetsBindingObserver {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCtrl = TextEditingController(text: widget.userBook.currentPage.toString());
    _endCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    
    // Auto-start timer if not running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(sessionTimerNotifierProvider).isRunning) {
        ref.read(sessionTimerNotifierProvider.notifier).start();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startCtrl.dispose();
    _endCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(sessionTimerNotifierProvider.notifier).pause();
    }
  }

  Future<void> _saveSession() async {
    final start = int.tryParse(_startCtrl.text) ?? widget.userBook.currentPage;
    final end = int.tryParse(_endCtrl.text);
    
    if (end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an end page')));
      return;
    }
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End page must be > start page')));
      return;
    }
    final total = widget.userBook.totalPages ?? widget.userBook.book.pageCount ?? 9999;
    if (end > total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End page exceeds total pages!')));
      return;
    }

    final pagesRead = end - start;
    final xpEarned = (pagesRead / 10).floor().clamp(1, 999);
    final user = ref.read(currentUserProvider)!;
    final timerState = ref.read(sessionTimerNotifierProvider);

    try {
      await ref.read(progressRepositoryProvider).saveReadingSession(
        userId: user.id,
        bookId: widget.userBook.book.id,
        startPage: start,
        endPage: end,
        durationSecs: timerState.elapsed.inSeconds,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );

      await ref.read(progressRepositoryProvider).logXp(user.id, 'session_logged', xpEarned);

      ref.read(sessionTimerNotifierProvider.notifier).reset();
      
      // Invalidate providers
      ref.invalidate(readingSessionsProvider(widget.userBook.book.id));
      ref.invalidate(readingSpeedProvider);
      ref.invalidate(libraryReadingProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('📖 '),
                Text('$pagesRead pages in ${timerState.elapsed.inMinutes} min · +$xpEarned XP earned'),
              ],
            ),
            backgroundColor: AppColors.surface,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sessionTimerNotifierProvider);
    final String timerText = '${timerState.elapsed.inHours.toString().padLeft(2, '0')}:'
        '${(timerState.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(timerState.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
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
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.elevated, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text('Reading Session', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: Spacing.lg),

              // TIMER
              Center(
                child: Text(timerText, style: AppTextStyles.displayLarge.copyWith(color: AppColors.amber)),
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (timerState.isRunning)
                    OutlinedAppButton(label: 'Pause', compact: true, onPressed: () => ref.read(sessionTimerNotifierProvider.notifier).pause())
                  else
                    OutlinedAppButton(label: 'Resume', compact: true, onPressed: () => ref.read(sessionTimerNotifierProvider.notifier).resume()),
                ],
              ),
              const SizedBox(height: Spacing.lg),

              // PAGE INPUTS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Started at', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        AppTextField(label: '', controller: _startCtrl, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finished at', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        AppTextField(label: 'End page', hint: 'End page', controller: _endCtrl, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // NOTES
              AppTextField(label: 'Session note (optional)', controller: _notesCtrl, maxLines: 2),
              const SizedBox(height: Spacing.lg),

              // SAVE
              AppButton(label: 'Finish Session', onPressed: _saveSession),
            ],
          ),
        );
      },
    );
  }
}