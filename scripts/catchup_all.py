import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. DISCOVER & LOCAL CACHE UPDATES
# ==========================================

w('lib/features/book_search/data/datasources/book_local_cache.dart', r"""
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/book.dart';
import '../models/google_book_model.dart';

class BookLocalCache {
  static const _boxName = 'book_cache';
  static const _maxSize = 50;

  Box get _box => Hive.box(_boxName);

  void cacheBook(Book book) {
    final json = GoogleBookModel.toSupabaseJson(book);
    _box.put(book.id, jsonEncode(json));
    _trimCache();
  }

  Book? getCachedBook(String id) {
    final raw = _box.get(id) as String?;
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Book(
        id: map['id'] as String,
        isbn10: map['isbn_10'] as String?,
        isbn13: map['isbn_13'] as String?,
        title: map['title'] as String,
        authors: List<String>.from(map['authors'] as List? ?? []),
        publisher: map['publisher'] as String?,
        publishedDate: map['published_date'] as String?,
        description: map['description'] as String?,
        pageCount: map['page_count'] as int?,
        categories: List<String>.from(map['categories'] as List? ?? []),
        thumbnailUrl: map['thumbnail_url'] as String?,
        language: map['language'] as String? ?? 'en',
        averageRating: (map['average_rating'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> getRecentSearches() {
    return List<String>.from(_box.get('recent_searches', defaultValue: []) as List? ?? []);
  }

  void addRecentSearch(String query) {
    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 8) searches.removeLast();
    _box.put('recent_searches', searches);
  }

  void clearRecentSearches() {
    _box.delete('recent_searches');
  }

  void _trimCache() {
    final keys = _box.keys.where((k) => k != 'recent_searches').toList();
    if (keys.length > _maxSize) {
      for (var i = _maxSize; i < keys.length; i++) {
        _box.delete(keys[i]);
      }
    }
  }
}
""".strip())

w('lib/features/discover/presentation/screens/discover_screen.dart', r"""
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../../book_search/presentation/providers/book_search_provider.dart';
import '../../../book_search/data/repositories/book_search_repository_impl.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.isEmpty) {
      ref.read(bookSearchNotifierProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(bookSearchNotifierProvider.notifier).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: Spacing.sm),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discover', style: AppTextStyles.displayMedium),
                Text('Find your next great read', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          _ScanButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.lg,
          border: Border.all(
            color: _focused ? AppColors.amber.withOpacity(0.6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _controller,
          onChanged: _onSearch,
          onTap: () => setState(() => _focused = true),
          onTapOutside: (_) => setState(() => _focused = false),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search books, authors, ISBN…',
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 22),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                    onPressed: () {
                      _controller.clear();
                      ref.read(bookSearchNotifierProvider.notifier).clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final searchState = ref.watch(bookSearchNotifierProvider);
    final query = _controller.text.trim();

    if (query.isEmpty) return _buildDefaultState();

    return searchState.when(
      loading: () => const BookGridShimmer(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(bookSearchNotifierProvider.notifier).search(query),
      ),
      data: (books) => books.isEmpty ? _buildNoResults(query) : _buildResults(books),
    );
  }

  Widget _buildDefaultState() {
    final recents = ref.watch(recentSearchesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTextStyles.titleLarge),
                TextButton(
                  onPressed: () {
                    ref.read(bookLocalCacheProvider).clearRecentSearches();
                    ref.invalidate(recentSearchesProvider);
                  },
                  child: const Text('Clear', style: TextStyle(color: AppColors.textHint)),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ...recents.map((q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppColors.textHint, size: 20),
              title: Text(q, style: AppTextStyles.bodyLarge),
              trailing: const Icon(Icons.north_west, color: AppColors.textHint, size: 16),
              onTap: () {
                _controller.text = q;
                _onSearch(q);
              },
            )),
            const SizedBox(height: Spacing.lg),
          ],
          Text('Browse Genres', style: AppTextStyles.titleLarge),
          const SizedBox(height: Spacing.sm),
          _GenreGrid(
            onGenreSelected: (genreQuery) {
              _controller.text = genreQuery;
              _onSearch(genreQuery);
              setState(() => _focused = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.md,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) => BookCard(
        book: books[i],
        animationIndex: i,
        onTap: () => context.push('/book/${books[i].id}', extra: books[i]),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return EmptyStateView(
      icon: Icons.search_off,
      title: 'No results for "$query"',
      subtitle: 'Try a different title, author, or ISBN',
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scan'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.md,
          border: Border.all(color: AppColors.amber.withOpacity(0.3)),
        ),
        child: const Icon(Icons.qr_code_scanner, color: AppColors.amber, size: 22),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  final ValueChanged<String> onGenreSelected;

  const _GenreGrid({required this.onGenreSelected});

  final _genres = const [
    ('Fantasy', '🧙', Color(0xFF3D2E60)),
    ('Science Fiction', '🚀', Color(0xFF1A2E4A)),
    ('Mystery', '🔍', Color(0xFF2E1A1A)),
    ('Romance', '💕', Color(0xFF3D1A2E)),
    ('Non-Fiction', '📚', Color(0xFF1A3D2E)),
    ('Thriller', '⚡', Color(0xFF2E2E1A)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
        childAspectRatio: 2.5,
      ),
      itemCount: _genres.length,
      itemBuilder: (context, i) {
        final (name, emoji, color) = _genres[i];
        return GestureDetector(
          onTap: () => onGenreSelected('subject:$name'),
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: RadiusSize.md),
            child: Row(
              children: [
                const SizedBox(width: Spacing.md),
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: Spacing.sm),
                Text(name, style: AppTextStyles.titleLarge),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }
}
""".strip())

