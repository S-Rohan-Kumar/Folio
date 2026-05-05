import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = rating >= i + 1;
        final half = !full && rating >= i + 0.5;
        final icon = full ? Icons.star : (half ? Icons.star_half : Icons.star_border);
        if (interactive) {
          return GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final local = box.globalToLocal(d.globalPosition);
                final starWidth = size + 2;
                final starIndex = (local.dx / starWidth).floor();
                final isLeft = (local.dx % starWidth) < starWidth / 2;
                onRatingChanged?.call(isLeft ? starIndex + 0.5 : starIndex + 1.0);
              }
            },
            child: Icon(icon, size: size, color: AppColors.amber),
          );
        }
        return Icon(icon, size: size, color: AppColors.amber);
      }),
    );
  }
}