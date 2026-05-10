import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. BOOK SEARCH & SCAN
# ==========================================

w('lib/features/book_search/presentation/screens/book_search_screen.dart', r"""
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/book_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/book_search_provider.dart';
import '../widgets/book_found_bottom_sheet.dart';

class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      ref.read(bookSearchNotifierProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(bookSearchNotifierProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(bookSearchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by title, author, or ISBN',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textHint),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _searchCtrl.text.isEmpty
          ? const EmptyStateView(
              icon: Icons.search,
              title: 'Search Books',
              subtitle: 'Find your next great read by title, author, or ISBN',
            )
          : searchState.when(
              loading: () => const BookGridShimmer(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => _onSearchChanged(_searchCtrl.text),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No results found',
                    subtitle: 'No books found for "${_searchCtrl.text}"',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(Spacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: Spacing.md,
                    mainAxisSpacing: Spacing.md,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      animationIndex: index,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BookFoundBottomSheet(book: book),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.qr_code_scanner, color: AppColors.background),
      ),
    );
  }
}
""".strip())

w('lib/features/book_search/presentation/screens/barcode_scan_screen.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/book_search_provider.dart';
import '../widgets/book_found_bottom_sheet.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _isbnCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _permanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _isbnCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _lookupIsbn(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _lookupIsbn(String isbn) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    try {
      final book = await ref.read(bookSearchNotifierProvider.notifier).searchByIsbn(isbn);
      if (mounted) Navigator.pop(context); // hide loading

      if (book != null) {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BookFoundBottomSheet(book: book),
          ).then((_) {
            if (mounted) setState(() => _isProcessing = false);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Book not found — try searching by title'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Search',
                textColor: AppColors.background,
                onPressed: () => context.go('/discover'),
              ),
            ),
          );
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.textHint),
              const SizedBox(height: Spacing.md),
              Text('Camera Access Required', style: AppTextStyles.headlineMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Pagebound needs camera access\nto scan book barcodes.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              if (_permanentlyDenied)
                AppButton(
                  label: 'Open Settings',
                  compact: true,
                  onPressed: () => openAppSettings(),
                )
              else
                AppButton(
                  label: 'Allow Camera',
                  compact: true,
                  onPressed: _checkPermission,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Custom Overlay
          Container(
            decoration: ShapeDecoration(
              shape: _ScannerOverlayShape(
                borderColor: AppColors.amber,
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 4,
                cutOutSize: 280,
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Scan Barcode',
                        style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // balance back button
                  ],
                ),
              ),
            ),
          ),

          // Manual Entry Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Enter ISBN manually',
                        controller: _isbnCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    AppButton(
                      label: 'Look Up',
                      compact: true,
                      onPressed: () {
                        if (_isbnCtrl.text.isNotEmpty) {
                          _lookupIsbn(_isbnCtrl.text.trim());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderRadius = 0,
    this.borderLength = 20,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    rect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize - 60, // making it slightly rectangular
    );
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;

    final Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize - 60,
    );

    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.quadraticBezierTo(cutOutRect.left, cutOutRect.top, cutOutRect.left + borderRadius, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.quadraticBezierTo(cutOutRect.right, cutOutRect.top, cutOutRect.right, cutOutRect.top + borderRadius);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.quadraticBezierTo(cutOutRect.right, cutOutRect.bottom, cutOutRect.right - borderRadius, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.quadraticBezierTo(cutOutRect.left, cutOutRect.bottom, cutOutRect.left, cutOutRect.bottom - borderRadius);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
""".strip())

# ==========================================
# 2. BOTTOM SHEETS
# ==========================================

w('lib/features/book_search/presentation/widgets/book_found_bottom_sheet.dart', r"""
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../library/presentation/widgets/shelf_picker_bottom_sheet.dart';
import '../../domain/entities/book.dart';

class BookFoundBottomSheet extends StatelessWidget {
  final Book book;

  const BookFoundBottomSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: RadiusSize.md,
                    child: CachedNetworkImage(
                      imageUrl: book.thumbnailUrl ?? '',
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        height: 150,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.book, color: AppColors.textHint, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          book.authors.isNotEmpty ? book.authors.join(', ') : 'Unknown Author',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.amber),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: [
                            if (book.pageCount != null) ...[
                              const Icon(Icons.menu_book, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${book.pageCount} p', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(width: Spacing.md),
                            ],
                            if (book.averageRating != null) ...[
                              const Icon(Icons.star, size: 14, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text('${book.averageRating}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              if (book.description != null && book.description!.isNotEmpty) ...[
                Text(
                  book.description!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.lg),
              ],
              AppButton(
                label: 'Add to Shelf',
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShelfPickerBottomSheet(book: book),
                  );
                },
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedAppButton(
                label: 'View Details',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/book/${book.id}', extra: book);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""".strip())

w('lib/features/library/presentation/widgets/shelf_picker_bottom_sheet.dart', r"""
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../book_search/domain/entities/book.dart';
import '../../domain/entities/user_book.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../providers/library_provider.dart';

class ShelfPickerBottomSheet extends ConsumerWidget {
  final Book book;

  const ShelfPickerBottomSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add to Shelf',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              _buildOption(context, ref, '📖 Reading Now', ReadingStatus.reading),
              _buildOption(context, ref, '🔖 Want to Read', ReadingStatus.wantToRead),
              _buildOption(context, ref, '✅ Finished', ReadingStatus.finished),
              _buildOption(context, ref, '✗ Did Not Finish', ReadingStatus.dnf),
              const SizedBox(height: Spacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, String title, ReadingStatus status) {
    return ListTile(
      title: Text(title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
      shape: RoundedRectangleBorder(borderRadius: RadiusSize.md),
      onTap: () async {
        final user = ref.read(currentUserProvider);
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in first'), backgroundColor: AppColors.error),
          );
          return;
        }

        try {
          await ref.read(libraryRemoteDataSourceProvider).addBookToLibrary(user.id, book, status);
          
          // Log XP directly using supabase client for now
          // (Phase 3 will build proper XP UseCase)
          await ref.read(supabaseClientProvider).from('xp_log').insert({
            'user_id': user.id,
            'action': 'book_added',
            'xp_earned': 10,
          });

          // Invalidate relevant providers
          ref.invalidate(libraryWantToReadProvider);
          ref.invalidate(libraryReadingProvider);
          ref.invalidate(libraryFinishedProvider);
          ref.invalidate(libraryDnfProvider);

          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to your library ✓'), backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding to shelf: $e'), backgroundColor: AppColors.error),
            );
          }
        }
      },
    );
  }
}
""".strip())

print("Phase 2 scripts generated successfully")