w('lib/features/library/presentation/screens/library_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../domain/entities/user_book.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    (ReadingStatus.reading, 'Reading', Icons.menu_book),
    (ReadingStatus.wantToRead, 'Want to Read', Icons.bookmark),
    (ReadingStatus.finished, 'Finished', Icons.check_circle),
    (ReadingStatus.dnf, 'DNF', Icons.cancel),
    (ReadingStatus.onHold, 'On Hold', Icons.pause_circle),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((t) => _LibraryTab(status: t.$1)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Library', style: AppTextStyles.displayMedium),
                Text('Your reading journey', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/discover'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: RadiusSize.md),
              child: const Icon(Icons.add, color: AppColors.amber, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      height: 42,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.amber,
        indicatorWeight: 2,
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
      ),
    );
  }
}

class _LibraryTab extends ConsumerWidget {
  final ReadingStatus status;
  const _LibraryTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _providerFor(status);
    final state = ref.watch(provider);

    return state.when(
      loading: () => const BookGridShimmer(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
      data: (books) => books.isEmpty
          ? _buildEmpty(context, status)
          : GridView.builder(
              padding: const EdgeInsets.all(Spacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: Spacing.sm,
                mainAxisSpacing: Spacing.md,
                childAspectRatio: 0.58,
              ),
              itemCount: books.length,
              itemBuilder: (context, i) => BookCard(
                book: books[i].book,
                userBook: books[i],
                animationIndex: i,
                onTap: () => context.push('/book/${books[i].book.id}', extra: books[i].book),
              ),
            ),
    );
  }

  AsyncNotifierProvider<LibraryNotifier, List<UserBook>> _providerFor(ReadingStatus s) {
    switch (s) {
      case ReadingStatus.reading: return libraryReadingProvider;
      case ReadingStatus.wantToRead: return libraryWantToReadProvider;
      case ReadingStatus.finished: return libraryFinishedProvider;
      case ReadingStatus.dnf: return libraryDnfProvider;
      case ReadingStatus.onHold: return libraryOnHoldProvider;
    }
  }

