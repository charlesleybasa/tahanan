import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
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
import '../../widgets/fields.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../project/project_screens.dart' show adjusted;
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
    unawaited(_camera.dispose());
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

/// Confirm booking (step 1 of 2), opened from a seller's booking QR.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    final u = p?.unit;
    const shape = ArchBorder(bottomRadius: 28);
    return Stack(
      children: [
        ScreenScroll(
          bottom: Spacing.tabBarClearance,
          children: [
            Row(
              children: [
                BackCircleButton(onTap: () => context.go(Screen.home)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm booking', style: Typo.outfit(19, Typo.semibold, Palette.text)),
                      Text('Step 1 of 2', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                    ],
                  ),
                ),
                const StatusPill('From seller QR', tone: PillTone.accepted, icon: TIcon.scan),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                height: 230,
                foregroundDecoration: ShapeDecoration(
                  shape: shape.copyWith(side: BorderSide(color: Palette.white(0.12))),
                ),
                child: ClipPath(
                  clipper: const ShapeBorderClipper(shape: shape),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Photo('photoPH', kenBurns: true),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Palette.night.o(0), Palette.night.o(0.85)],
                            stops: const [0.5, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(10)),
                          child: Text(u?.code ?? '', style: Typo.mono(12, Typo.semibold, Palette.ink)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).rise(1),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: IText(u?.brandName ?? '', style: Typo.h1(32)),
            ).rise(2),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const TIconView(TIcon.pin, size: 15, color: Palette.muted),
                  const SizedBox(width: 6),
                  Text(
                    '${u?.barangay ?? ''}, ${u?.location ?? ''}',
                    style: Typo.manrope(14, Typo.regular, Palette.muted),
                  ),
                ],
              ),
            ).rise(2),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusPill(u?.product ?? ''),
                  StatusPill(u?.block ?? ''),
                  StatusPill('${u?.floorArea ?? ''} sqm floor'),
                  StatusPill('${u?.lotArea ?? ''} sqm lot'),
                ],
              ),
            ).rise(3),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Glass(
                radius: 24,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                child: Column(
                  children: [
                    SummaryLine('Total contract price', u?.tcp ?? '', verticalPadding: 13),
                    const SummaryLine('Downpayment', 'None', valueColor: Palette.acceptedText, verticalPadding: 13),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Monthly amortization', style: Typo.manrope(14, Typo.regular, Palette.muted)),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: u?.monthly ?? '', style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                                TextSpan(
                                  text: ' · ${u?.term ?? ''}',
                                  style: Typo.manrope(14, Typo.semibold, Palette.subtle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 1,
                      child: ColoredBox(color: Palette.white(0.08)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Due today · Consultation fee',
                              style: Typo.manrope(14, Typo.extrabold, Palette.text),
                            ),
                          ),
                          Text(u?.consultationFee ?? '', style: Typo.outfit(20, Typo.bold, Palette.yellow)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).rise(4),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GlassCard(
                radius: 24,
                children: [
                  RowLayout(
                    children: [
                      InitialsAvatar(p?.initials ?? 'MS', size: 42),
                      RowText(title: p?.fullName ?? '', overline: 'Buyer'),
                      // TODO: API — edit buyer details on the booking (no edit screen in the design yet)
                      SizedBox(
                        height: 44,
                        child: Center(child: Text('Edit', style: Typo.manrope(13, Typo.extrabold, Palette.yellow))),
                      ),
                    ],
                  ),
                  const RowDivider(),
                  RowLayout(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
                        child: Text(u?.seller.initials ?? 'JD', style: Typo.outfit(16, Typo.bold, Palette.ink)),
                      ),
                      RowText(title: '${u?.seller.name ?? ''} · Homeful seller', overline: 'Assisted by'),
                    ],
                  ),
                ],
              ),
            ).rise(5),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CheckboxRow(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v),
                child: IText(
                  'I confirm the unit details above and agree to the reservation terms.',
                  style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.366 + 4 / 13),
                ),
              ),
            ).rise(6),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomCTABar(
            child: PrimaryButton('Continue to payment', onTap: () => context.go(const Screen(ScreenKind.payment))),
          ),
        ),
      ],
    );
  }
}

// MARK: Payment

