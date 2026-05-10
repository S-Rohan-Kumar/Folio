import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : double.infinity,
      height: compact ? 36 : 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.amberMuted,
          shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
          padding: EdgeInsets.symmetric(horizontal: compact ? Spacing.md : Spacing.lg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class OutlinedAppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  const OutlinedAppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : double.infinity,
      height: compact ? 36 : 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.amber,
          side: const BorderSide(color: AppColors.elevated),
          shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
          padding: EdgeInsets.symmetric(horizontal: compact ? Spacing.md : Spacing.lg),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  
  const GoogleSignInButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.elevated),
          shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 28, color: AppColors.textPrimary),
            const SizedBox(width: Spacing.sm),
            Text('Continue with Google', style: AppTextStyles.labelLarge),
          ],
        ),
      ),
    );
  }
}