  Widget _buildEmpty(BuildContext context, ReadingStatus status) {
    final (icon, title, subtitle) = switch (status) {
      ReadingStatus.reading => (Icons.menu_book_outlined, 'Nothing here yet', 'Start a book and track your progress'),
      ReadingStatus.wantToRead => (Icons.bookmark_border, 'Your wishlist is empty', 'Add books you want to read'),
      ReadingStatus.finished => (Icons.emoji_events_outlined, 'No finished books yet', 'Finish your first book!'),
      ReadingStatus.dnf => (Icons.cancel_outlined, 'No abandoned books', 'Great — you finish everything you start!'),
      ReadingStatus.onHold => (Icons.pause_circle_outline, 'Nothing on hold', 'Taking a break? Put a book on hold here'),
    };

    return EmptyStateView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: TextButton.icon(
        onPressed: () => context.push('/discover'),
        icon: const Icon(Icons.search, color: AppColors.amber),
        label: const Text('Find a book', style: TextStyle(color: AppColors.amber)),
      ),
    );
  }
}
""".strip())


# ==========================================
# 2. AUTHENTICATION UI & ROUTING
# ==========================================

w('lib/features/auth/presentation/screens/login_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // Navigation is handled by router redirect
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome back', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Sign in to continue your reading journey', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              _buildTextField(_email, 'Email', Icons.email_outlined, false),
              const SizedBox(height: 16),
              _buildTextField(_password, 'Password', Icons.lock_outline, true),
              const SizedBox(height: 32),
              AppButton(
                label: 'Sign In',
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: AppTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/auth/signup'),
                    child: const Text('Sign Up', style: TextStyle(color: AppColors.amber)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        prefixIcon: Icon(icon, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
""".strip())

w('lib/features/auth/presentation/screens/signup_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signup() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'full_name': _name.text.trim()},
      );
      // Navigation is handled by router redirect
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Account', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Join Pagebound to track your reading', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              _buildTextField(_name, 'Full Name', Icons.person_outline, false),
              const SizedBox(height: 16),
              _buildTextField(_email, 'Email', Icons.email_outlined, false),
              const SizedBox(height: 16),
              _buildTextField(_password, 'Password', Icons.lock_outline, true),
              const SizedBox(height: 32),
              AppButton(
                label: 'Sign Up',
                isLoading: _isLoading,
                onPressed: _signup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        prefixIcon: Icon(icon, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
""".strip())

w('lib/core/router/app_router.dart', r"""
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

      // Uncomment to enforce authentication
      // if (!isLoggedIn && !isGoingToAuth) return '/auth/login';
      // if (isLoggedIn && isGoingToAuth) return '/home';

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
""".strip())

w('lib/app.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class PageboundApp extends ConsumerWidget {
  const PageboundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pagebound',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
""".strip())

# ==========================================
# 3. COMMUNITY CREATION UI & FABS
# ==========================================

w('lib/features/community/presentation/screens/community_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/thread_repository_impl.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ClubsTab(),
                  _DiscussionsTab(),
                  _BattlesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.amber,
        onPressed: () => _showCreateClubDialog(context),
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('Create Club', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.amber,
        onPressed: () => _showCreateThreadDialog(context),
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('New Thread', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  void _showCreateClubDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Create a Club', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Club Name', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null || nameCtrl.text.isEmpty) return;
                await ref.read(clubRepositoryProvider).createClub(nameCtrl.text, descCtrl.text, user.id, true);
                ref.invalidate(publicClubsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateThreadDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    // In a real app, you'd select a book to attach the thread to. Using a placeholder for now.
    final bookId = 'placeholder_book_id';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Start Discussion', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Body', labelStyle: TextStyle(color: AppColors.textHint)),
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null || titleCtrl.text.isEmpty) return;
                await ref.read(threadRepositoryProvider).createThread(bookId, null, user.id, titleCtrl.text, bodyCtrl.text, false);
                ref.invalidate(recentThreadsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Post', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Text('Community', style: AppTextStyles.displayMedium),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.amber,
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: 'Clubs'),
          Tab(text: 'Discussions'),
          Tab(text: 'Battles'),
        ],
      ),
    );
  }
}

