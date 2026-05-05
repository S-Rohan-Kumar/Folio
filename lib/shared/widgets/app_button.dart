import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isSecondary = variant == AppButtonVariant.secondary;

    return SizedBox(
      height: 52,
      width: width,
      child: AnimatedScale(
        scale: onPressed == null ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: isSecondary
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                child: _buildChild(AppColors.amber),
              )
            : variant == AppButtonVariant.ghost
                ? TextButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _buildChild(AppColors.amber),
                  )
                : ElevatedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _buildChild(AppColors.background),
                  ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Text(label, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold));
  }
}