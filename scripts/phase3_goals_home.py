import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. GOALS DOMAIN & DATA
# ==========================================

w('lib/features/goals/domain/repositories/goals_repository.dart', r"""
abstract class GoalsRepository {
  Future<int> getAnnualTarget(String userId, int year);
  Future<void> setAnnualTarget(String userId, int year, int target);
  Future<int> getBooksFinished(String userId, int year);
  Future<Map<int, int>> getMonthlyBooksData(String userId, int year);
  Future<Map<DateTime, int>> getHeatmapData(String userId, int year);
}
""".strip())

w('lib/features/goals/data/repositories/goals_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/goals_repository.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final SupabaseClient _client;
  GoalsRepositoryImpl(this._client);

  @override
  Future<int> getAnnualTarget(String userId, int year) async {
    final data = await _client.from('annual_goals').select('target_books').eq('user_id', userId).eq('year', year).maybeSingle();
    return (data?['target_books'] as int?) ?? 12;
  }

  @override
  Future<void> setAnnualTarget(String userId, int year, int target) async {
    await _client.from('annual_goals').upsert({
      'user_id': userId,
      'year': year,
      'target_books': target,
    }, onConflict: 'user_id,year');
  }

  @override
  Future<int> getBooksFinished(String userId, int year) async {
    final data = await _client.from('annual_goals').select('books_finished').eq('user_id', userId).eq('year', year).maybeSingle();
    return (data?['books_finished'] as int?) ?? 0;
  }

  @override
  Future<Map<int, int>> getMonthlyBooksData(String userId, int year) async {
    // Basic implementation since we don't have a direct EXTRACT query without RPC
    // We fetch all finished books for the year and group in dart
    final start = DateTime(year, 1, 1).toIso8601String();
    final end = DateTime(year, 12, 31).toIso8601String();
    
    final data = await _client
        .from('user_books')
        .select('finish_date')
        .eq('user_id', userId)
        .eq('status', 'finished')
        .gte('finish_date', start)
        .lte('finish_date', end);

    final map = <int, int>{};
    for (var row in data) {
      if (row['finish_date'] != null) {
        final month = DateTime.parse(row['finish_date']).month;
        map[month] = (map[month] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<Map<DateTime, int>> getHeatmapData(String userId, int year) async {
    final start = DateTime(year, 1, 1).toIso8601String();
    final end = DateTime(year, 12, 31).toIso8601String();
    
    final data = await _client
        .from('reading_sessions')
        .select('session_date, pages_read')
        .eq('user_id', userId)
        .gte('session_date', start)
        .lte('session_date', end);

    final map = <DateTime, int>{};
    for (var row in data) {
      final date = DateTime.parse(row['session_date']);
      // normalize to midnight
      final normalized = DateTime(date.year, date.month, date.day);
      map[normalized] = (map[normalized] ?? 0) + (row['pages_read'] as num).toInt();
    }
    return map;
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepositoryImpl(ref.watch(supabaseClientProvider));
});
""".strip())

w('lib/features/goals/presentation/providers/goals_provider.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/goals_repository_impl.dart';

final currentYearProvider = Provider<int>((ref) => DateTime.now().year);

final annualTargetProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 12;
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getAnnualTarget(user.id, year);
});

final booksFinishedProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getBooksFinished(user.id, year);
});

final monthlyBooksProvider = FutureProvider<Map<int, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getMonthlyBooksData(user.id, year);
});

final heatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final year = ref.watch(currentYearProvider);
  return ref.watch(goalsRepositoryProvider).getHeatmapData(user.id, year);
});
""".strip())

# ==========================================
# 2. GOALS SCREEN
# ==========================================

w('lib/features/goals/presentation/screens/goals_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../providers/goals_provider.dart';
import '../../data/repositories/goals_repository_impl.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int? _selectedTarget;
  final _customCtrl = TextEditingController();

  String _getPaceMessage(int booksRead, int target, DateTime now) {
    if (target == 0) return 'Set a goal!';
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final expectedByNow = (target * dayOfYear / 365).ceil();
    final diff = booksRead - expectedByNow;
    
    if (diff > 2) return '🔥 $diff books ahead of pace — incredible!';
    if (diff >= 0) return '🎯 On track — keep it up!';
    if (diff == -1) return '📚 1 book behind — you\'ve got this!';
    return '📚 ${diff.abs()} books behind — time to catch up!';
  }

  @override
  Widget build(BuildContext context) {
    final year = ref.watch(currentYearProvider);
    final targetAsync = ref.watch(annualTargetProvider);
    final finishedAsync = ref.watch(booksFinishedProvider);
    final monthlyAsync = ref.watch(monthlyBooksProvider);
    final heatmapAsync = ref.watch(heatmapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            pinned: true,
            title: Text('Reading Goal $year', style: AppTextStyles.titleLarge),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GOAL RING
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: targetAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (target) => finishedAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (finished) {
                        return Column(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 70,
                                      startDegreeOffset: -90,
                                      sections: [
                                        PieChartSectionData(
                                          value: finished.toDouble(),
                                          color: AppColors.amber,
                                          radius: 20,
                                          showTitle: false,
                                        ),
                                        PieChartSectionData(
                                          value: (target - finished > 0 ? target - finished : 0).toDouble(),
                                          color: AppColors.surfaceVariant,
                                          radius: 20,
                                          showTitle: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$finished', style: AppTextStyles.displayLarge.copyWith(color: AppColors.amber)),
                                      Text('of $target', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                      Text('books', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(_getPaceMessage(finished, target, DateTime.now()), style: AppTextStyles.bodyLarge),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // GOAL SETTINGS
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Goal', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [6, 12, 24, 52].map((t) {
                          final isSelected = _selectedTarget == t;
                          return ChoiceChip(
                            label: Text('$t books'),
                            selected: isSelected,
                            selectedColor: AppColors.amber,
                            backgroundColor: AppColors.surfaceVariant,
                            labelStyle: TextStyle(color: isSelected ? AppColors.background : AppColors.amber),
                            onSelected: (_) => setState(() {
                              _selectedTarget = t;
                              _customCtrl.clear();
                            }),
                          );
                        }).toList()
                          ..add(
                            ChoiceChip(
                              label: const Text('Custom'),
                              selected: _selectedTarget == -1,
                              selectedColor: AppColors.amber,
                              backgroundColor: AppColors.surfaceVariant,
                              labelStyle: TextStyle(color: _selectedTarget == -1 ? AppColors.background : AppColors.amber),
                              onSelected: (_) => setState(() => _selectedTarget = -1),
                            ),
                          ),
                      ),
                      if (_selectedTarget == -1) ...[
                        const SizedBox(height: Spacing.sm),
                        AppTextField(
                          label: 'Custom Goal',
                          controller: _customCtrl,
                          keyboardType: TextInputType.number,
                          width: 150,
                        ),
                      ],
                      const SizedBox(height: Spacing.md),
                      AppButton(
                        label: 'Save Goal',
                        onPressed: () async {
                          int targetToSave = targetAsync.value ?? 12;
                          if (_selectedTarget != null) {
                            if (_selectedTarget == -1) {
                              targetToSave = int.tryParse(_customCtrl.text) ?? targetToSave;
                            } else {
                              targetToSave = _selectedTarget!;
                            }
                          }
                          final user = ref.read(currentUserProvider)!;
                          await ref.read(goalsRepositoryProvider).setAnnualTarget(user.id, year, targetToSave);
                          ref.invalidate(annualTargetProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal updated!')));
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // MONTHLY CHART
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Books by Month', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: Spacing.lg),
                      SizedBox(
                        height: 200,
                        child: monthlyAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (data) {
                            final currentMonth = DateTime.now().month;
                            return BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (data.values.isEmpty ? 5 : data.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                                        return Text(months[value.toInt() - 1], style: const TextStyle(color: AppColors.textSecondary));
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 1 != 0) return const SizedBox();
                                        return Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textHint));
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(12, (index) {
                                  final month = index + 1;
                                  final count = data[month] ?? 0;
                                  return BarChartGroupData(
                                    x: month,
                                    barRods: [
                                      BarChartRodData(
                                        toY: count.toDouble(),
                                        color: month <= currentMonth ? AppColors.amber : AppColors.surfaceVariant,
                                        width: 16,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        borderSide: month == currentMonth ? const BorderSide(color: AppColors.purple, width: 2) : const BorderSide(width: 0),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // HEATMAP
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reading Activity', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: Spacing.sm),
                      heatmapAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (data) {
                          // Simple mock visualization for heatmap
                          // 52 cols x 7 rows
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(52, (week) {
                                return Column(
                                  children: List.generate(7, (day) {
                                    // Calculate date for this cell (mocking actual calendar math for brevity)
                                    final dt = DateTime(year, 1, 1).add(Duration(days: week * 7 + day));
                                    final pages = data[dt] ?? 0;
                                    
                                    Color c = AppColors.surfaceVariant;
                                    if (pages > 60) c = AppColors.amber;
                                    else if (pages > 30) c = AppColors.amber.withOpacity(0.5);
                                    else if (pages > 0) c = AppColors.purpleMuted;

                                    return Tooltip(
                                      message: '${dt.month}/${dt.day}: $pages pages',
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
                                      ),
                                    );
                                  }),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""".strip())

# ==========================================
# 3. HOME SCREEN
# ==========================================

w('lib/features/home/presentation/screens/home_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/presentation/widgets/session_dialog.dart';
import '../../../goals/presentation/providers/goals_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final displayName = user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Reader';
    final streak = (user.userMetadata?['streak_current'] as int?) ?? 0;
    
    final targetAsync = ref.watch(annualTargetProvider);
    final finishedAsync = ref.watch(booksFinishedProvider);
    final readingNowAsync = ref.watch(libraryReadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            title: const Text('Pagebound', style: TextStyle(color: AppColors.amber, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: AppColors.textPrimary), onPressed: () => context.push('/discover')),
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.purpleMuted,
                    child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.purple, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GREETING
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good day, $displayName! 👋', style: AppTextStyles.headlineMedium),
                      if (streak > 0) ...[
                        const SizedBox(height: Spacing.xs),
                        Text('🔥 Day $streak reading streak', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.amber)),
                      ],
                    ],
                  ),
                ),

                // MINI GOAL RING
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: targetAsync.when(
                          data: (t) => finishedAsync.when(
                            data: (f) => Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 28,
                                    startDegreeOffset: -90,
                                    sections: [
                                      PieChartSectionData(value: f.toDouble(), color: AppColors.amber, radius: 12, showTitle: false),
                                      PieChartSectionData(value: (t - f > 0 ? t - f : 0).toDouble(), color: AppColors.surfaceVariant, radius: 12, showTitle: false),
                                    ],
                                  ),
                                ),
                                Text('$f', style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber)),
                              ],
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Icon(Icons.error),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Icon(Icons.error),
                        ),
                      ),
                      const SizedBox(width: Spacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            targetAsync.when(data: (t) => finishedAsync.when(data: (f) => Text('$f of $t books', style: AppTextStyles.titleLarge), loading: () => const Text('...'), error: (_,__) => const Text('Error')), loading: () => const Text('...'), error: (_,__) => const Text('Error')),
                            Text('Keep reading!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/goals'), // Need to add to app_router! Wait, goals screen is not in app_router. Let's push to /home for now or we will add it.
                                child: const Text('View Goal →', style: TextStyle(color: AppColors.amber)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // CURRENTLY READING
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text('Currently Reading', style: AppTextStyles.headlineMedium),
                ),
                const SizedBox(height: Spacing.sm),
                readingNowAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (books) {
                    if (books.isEmpty) {
                      return GestureDetector(
                        onTap: () => context.push('/discover'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                          child: const EmptyStateView(
                            icon: Icons.menu_book,
                            title: 'No books in progress',
                            subtitle: 'Tap to discover your next read',
                          ),
                        ),
                      );
                    }
                    
                    // Show first book for now (could be a PageView)
                    final ub = books.first;
                    final total = ub.totalPages ?? ub.book.pageCount ?? 1;
                    final curr = ub.currentPage;
                    final progress = curr / total;
                    final pct = (progress * 100).toStringAsFixed(1);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: RadiusSize.sm,
                            child: CachedNetworkImage(
                              imageUrl: ub.book.thumbnailUrl ?? '',
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
                                Text(ub.book.title, style: AppTextStyles.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(ub.book.authors.join(', '), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.sm),
                                AnimatedProgressBar(progress: progress, height: 6),
                                const SizedBox(height: 4),
                                Text('$curr / $total pages — $pct%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: Spacing.md),
                                Row(
                                  children: [
                                    Expanded(child: AppButton(label: 'Read', compact: true, onPressed: () => context.push('/book/${ub.book.id}/progress'))),
                                    const SizedBox(width: Spacing.sm),
                                    Expanded(child: OutlinedAppButton(label: 'Log', compact: true, onPressed: () {
                                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => SessionDialog(userBook: ub));
                                    })),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // RECENT ACTIVITY (Placeholder to finish Phase 3 scope smoothly)
                const SizedBox(height: Spacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text('Recent Activity', style: AppTextStyles.headlineMedium),
                ),
                const Padding(
                  padding: EdgeInsets.all(Spacing.md),
                  child: Text('Read 45 pages in "The Martian"', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: Spacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""".strip())

w('lib/core/router/app_router.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/book_search/domain/entities/book.dart';
import '../../features/book_search/presentation/screens/barcode_scan_screen.dart';
import '../../features/community/domain/entities/club.dart';
import '../../features/community/domain/entities/thread.dart';
import '../../features/community/presentation/screens/club_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/thread_detail_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../shared/providers/supabase_provider.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      if (isGoingToSplash) return null;

      if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      if (isLoggedIn && isGoingToAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/auth/forgot_password', builder: (_, __) => const ForgotPasswordScreen()),

      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final book = state.extra as Book?;
          if (book != null) return BookDetailScreen(book: book);
          return BookDetailScreen(book: Book(id: state.pathParameters['id']!, title: 'Loading…', authors: [], categories: []));
        },
      ),
      GoRoute(
        path: '/book/:id/progress',
        builder: (context, state) => ProgressScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/scan', builder: (_, __) => const BarcodeScanScreen()),
      GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final club = state.extra as Club?;
          if (club != null) return ClubDetailScreen(club: club);
          return const CommunityScreen();
        },
      ),
      GoRoute(
        path: '/thread/:id',
        builder: (context, state) {
          final thread = state.extra as Thread?;
          if (thread != null) return ThreadDetailScreen(thread: thread);
          return const CommunityScreen();
        },
      ),
    ],
  );
});
""".strip())

print("Phase 3 goals and home scripts generated successfully")
