import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/my_clubs_tab.dart';
import '../widgets/discover_clubs_tab.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text('Community', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
                pinned: true,
                backgroundColor: AppColors.background,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.amber),
                    onPressed: () => context.push('/club/create'),
                  ),
                ],
                bottom: const TabBar(
                  tabs: [Tab(text: "My Clubs"), Tab(text: "Discover")],
                  indicatorColor: AppColors.amber,
                  labelColor: AppColors.amber,
                  unselectedLabelColor: AppColors.textSecondary,
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              MyClubsTab(),
              DiscoverClubsTab(),
            ],
          ),
        ),
      ),
    );
  }
}