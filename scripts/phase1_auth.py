import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 0. SHARED WIDGETS
# ==========================================

w('lib/shared/widgets/app_text_field.dart', r"""
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
""".strip())

w('lib/shared/widgets/app_button.dart', r"""
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
""".strip())


# ==========================================
# 1. AUTH DOMAIN & DATA
# ==========================================

w('lib/features/auth/domain/repositories/auth_repository.dart', r"""
abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password, String displayName);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
}
""".strip())

w('lib/features/auth/data/repositories/auth_repository_impl.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  AuthRepositoryImpl(this._client);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    // Basic Google OAuth placeholder (requires further configuration in Supabase dashboard)
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});
""".strip())

w('lib/features/auth/presentation/providers/auth_provider.dart', r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithEmail(email, password, name);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resetPassword(email);
    });
  }
}

final authNotifierProvider = AutoDisposeAsyncNotifierProvider<AuthNotifier, void>(() => AuthNotifier());
""".strip())


# ==========================================
# 2. AUTH SCREENS
# ==========================================

w('lib/features/auth/presentation/screens/splash_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/supabase_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _checkAuth);
  }

  void _checkAuth() {
    if (!mounted) return;
    final session = ref.read(authStateProvider).value;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pagebound',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms),
      ),
    );
  }
}
""".strip())

w('lib/features/auth/presentation/screens/login_screen.dart', r"""
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
""".strip())

w('lib/features/auth/presentation/screens/signup_screen.dart', r"""
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

    await ref.read(authNotifierProvider.notifier).signUp(email, pass, name);
    
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Welcome to Pagebound 📚'), backgroundColor: AppColors.success),
      );
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
""".strip())

w('lib/features/auth/presentation/screens/forgot_password_screen.dart', r"""
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
""".strip())

w('lib/core/router/app_router.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/book_search/domain/entities/book.dart';
import '../../features/book_search/presentation/screens/barcode_scan_screen.dart';
import '../../features/community/domain/entities/club.dart';
import '../../features/community/domain/entities/thread.dart';
import '../../features/community/presentation/screens/club_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/thread_detail_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/providers/supabase_provider.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      if (isGoingToSplash) return null; // let splash handle auth routing logic

      if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      if (isLoggedIn && isGoingToAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/auth/forgot_password', builder: (_, __) => const ForgotPasswordScreen()),

      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final book = state.extra as Book?;
          if (book != null) return BookDetailScreen(book: book);
          return BookDetailScreen(book: Book(id: state.pathParameters['id']!, title: 'Loading…', authors: [], categories: []));
        },
      ),
      GoRoute(path: '/scan', builder: (_, __) => const BarcodeScanScreen()),
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final club = state.extra as Club?;
          if (club != null) return ClubDetailScreen(club: club);
          return const CommunityScreen();
        },
      ),
      GoRoute(
        path: '/thread/:id',
        builder: (context, state) {
          final thread = state.extra as Thread?;
          if (thread != null) return ThreadDetailScreen(thread: thread);
          return const CommunityScreen();
        },
      ),
    ],
  );
});
""".strip())

print("Phase 1 screens and routing created successfully")
