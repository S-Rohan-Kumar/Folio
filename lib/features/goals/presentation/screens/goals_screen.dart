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