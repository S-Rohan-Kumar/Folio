import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.amberMuted,
                    child: Text(
                      user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : 'U',
                      style: AppTextStyles.displayMedium.copyWith(color: AppColors.amber),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(user.userMetadata?['full_name'] ?? 'Book Lover', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  Text(user.email ?? '', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: Spacing.xl),
                  
                  // Stats Grid Placeholder
                  Row(
                    children: [
                      _buildStatCard('Books Read', '12'),
                      const SizedBox(width: Spacing.md),
                      _buildStatCard('Current Streak', '5 Days'),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Actions
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
                    tileColor: AppColors.surfaceVariant,
                    leading: const Icon(Icons.emoji_events, color: AppColors.amber),
                    title: Text('Reading Goals', style: AppTextStyles.titleLarge),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: () {},
                  ),
                  const SizedBox(height: Spacing.sm),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
                    tileColor: AppColors.surfaceVariant,
                    leading: const Icon(Icons.person, color: AppColors.purple),
                    title: Text('Edit Profile', style: AppTextStyles.titleLarge),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: () {},
                  ),
                  const SizedBox(height: Spacing.xl),
                  
                  TextButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.md,
          border: Border.all(color: AppColors.amber.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.amber)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}