import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/book_search/domain/entities/book.dart';
import '../../features/book_search/presentation/screens/barcode_scan_screen.dart';
import '../../features/community/domain/entities/club.dart';
import '../../features/community/domain/entities/thread.dart';
import '../../features/community/presentation/screens/club_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/create_club_screen.dart';
import '../../features/community/presentation/screens/thread_detail_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/reviews/presentation/screens/review_screen.dart';
import '../../shared/providers/supabase_provider.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // While auth stream is still loading, don't redirect yet
      if (authState.isLoading) return null;

      // A session object being non-null means the user is actually logged in
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      if (isGoingToSplash) return null;

      if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      if (isLoggedIn && isGoingToAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/auth/forgot_password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/auth/verify_email', builder: (_, state) {
        final email = state.extra as String? ?? '';
        return VerifyEmailScreen(email: email);
      }),

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
      GoRoute(
        path: '/book/:id/progress',
        builder: (context, state) => ProgressScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:id/review',
        builder: (context, state) => ReviewScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/scan', builder: (_, __) => const BarcodeScanScreen()),
      GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(path: '/club/create', builder: (_, __) => const CreateClubScreen()),
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