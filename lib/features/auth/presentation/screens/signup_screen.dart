import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    final needsVerification = await ref.read(authNotifierProvider.notifier).signUp(email, pass, name);

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppColors.error),
      );
    } else if (needsVerification) {
      // Email confirmation required — go to verify screen
      context.go('/auth/verify_email', extra: email);
    } else {
      // Auto confirmed (e.g. email confirmation disabled) — go home
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                Text("Create account", style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: Spacing.xs),
                Text("Join thousands of readers", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Spacing.xl),
                AppTextField(
                  label: "Display name",
                  controller: _nameCtrl,
                ),
                const SizedBox(height: Spacing.md),
                AppTextField(
                  label: "Email",
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: Spacing.md),
                AppTextField(
                  label: "Password",
                  controller: _passCtrl,
                  obscureText: _obscure,
                ),
                const SizedBox(height: Spacing.md),
                AppTextField(
                  label: "Confirm password",
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textHint),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                AppButton(
                  label: "Create Account",
                  isLoading: authState.isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text("Sign in", style: TextStyle(color: AppColors.amber)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}