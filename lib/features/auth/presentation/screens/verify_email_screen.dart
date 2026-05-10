import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.amber,
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Verify your email',
                style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'We\'ve sent a verification link to:\n$email',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xxl),
              Text(
                'Please check your inbox and click the link to activate your account.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              AppButton(
                label: 'Back to Sign In',
                onPressed: () => context.go('/auth/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
