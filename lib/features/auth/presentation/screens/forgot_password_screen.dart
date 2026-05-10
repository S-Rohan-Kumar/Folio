import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    await ref.read(authNotifierProvider.notifier).resetPassword(email);
    
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppColors.error),
      );
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.amber),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text("Reset password", style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: Spacing.md),
              if (!_sent) ...[
                Text(
                  "Enter your email and we'll send you\na link to reset your password.",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Spacing.xl),
                AppTextField(
                  label: "Email",
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: Spacing.lg),
                AppButton(
                  label: "Send Reset Link",
                  isLoading: authState.isLoading,
                  onPressed: _handleReset,
                ),
              ] else ...[
                const SizedBox(height: Spacing.xxl),
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
                const SizedBox(height: Spacing.md),
                Text(
                  "Check your email",
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.success),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  "We sent a reset link to\n${_emailCtrl.text}",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}