import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── discover_screen.dart (book search UI) ──────────────────────────────
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
                  onPressed: () {},
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
          _GenreGrid(),
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
          onTap: () {},
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

# ── barcode_scan_screen.dart ───────────────────────────────────────────
w('lib/features/book_search/presentation/screens/barcode_scan_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../library/presentation/screens/book_detail_screen.dart';
import '../providers/book_search_provider.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _isbnController = TextEditingController();
  bool _scanning = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    HapticFeedback.lightImpact();
    setState(() { _scanning = false; _loading = true; });

    await _lookupIsbn(raw);
  }

  Future<void> _lookupIsbn(String isbn) async {
    setState(() { _loading = true; _error = null; });
    try {
      final book = await ref.read(fetchBookByIsbnUseCaseProvider).call(isbn);
      if (!mounted) return;
      if (book == null) {
        setState(() { _error = 'No book found for ISBN: $isbn'; _loading = false; _scanning = true; });
      } else {
        setState(() => _loading = false);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scroll) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BookDetailScreen(book: book),
            ),
          ),
        );
        if (mounted) setState(() => _scanning = true);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; _scanning = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(context),
          const Spacer(),
          _buildViewfinder(),
          const SizedBox(height: Spacing.lg),
          _buildStatusArea(),
          const Spacer(),
          _buildManualEntry(),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(child: Center(
            child: Text('Scan Barcode', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          )),
          IconButton(
            onPressed: _controller.toggleTorch,
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, v, __) => Icon(
                v.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return SizedBox(
      width: 260,
      height: 160,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: RadiusSize.md,
            ),
          ),
          // Animated scan line
          if (_scanning)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: RadiusSize.md,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(height: 2, color: AppColors.amber)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .slideY(begin: -1, end: 1, duration: 1500.ms, curve: Curves.easeInOut),
                ),
              ),
            ),
          // Corner decorations
          ..._buildCorners(),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 3.0;
    return [
      Positioned(top: 0, left: 0, child: _Corner(size, thickness, [BorderSide.top, BorderSide.left])),
      Positioned(top: 0, right: 0, child: _Corner(size, thickness, [BorderSide.top, BorderSide.right])),
      Positioned(bottom: 0, left: 0, child: _Corner(size, thickness, [BorderSide.bottom, BorderSide.left])),
      Positioned(bottom: 0, right: 0, child: _Corner(size, thickness, [BorderSide.bottom, BorderSide.right])),
    ];
  }

  Widget _buildStatusArea() {
    if (_loading) {
      return Column(
        children: [
          const CircularProgressIndicator(color: AppColors.amber),
          const SizedBox(height: 12),
          Text('Looking up book…', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
        ],
      );
    }
    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: RadiusSize.md),
        child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
      ).animate().shake();
    }
    return Text('Point camera at a book barcode', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70));
  }

  Widget _buildManualEntry() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: RadiusSize.lg),
      child: Column(
        children: [
          Text('Or enter ISBN manually', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _isbnController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ISBN-10 or ISBN-13',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
                onPressed: () {
                  final isbn = _isbnController.text.trim();
                  if (isbn.isNotEmpty) _lookupIsbn(isbn);
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final List<BorderSide> sides;

  const _Corner(this.size, this.thickness, this.sides);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(AppColors.amber, thickness, sides),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final List<BorderSide> sides;

  _CornerPainter(this.color, this.thickness, this.sides);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final top = sides.contains(BorderSide.top);
    final bottom = sides.contains(BorderSide.bottom);
    final left = sides.contains(BorderSide.left);
    final right = sides.contains(BorderSide.right);

    if (top && left) {
      canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
    }
    if (top && right) {
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(0, 0), paint);
    }
    if (bottom && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
    if (bottom && right) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}
""".strip())

print("✅ DiscoverScreen + BarcodeScanScreen created.")
