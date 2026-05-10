import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textHint)
                .animate().scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              AppButton(label: 'Try Again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint)
                .animate().scale(begin: const Offset(0.5, 0.5)).fadeIn(),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 200.ms),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!.animate().fadeIn(delay: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}