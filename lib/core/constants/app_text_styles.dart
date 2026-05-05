import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const fontFamily = 'Inter';

  static const displayLarge = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary);
  static const displayMedium = TextStyle(fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.textPrimary);
  static const headlineLarge = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const headlineMedium = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const titleLarge = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const bodyLarge = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.textPrimary);
  static const bodyMedium = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static const labelLarge = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: AppColors.textPrimary);
  static const labelSmall = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.textHint);
}
