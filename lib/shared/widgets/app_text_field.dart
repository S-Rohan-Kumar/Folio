import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final String? errorText;
  final int? maxLines;
  final int? maxLength;
  final double? width;
  final bool expanded;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.suffixIcon,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.width,
    this.expanded = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
            labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            suffixIcon: suffixIcon,
            counterText: '', // Hide default counter
            border: OutlineInputBorder(
              borderRadius: RadiusSize.md,
              borderSide: const BorderSide(color: AppColors.elevated),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: RadiusSize.md,
              borderSide: const BorderSide(color: AppColors.elevated),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: RadiusSize.md,
              borderSide: const BorderSide(color: AppColors.amber),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: RadiusSize.md,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: RadiusSize.md,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 16),
          ),
        ),
      ],
    );

    if (width != null) {
      field = SizedBox(width: width, child: field);
    }
    if (expanded) {
      field = Expanded(child: field);
    }

    return field;
  }
}