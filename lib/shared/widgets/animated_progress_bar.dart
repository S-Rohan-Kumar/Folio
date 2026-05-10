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