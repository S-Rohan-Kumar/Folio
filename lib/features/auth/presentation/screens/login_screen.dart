import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: AppColors.error),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).signIn(email, pass);
    
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppColors.error),
      );
    } else {
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
                const SizedBox(height: Spacing.xxl),
                Text("Welcome back", style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: Spacing.xs),
                Text("Sign in to continue reading", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Spacing.xl),
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
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textHint),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/forgot_password'),
                    child: const Text('Forgot password?', style: TextStyle(color: AppColors.amber)),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                AppButton(
                  label: "Sign In",
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.elevated)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      child: Text("or", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ),
                    const Expanded(child: Divider(color: AppColors.elevated)),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                GoogleSignInButton(
                  onTap: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => context.push('/auth/signup'),
                      child: const Text("Sign up", style: TextStyle(color: AppColors.amber)),
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