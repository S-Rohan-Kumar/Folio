import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
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
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      // Enforce authentication
      if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      if (isLoggedIn && isGoingToAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),

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