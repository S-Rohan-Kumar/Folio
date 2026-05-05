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
      Positioned(top: 0, left: 0, child: _Corner(size, thickness, const [CornerSide.top, CornerSide.left])),
      Positioned(top: 0, right: 0, child: _Corner(size, thickness, const [CornerSide.top, CornerSide.right])),
      Positioned(bottom: 0, left: 0, child: _Corner(size, thickness, const [CornerSide.bottom, CornerSide.left])),
      Positioned(bottom: 0, right: 0, child: _Corner(size, thickness, const [CornerSide.bottom, CornerSide.right])),
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

enum CornerSide { top, bottom, left, right }

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final List<CornerSide> sides;

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
  final List<CornerSide> sides;

  _CornerPainter(this.color, this.thickness, this.sides);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final top = sides.contains(CornerSide.top);
    final bottom = sides.contains(CornerSide.bottom);
    final left = sides.contains(CornerSide.left);
    final right = sides.contains(CornerSide.right);

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