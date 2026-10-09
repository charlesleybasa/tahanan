import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/itext.dart';

/// Where a Funnel / Seller app QR should take the buyer.
enum QRRoute {
  booking,
  payment;

  /// TODO: API — the real payload format comes from the Funnel/Seller app (e.g. a signed URL).
  /// For the demo, any code mentioning "pay" opens Payment; everything else opens Booking.
  static QRRoute parse(String payload) => payload.toLowerCase().contains('pay') ? payment : booking;
}

// MARK: Scan

/// QR scanner: live camera inside a dimmed surround, animated yellow corners and scan line.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _frameTop = 200.0;
  static const _frameSize = 280.0;

  late final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );
  bool _cameraReady = false;
  bool _torch = false;
  QRRoute? _hit;
  Timer? _leave;

  @override
  void initState() {
    super.initState();
    unawaited(_startCamera());
  }

  Future<void> _startCamera() async {
    try {
      await _camera.start();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      // No camera (simulator) or permission denied: keep the decorative viewfinder.
    }
  }

  @override
  void dispose() {
    _leave?.cancel();
    // Throws if the camera never started (simulator, permission denied); nothing to release then.
    _camera.dispose().catchError((Object _) {});
    super.dispose();
  }

  void _found(QRRoute route) {
    if (_hit != null) return;
    setState(() => _hit = route);
    _leave = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) context.go(Screen(route == QRRoute.payment ? ScreenKind.payment : ScreenKind.booking));
    });
  }

  Future<void> _fromPhoto() async {
    final state = context.read<AppState>();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    String? code;
    try {
      code = (await _camera.analyzeImage(img.path))?.barcodes.firstOrNull?.rawValue;
    } catch (_) {}
    if (code != null) {
      _found(QRRoute.parse(code));
    } else {
      state.showToast('No QR code found in that photo', icon: TIcon.info, tint: Palette.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final frame = Rect.fromLTWH(
          (box.maxWidth - _frameSize) / 2,
          _frameTop - 54 + insets.top,
          _frameSize,
          _frameSize,
        );
        return ColoredBox(
          color: Palette.scanGround,
          child: Stack(
            children: [
              Positioned.fill(
                child: _cameraReady
                    ? MobileScanner(
                        controller: _camera,
                        fit: BoxFit.cover,
                        onDetect: (c) {
                          final v = c.barcodes.firstOrNull?.rawValue;
                          if (v != null) _found(QRRoute.parse(v));
                        },
                      )
                    : OverflowBox(
                        maxWidth: box.maxWidth + 80,
                        maxHeight: box.maxHeight + 80,
                        child: adjusted(blurred(22, const Photo('photoRow')), brightness: -0.55, saturation: 1.2),
                      ),
              ),
              Positioned.fill(
                child: DimmedSurround(hole: frame, radius: 36, color: const Color(0x8C02060E)),
              ),
              Positioned.fromRect(rect: frame, child: _viewfinder()),
              Positioned(left: 30, right: 30, top: 506 - 54 + insets.top, child: _message()),
              Positioned(left: 0, right: 0, top: insets.top, child: _topBar()),
              Positioned(left: 12, right: 12, bottom: insets.bottom + 16 - 34 + 8, child: _tryPanel()),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        IconCircleButton(
          TIcon.close,
          label: 'Close scanner',
          background: Palette.white(0.12),
          onTap: () => context.go(Screen.home),
        ),
        Expanded(
          child: Center(child: Text('Scan QR', style: Typo.outfit(18, Typo.semibold, Palette.text))),
        ),
        IconCircleButton(
          TIcon.bolt,
          label: 'Toggle flashlight',
          background: _torch ? Palette.yellow.o(0.35) : Palette.white(0.12),
          onTap: () {
            setState(() => _torch = !_torch);
            if (_cameraReady) unawaited(_camera.toggleTorch());
          },
        ),
      ],
    ),
  );

  Widget _viewfinder() {
    final color = _hit == null ? Palette.yellow : Palette.green;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_cameraReady)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(8 * math.pi / 180)
                ..rotateZ(-3 * math.pi / 180),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF000000).o(0.5), blurRadius: 25, offset: const Offset(0, 20)),
                  ],
                ),
                child: const DecorativeQR(),
              ),
            ),
          ).fadeIn(),
        Breathing(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: const Duration(milliseconds: 300),
            builder: (_, c, _) => ScanCorners(length: 52, lineWidth: 5, radius: 30, color: c!),
          ),
        ),
        if (_hit == null)
          const ScanLine()
        else ...[
          DecoratedBox(
            decoration: BoxDecoration(color: Palette.green.o(0.25), borderRadius: BorderRadius.circular(36)),
          ).fadeIn(0.3),
          Center(
            child: CheckDisc(size: 86, iconSize: 40, color: Palette.green, halos: [(12, Palette.green.o(0.25))]).pop(),
          ),
        ],
      ],
    );
  }

  Widget _message() => _hit != null
      ? IText(
          _hit == QRRoute.payment ? 'Payment QR found · opening payment' : 'Booking QR found · opening booking',
          textAlign: TextAlign.center,
          style: Typo.manrope(16, Typo.extrabold, Palette.acceptedText),
        ).fadeIn()
      : IText(
          'Point your camera at the QR from your\nHomeful seller or the Funnel app.',
          textAlign: TextAlign.center,
          style: Typo.manrope(15, Typo.regular, Palette.softer).copyWith(height: 1.366 + 7 / 15),
        );

  Widget _tryPanel() => SheetUp(
    child: Glass(
      radius: 30,
      fill: const Color(0xD90D1C38),
      blur: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROTOTYPE · TRY A CODE', style: Typo.overline()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tryButton(TIcon.home, 'Booking QR', () => _found(QRRoute.booking))),
              const SizedBox(width: 10),
              Expanded(child: _tryButton(TIcon.wallet, 'Payment QR', () => _found(QRRoute.payment))),
            ],
          ),
          const SizedBox(height: 10),
          GhostButton('Upload QR from photos', icon: TIcon.image, height: 48, onTap: _fromPhoto),
        ],
      ),
    ),
  );

  Widget _tryButton(TIcon icon, String title, VoidCallback onTap) => Pressable(
    onTap: onTap,
    semanticLabel: title,
    child: Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Palette.white(0.06), borderRadius: BorderRadius.circular(20)),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.white(0.12), strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TIconView(icon, color: Palette.yellow),
          const SizedBox(height: 4),
          Text(title, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
        ],
      ),
    ),
  );
}

// MARK: Booking
