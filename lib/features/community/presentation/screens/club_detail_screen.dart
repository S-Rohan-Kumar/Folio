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