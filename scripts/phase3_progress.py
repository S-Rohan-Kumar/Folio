import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 0. SHARED PROGRESS WIDGETS
# ==========================================

w('lib/shared/widgets/animated_progress_bar.dart', r"""
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Determine gradient based on progress
    List<Color> colors;
    if (clampedProgress < 0.33) {
      colors = [AppColors.amber, AppColors.amberMuted];
    } else if (clampedProgress < 0.66) {
      colors = [AppColors.amber, AppColors.success];
    } else {
      colors = [AppColors.purple, AppColors.amber];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clampedProgress,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
""".strip())

w('lib/shared/widgets/stat_card.dart', r"""
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.amber),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
""".strip())

# ==========================================
# 1. PROGRESS DOMAIN & DATA
# ==========================================

w('lib/features/progress/domain/entities/reading_session.dart', r"""
class ReadingSession {
  final String id;
  final String userId;
  final String bookId;
  final int startPage;
  final int endPage;
  final int pagesRead;
  final int durationSecs;
  final DateTime sessionDate;
  final String? notes;

  const ReadingSession({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.startPage,
    required this.endPage,
    required this.pagesRead,
    required this.durationSecs,
    required this.sessionDate,
    this.notes,
  });
}
""".strip())

w('lib/features/progress/domain/repositories/progress_repository.dart', r"""
import '../entities/reading_session.dart';

abstract class ProgressRepository {
  Future<void> saveReadingSession({
    required String userId,
    required String bookId,
    required int startPage,
    required int endPage,
    required int durationSecs,
    String? notes,
  });
  
  Future<List<ReadingSession>> getReadingSessions(String userId, String bookId);
  Future<double> getReadingSpeed(String userId); // pages per hour
  Future<void> logXp(String userId, String action, int xpEarned);
}
""".strip())

w('lib/features/progress/data/repositories/progress_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final SupabaseClient _client;
  ProgressRepositoryImpl(this._client);

  @override
  Future<void> saveReadingSession({
    required String userId,
    required String bookId,
    required int startPage,
    required int endPage,
    required int durationSecs,
    String? notes,
  }) async {
    // 1. Save session
    await _client.from('reading_sessions').insert({
      'user_id': userId,
      'book_id': bookId,
      'start_page': startPage,
      'end_page': endPage,
      'duration_secs': durationSecs,
      'notes': notes,
      'session_date': DateTime.now().toIso8601String().split('T').first,
    });

    // 2. Update user_books
    // Check if finished
    final ub = await _client.from('user_books').select('total_pages, books(page_count)').eq('user_id', userId).eq('book_id', bookId).single();
    final total = (ub['total_pages'] as int?) ?? (ub['books']['page_count'] as int?) ?? 9999;
    
    final isFinished = endPage >= total;
    
    await _client.from('user_books').update({
      'current_page': endPage,
      'updated_at': DateTime.now().toIso8601String(),
      if (isFinished) 'status': 'finished',
      if (isFinished) 'finish_date': DateTime.now().toIso8601String().split('T').first,
    }).eq('user_id', userId).eq('book_id', bookId);
  }

  @override
  Future<List<ReadingSession>> getReadingSessions(String userId, String bookId) async {
    final data = await _client
        .from('reading_sessions')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
        
    return (data as List).map((row) => ReadingSession(
      id: row['id'],
      userId: row['user_id'],
      bookId: row['book_id'],
      startPage: row['start_page'],
      endPage: row['end_page'],
      pagesRead: row['pages_read'],
      durationSecs: row['duration_secs'],
      sessionDate: DateTime.parse(row['session_date']),
      notes: row['notes'],
    )).toList();
  }

  @override
  Future<double> getReadingSpeed(String userId) async {
    final data = await _client
        .from('reading_sessions')
        .select('pages_read, duration_secs')
        .eq('user_id', userId);
        
    if (data.isEmpty) return 0.0;
    
    int totalPages = 0;
    int totalSecs = 0;
    for (var row in data) {
      totalPages += (row['pages_read'] as num).toInt();
      totalSecs += (row['duration_secs'] as num).toInt();
    }
    
    if (totalSecs == 0) return 0.0;
    return (totalPages / (totalSecs / 3600));
  }

  @override
  Future<void> logXp(String userId, String action, int xpEarned) async {
    await _client.from('xp_log').insert({
      'user_id': userId,
      'action': action,
      'xp_earned': xpEarned,
    });
    
    // Increment user XP
    await _client.rpc('increment_user_xp', params: {'user_id_param': userId, 'amount': xpEarned});
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepositoryImpl(ref.watch(supabaseClientProvider));
});
""".strip())

w('supabase/fix_xp.sql', r"""
-- RUN THIS IN SUPABASE SQL EDITOR to support the rpc call
CREATE OR REPLACE FUNCTION increment_user_xp(user_id_param UUID, amount INT)
RETURNS void AS $$
BEGIN
  UPDATE public.users 
  SET xp = xp + amount
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""".strip())

# ==========================================
# 2. PROGRESS PROVIDERS & TIMER
# ==========================================

w('lib/features/progress/presentation/providers/session_timer_provider.dart', r"""
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TimerState {
  final Duration elapsed;
  final bool isRunning;
  const TimerState({required this.elapsed, required this.isRunning});
  
  TimerState copyWith({Duration? elapsed, bool? isRunning}) =>
    TimerState(elapsed: elapsed ?? this.elapsed, isRunning: isRunning ?? this.isRunning);
}

class SessionTimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _startTime;

  @override
  TimerState build() {
    final box = Hive.box('session_cache');
    final saved = box.get('session_start') as String?;
    if (saved != null) {
      _startTime = DateTime.parse(saved);
      final elapsed = DateTime.now().difference(_startTime!);
      return TimerState(elapsed: elapsed, isRunning: false); // Paused state by default if recovered
    }
    return const TimerState(elapsed: Duration.zero, isRunning: false);
  }

  void start() {
    _startTime ??= DateTime.now().subtract(state.elapsed);
    state = state.copyWith(isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startTime!);
      state = state.copyWith(elapsed: elapsed);
    });
    Hive.box('session_cache').put('session_start', _startTime!.toIso8601String());
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    _startTime = DateTime.now().subtract(state.elapsed);
    start();
  }

  void reset() {
    _ticker?.cancel();
    _startTime = null;
    state = const TimerState(elapsed: Duration.zero, isRunning: false);
    Hive.box('session_cache').delete('session_start');
  }
}

final sessionTimerNotifierProvider = NotifierProvider<SessionTimerNotifier, TimerState>(() {
  return SessionTimerNotifier();
});
""".strip())

w('lib/features/progress/presentation/providers/progress_provider.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../data/repositories/progress_repository_impl.dart';

final readingSessionsProvider = FutureProvider.family<List<ReadingSession>, String>((ref, bookId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(progressRepositoryProvider).getReadingSessions(user.id, bookId);
});

final readingSpeedProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  return ref.watch(progressRepositoryProvider).getReadingSpeed(user.id);
});
""".strip())

# ==========================================
# 3. PROGRESS SCREENS & DIALOGS
# ==========================================

w('lib/features/progress/presentation/screens/progress_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/session_dialog.dart';

class ProgressScreen extends ConsumerWidget {
  final String bookId;

  const ProgressScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBooksAsync = ref.watch(libraryReadingProvider);
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: userBooksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(libraryReadingProvider)),
        data: (books) {
          final userBook = books.where((b) => b.book.id == bookId).firstOrNull;
          if (userBook == null) {
            return const EmptyStateView(
              icon: Icons.error_outline,
              title: 'Book not found',
              subtitle: 'This book is not in your Reading Now shelf',
            );
          }

          final book = userBook.book;
          final totalPages = userBook.totalPages ?? book.pageCount ?? 1;
          final currentPage = userBook.currentPage;
          final progress = currentPage / totalPages;
          final percent = (progress * 100).toStringAsFixed(1);
          
          final sessionsAsync = ref.watch(readingSessionsProvider(bookId));
          final speedAsync = ref.watch(readingSpeedProvider);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.surface,
                pinned: true,
                title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notes),
                    onPressed: () => context.push('/book/$bookId/notes'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BOOK HEADER
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: RadiusSize.sm,
                            child: CachedNetworkImage(
                              imageUrl: book.thumbnailUrl ?? '',
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, width: 60, height: 90, child: const Icon(Icons.book)),
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(book.title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
                                Text(book.authors.join(', '), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.amberMuted.withOpacity(0.3), borderRadius: RadiusSize.sm),
                                  child: Text('Reading Now', style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PROGRESS SECTION
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Page $currentPage of $totalPages', style: AppTextStyles.bodyMedium),
                              Text('$percent%', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          AnimatedProgressBar(progress: progress),
                          const SizedBox(height: Spacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              speedAsync.when(
                                data: (s) => StatCard(label: 'Speed', value: '${s.toInt()} pg/h'),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Speed', value: '-'),
                              ),
                              speedAsync.when(
                                data: (s) {
                                  final pagesLeft = totalPages - currentPage;
                                  final hrsLeft = s > 0 ? pagesLeft / s : 0;
                                  return StatCard(label: 'Time Left', value: hrsLeft > 0 ? '${hrsLeft.toStringAsFixed(1)}h' : '-');
                                },
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Time Left', value: '-'),
                              ),
                              sessionsAsync.when(
                                data: (list) => StatCard(label: 'Sessions', value: '${list.length}'),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const StatCard(label: 'Sessions', value: '-'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // SESSION BUTTON
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: AppButton(
                        label: '📖 Start Reading Session',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SessionDialog(userBook: userBook),
                          );
                        },
                      ),
                    ),

                    // STREAK BANNER
                    if (user?.userMetadata?['streak_current'] != null && user!.userMetadata!['streak_current'] > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(color: AppColors.purpleMuted, borderRadius: RadiusSize.md),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: Spacing.md),
                              Text('Day ${user.userMetadata!['streak_current']} streak — keep it up!', style: AppTextStyles.titleLarge),
                            ],
                          ),
                        ),
                      ),

                    // SESSION HISTORY
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Text('Reading Sessions', style: AppTextStyles.headlineMedium),
                    ),
                    sessionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(readingSessionsProvider)),
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(Spacing.md),
                            child: Text('No sessions logged yet. Tap "Start Reading Session" to begin!'),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceVariant),
                          itemBuilder: (context, i) {
                            final session = sessions[i];
                            final date = session.sessionDate;
                            final mins = (session.durationSecs / 60).round();
                            final speed = (session.pagesRead / (session.durationSecs / 3600)).round();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${date.month}/${date.day}/${date.year}', style: AppTextStyles.titleLarge),
                                      Text('Pages ${session.startPage} - ${session.endPage}', style: AppTextStyles.labelSmall),
                                    ],
                                  ),
                                  Text('${session.pagesRead} pages', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$mins min', style: AppTextStyles.bodyMedium),
                                      Text('$speed pg/hr', style: AppTextStyles.labelSmall),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
""".strip())

w('lib/features/progress/presentation/widgets/session_dialog.dart', r"""
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
""".strip())

print("Phase 3 progress scripts generated successfully")