/// Payment (step 2 of 2): method list → processing overlay → Paid.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'ew';
  bool _paying = false;
  Timer? _timer;

  static const _methods = [
    (id: 'ew', name: 'E-wallet', sub: 'Pay from your mobile wallet', icon: TIcon.wallet),
    (id: 'cc', name: 'Debit or credit card', sub: 'Visa, Mastercard, JCB', icon: TIcon.card),
    (id: 'ob', name: 'Online banking', sub: 'Transfer from your bank app', icon: TIcon.bank),
    (id: 'otc', name: 'Over the counter', sub: 'Pay at partner outlets', icon: TIcon.store),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pay() {
    // TODO: API — create a payment intent for the consultation fee and hand off to the selected provider.
    setState(() => _paying = true);
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go(const Screen(ScreenKind.paid));
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().profile?.unit;
    return Stack(
      children: [
        ScreenScroll(
          bottom: Spacing.tabBarClearance,
          children: [
            Row(
              children: [
                BackCircleButton(onTap: () => context.go(const Screen(ScreenKind.booking))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment', style: Typo.outfit(19, Typo.semibold, Palette.text)),
                      Text('Step 2 of 2', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                    ],
                  ),
                ),
                const TIconView(TIcon.lock, size: 15, color: Palette.acceptedText),
                const SizedBox(width: 6),
                Text('Secure', style: Typo.manrope(12, Typo.extrabold, Palette.acceptedText)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 34),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    const Positioned(
                      top: -30,
                      width: 260,
                      height: 160,
                      child: GlowPulse(child: ClosestSideGlow(Palette.yellow, 0.25)),
                    ),
                    Column(
                      children: [
                        Text('Amount due', style: Typo.manrope(13, Typo.bold, Palette.muted)),
                        const SizedBox(height: 4),
                        Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(
                                text: '₱10,000',
                                style: TextStyle(color: Palette.text),
                              ),
                              TextSpan(
                                text: '.00',
                                style: TextStyle(color: Palette.subtle),
                              ),
                            ],
                          ),
                          style: Typo.outfit(52, Typo.bold).copyWith(letterSpacing: -0.035 * 52),
                        ),
                        const SizedBox(height: 6),
                        Text('Consultation fee · ${u?.code ?? ''}', style: Typo.mono(12, Typo.medium, Palette.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ).rise(1),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text('Pay with', style: Typo.sectionTitle(17)),
            ).rise(2),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  for (final (i, m) in _methods.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _methodRow(m.id, m.name, m.sub, m.icon),
                  ],
                ],
              ),
            ).rise(3),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomCTABar(
            child: PrimaryButton(
              'Pay ${u?.consultationFee ?? '₱10,000.00'}',
              icon: TIcon.lock,
              iconSize: 18,
              onTap: _pay,
            ),
          ),
        ),
        if (_paying)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ColoredBox(
                color: Palette.deep.o(0.82),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spinner(size: 56, lineWidth: 4),
                    const SizedBox(height: 18),
                    Text('Processing payment…', style: Typo.manrope(16, Typo.extrabold, Palette.text)),
                  ],
                ),
              ),
            ),
          ).fadeIn(),
      ],
    );
  }

  Widget _methodRow(String id, String name, String sub, TIcon icon) {
    final on = _method == id;
    return Pressable(
      onTap: () => setState(() => _method = id),
      semanticLabel: name,
      child: Container(
        decoration: BoxDecoration(
          color: on ? Palette.yellow.o(0.08) : Palette.white(0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? Palette.yellow : Palette.white(0.1),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: RowLayout(
          children: [
            IconTile(icon: icon, tint: Palette.yellow, background: Palette.white(0.08)),
            RowText(title: name, subtitle: sub, subtitleSize: 12, subtitleColor: Palette.subtle),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: on ? Palette.yellow : Palette.white(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: on
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
                    ).pop()
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: Paid

class PaidScreen extends StatefulWidget {
  const PaidScreen({super.key});

  @override
  State<PaidScreen> createState() => _PaidScreenState();
}

class _PaidScreenState extends State<PaidScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.heavyImpact());
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().profile?.unit;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Timeline(
              builder: (_, t) => Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: top + 90 - 54,
                    child: LoopingArchRing(t: t, width: 320, height: 360, color: Palette.green.o(0.45), delay: 0),
                  ),
                  Positioned(
                    top: top + 40 - 54,
                    child: LoopingArchRing(t: t, width: 460, height: 480, color: Palette.yellow.o(0.3), delay: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        ScreenScroll(
          horizontal: 24,
          top: 150 - 54,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Palette.green.o(0.35), blurRadius: 40)],
                    ),
                    child: CheckDisc(
                      size: 116,
                      iconSize: 54,
                      color: Palette.green,
                      halos: [(16, Palette.green.o(0.16))],
                    ),
                  ).pop(),
                  const SizedBox(height: 44),
                  Text('SALAMAT!', style: Typo.eyebrow).rise(3),
                  const SizedBox(height: 10),
                  IText('Payment received', style: Typo.h1(38)).rise(4),
                  const SizedBox(height: 12),
                  IText(
                    'Your unit at ${u?.brandName ?? 'Pasinaya Homes'} ${(u?.location ?? 'Ternate').split(',').first} is reserved. We emailed your receipt.',
                    textAlign: TextAlign.center,
                    style: Typo.mutedBody(),
                  ).rise(5),
                  const SizedBox(height: 24),
                  Glass(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                    child: Column(
                      children: [
                        SummaryLine('Amount', u?.consultationFee ?? ''),
                        SummaryLine('Reference no.', u?.referenceNo ?? '', divider: false, mono: true),
                      ],
                    ),
                  ).rise(6),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      PrimaryButton('Back to home', icon: TIcon.home, onTap: () => context.go(Screen.home)),
                      const SizedBox(height: 10),
                      GhostButton('Upload my requirements', onTap: () => context.go(Screen.application)),
                    ],
                  ).rise(7),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