class _ClubsTab extends ConsumerWidget {
  const _ClubsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(publicClubsProvider);

    return clubsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(publicClubsProvider)),
      data: (clubs) {
        if (clubs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.groups,
            title: 'No Clubs Found',
            subtitle: 'Be the first to start a reading club!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: clubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, i) {
            final c = clubs[i];
            return ListTile(
              contentPadding: const EdgeInsets.all(Spacing.sm),
              shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
              tileColor: AppColors.surfaceVariant,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.purpleMuted, borderRadius: RadiusSize.sm),
                child: const Icon(Icons.menu_book, color: AppColors.purple),
              ),
              title: Text(c.name, style: AppTextStyles.titleLarge),
              subtitle: Text('${c.memberCount} members', style: AppTextStyles.bodyMedium),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => context.push('/club/${c.id}', extra: c),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1);
          },
        );
      },
    );
  }
}

class _DiscussionsTab extends ConsumerWidget {
  const _DiscussionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(recentThreadsProvider);

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(recentThreadsProvider)),
      data: (threads) {
        if (threads.isEmpty) {
          return const EmptyStateView(
            icon: Icons.forum,
            title: 'No Discussions',
            subtitle: 'Start a conversation about a book!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceVariant),
          itemBuilder: (context, i) {
            final t = threads[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.title, style: AppTextStyles.titleLarge),
              subtitle: Text('${t.replyCount} replies', style: AppTextStyles.bodyMedium),
              onTap: () => context.push('/thread/${t.id}', extra: t),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
          },
        );
      },
    );
  }
}

class _BattlesTab extends ConsumerWidget {
  const _BattlesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battlesAsync = ref.watch(userBattlesProvider);

    return battlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(userBattlesProvider)),
      data: (battles) {
        if (battles.isEmpty) {
          return const EmptyStateView(
            icon: Icons.swords,
            title: 'No Active Battles',
            subtitle: 'Challenge a friend to a reading race!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: battles.length,
          itemBuilder: (context, i) {
            final b = battles[i];
            return Card(
              color: AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Battle vs ${b.rivalId.substring(0, 5)}...', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: b.challengerPage / (b.challengerPage + b.rivalPage + 1),
                      backgroundColor: AppColors.purpleMuted,
                      color: AppColors.amber,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
""".strip())


# ==========================================
# 4. PROFILE SCREEN UI
# ==========================================

w('lib/features/profile/presentation/screens/profile_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.amberMuted,
                    child: Text(
                      user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : 'U',
                      style: AppTextStyles.displayMedium.copyWith(color: AppColors.amber),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(user.userMetadata?['full_name'] ?? 'Book Lover', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  Text(user.email ?? '', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: Spacing.xl),
                  
                  // Stats Grid Placeholder
                  Row(
                    children: [
                      _buildStatCard('Books Read', '12'),
                      const SizedBox(width: Spacing.md),
                      _buildStatCard('Current Streak', '5 Days'),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Actions
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
                    tileColor: AppColors.surfaceVariant,
                    leading: const Icon(Icons.emoji_events, color: AppColors.amber),
                    title: Text('Reading Goals', style: AppTextStyles.titleLarge),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: () {},
                  ),
                  const SizedBox(height: Spacing.sm),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
                    tileColor: AppColors.surfaceVariant,
                    leading: const Icon(Icons.person, color: AppColors.purple),
                    title: Text('Edit Profile', style: AppTextStyles.titleLarge),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: () {},
                  ),
                  const SizedBox(height: Spacing.xl),
                  
                  TextButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: RadiusSize.md,
          border: Border.all(color: AppColors.amber.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.amber)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}
""".strip())

print("Catch-up scripts generated successfully")
