import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/itext.dart';

/// Darkens an image like SwiftUI `.brightness(b)` (b < 0) and optionally boosts saturation.
Widget adjusted(Widget child, {double brightness = 0, double saturation = 1}) {
  final s = saturation;
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final b = brightness * 255;
  return ColorFiltered(
    colorFilter: ColorFilter.matrix([
      lr * (1 - s) + s,
      lg * (1 - s),
      lb * (1 - s),
      0,
      b,
      lr * (1 - s),
      lg * (1 - s) + s,
      lb * (1 - s),
      0,
      b,
      lr * (1 - s),
      lg * (1 - s),
      lb * (1 - s) + s,
      0,
      b,
      0,
      0,
      0,
      1,
      0,
    ]),
    child: child,
  );
}

// MARK: Brand

class BrandScreen extends StatelessWidget {
  const BrandScreen({super.key, required this.brandIndex});

  final int brandIndex;

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AppState>().brands;
    if (brands.isEmpty) return const SizedBox.shrink();
    final b = brandIndex < brands.length ? brands[brandIndex] : brands.first;
    final top = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(context, b, top),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.gutter, 8, Spacing.gutter, 60),
            child: _content(context, b),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Brand b, double top) {
    return SizedBox(
      height: 440,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Photo(b.image, kenBurns: true),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Palette.night.o(0.45), Palette.night.o(0), Palette.night.o(0.2), Palette.night],
                  stops: const [0, 0.26, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(b.product, background: Palette.yellow, foreground: Palette.ink).rise(),
                  const SizedBox(height: 12),
                  IText(b.name, style: Typo.h1(44)).rise(1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const TIconView(TIcon.pin, size: 15, color: Palette.soft),
                      const SizedBox(width: 6),
                      Text(b.heroLocationLabel, style: Typo.manrope(14, Typo.semibold, Palette.soft)),
                    ],
                  ).rise(2),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: top,
              child: Row(
                children: [
                  IconCircleButton(
                    TIcon.arrowLeft,
                    label: 'Back',
                    background: Palette.night.o(0.5),
                    blur: true,
                    onTap: () => context.go(Screen.home),
                  ),
                  const Spacer(),
                  // TODO: API — saved homes (no saved list in the design yet)
                  IconCircleButton(
                    TIcon.heart,
                    label: 'Save',
                    background: Palette.night.o(0.5),
                    blur: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Brand b) {
    Widget stat(String label, String value, [Color color = Palette.text]) => Expanded(
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Typo.manrope(10, Typo.extrabold, Palette.subtle).copyWith(letterSpacing: 0.6)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: Typo.outfit(17, Typo.bold, color)),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            stat('STARTS AT', b.from, Palette.yellow),
            const SizedBox(width: 8),
            stat('MIN. GMI', b.gmi),
            const SizedBox(width: 8),
            stat('MONTHLY', b.monthly),
          ],
        ).rise(3),
        const SizedBox(height: 18),
        IText(
          b.description,
          style: Typo.manrope(15, Typo.regular, Palette.muted).copyWith(height: 1.366 + 0.35),
        ).rise(4),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Choose a location', style: Typo.sectionTitle())),
            Text('Tap to view slides', style: Typo.manrope(13, Typo.bold, Palette.subtle)),
          ],
        ).rise(5),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final (i, loc) in b.locations.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              Pressable(
                onTap: () => context.go(Screen.location(brandIndex, i)),
                semanticLabel: '${loc.name}, ${loc.barangay}',
                child: Glass(
                  padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                  child: Row(
                    children: [
                      ClipPath(
                        clipper: const ShapeBorderClipper(shape: ArchBorder(bottomRadius: 12)),
                        child: SizedBox(width: 58, height: 70, child: Photo(b.image)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.name, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                            const SizedBox(height: 2),
                            Text(loc.barangay, style: Typo.manrope(12, Typo.regular, Palette.subtle)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                StatusPill('${loc.floorArea} sqm', height: 22),
                                const SizedBox(width: 6),
                                StatusPill('TCP ${loc.tcp}', tone: PillTone.reviewed, height: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Chevron(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ).rise(6),
      ],
    );
  }
}

// MARK: Location story

enum SlideKind { hero, video, map, home, invest }

/// Full-screen location stories: Hero, Video, Site plan, The home, Investment.
/// Auto-advances every 6 s; tap left/right to go back/forward, hold to pause.
class LocationStoryScreen extends StatefulWidget {
  const LocationStoryScreen({super.key, required this.brandIndex, required this.locationIndex});

  final int brandIndex, locationIndex;

  @override
  State<LocationStoryScreen> createState() => _LocationStoryScreenState();
}

class _LocationStoryScreenState extends State<LocationStoryScreen> with SingleTickerProviderStateMixin {
  int _slide = 0;
  bool _gallery = false;
  bool _paused = false;
  DateTime? _pressStart;

  /// Progress of the running segment, 0…1 over 6 s.
  late final _progress = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _slide < SlideKind.values.length - 1) _set(_slide + 1);
    })
    ..forward();

  SlideKind get _kind => SlideKind.values[_slide];

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _set(int i) {
    setState(() => _slide = i.clamp(0, SlideKind.values.length - 1));
    _progress
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AppState>().brands;
    if (brands.isEmpty) return const SizedBox.shrink();
    final b = widget.brandIndex < brands.length ? brands[widget.brandIndex] : brands.first;
    final l = widget.locationIndex < b.locations.length ? b.locations[widget.locationIndex] : b.locations.first;
    return ColoredBox(
      color: Palette.deep,
      child: _gallery
          ? KeyedSubtree(
              key: const ValueKey('gallery'),
              child: _ScreenIn(
                child: GalleryScreen(
                  brand: b,
                  location: l,
                  onBack: () {
                    setState(() => _gallery = false);
                    _set(_slide);
                  },
                ),
              ),
            )
          : _story(b, l),
    );
  }

  Widget _story(Brand b, Location l) {
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(key: ValueKey(_slide), child: _image(b)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.deep.o(0.7), Palette.deep.o(0), Palette.deep.o(0.1), Palette.deep.o(0.92), Palette.deep],
              stops: const [0, 0.22, 0.48, 0.78, 1],
            ),
          ),
        ),
        if (_kind == SlideKind.map)
          const CssRadialGradient(
            rx: 0.9,
            ry: 0.6,
            cx: 0.5,
            cy: 0.3,
            colors: [Color(0xFF12305E), Palette.deep],
            stops: [0, 0.75],
          ).fadeIn(),
        _tapZones(insets),
        if (_kind == SlideKind.video) _playButton(insets.top),
        if (_kind == SlideKind.map)
          Positioned(
            left: 20,
            right: 20,
            top: insets.top + 128 - 54,
            child: KeyedSubtree(key: ValueKey(_slide), child: const SitePlanCard().rise(1)),
          ),
        Positioned.fill(
          child: Column(
            children: [
              SizedBox(height: insets.top),
              _segments(),
              const SizedBox(height: 12),
              _topBar(b, l),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, insets.bottom),
                child: KeyedSubtree(key: ValueKey(_slide), child: _caption(b, l)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _image(Brand b) {
    return switch (_kind) {
      SlideKind.map => const SizedBox.shrink(),
      SlideKind.invest => adjusted(blurred(3, Photo(b.image, kenBurns: true)), brightness: -0.45).fadeIn(),
      SlideKind.video => Photo(b.streetImage, kenBurns: true).fadeIn(),
      SlideKind.home => const Photo('photoInterior', kenBurns: true).fadeIn(),
      SlideKind.hero => Photo(b.image, kenBurns: true).fadeIn(),
    };
  }

  /// Between 120 pt from the top and 300 pt from the bottom: left 35% = back, right 65% = forward. Hold pauses.
  Widget _tapZones(EdgeInsets insets) => Positioned(
    left: 0,
    right: 0,
    top: insets.top + 120 - 54,
    bottom: insets.bottom + 300 - 34,
    child: Semantics(
      label: 'Slide ${_slide + 1} of 5',
      onIncrease: () => _set(_slide + 1),
      onDecrease: () => _set(_slide - 1),
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _pressStart = DateTime.now();
            _paused = true;
            _progress.stop();
          },
          onLongPressStart: (_) => _progress.stop(),
          onLongPressEnd: (_) => _resume(),
          onTapCancel: _resume,
          onTapUp: (d) {
            final held = DateTime.now().difference(_pressStart ?? DateTime.now()).inMilliseconds;
            _resume();
            if (held >= 300) return;
            if (d.localPosition.dx < box.maxWidth * 0.35) {
              _set(_slide - 1);
            } else if (_slide < SlideKind.values.length - 1) {
              _set(_slide + 1);
            }
          },
        ),
      ),
    ),
  );

  void _resume() {
    _pressStart = null;
    if (_paused) {
      _paused = false;
      if (_progress.value < 1) _progress.forward();
    }
  }

  Widget _playButton(double top) => Positioned(
    left: 0,
    right: 0,
    top: top + 300 - 54,
    child: Center(
      child: KeyedSubtree(
        key: ValueKey(_slide),
        child: SizedBox.square(
          dimension: 92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PulseRing(color: Palette.white(0.7)),
              // TODO: API — project video URL from the CMS slide
              Semantics(
                label: 'Play project video',
                button: true,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Palette.white(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Palette.white(0.09), strokeAlign: BorderSide.strokeAlignInside),
                      ),
                      alignment: Alignment.center,
                      child: const TIconView(TIcon.play, size: 34, color: Color(0xFFFFFFFF)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).pop(),
      ),
    ),
  );

  Widget _segments() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 52 - 54 + 2, 16, 0),
    child: AnimatedBuilder(
      animation: _progress,
      builder: (_, _) => Row(
        children: [
          for (var k = 0; k < SlideKind.values.length; k++) ...[
            if (k > 0) const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 3,
                child: LayoutBuilder(
                  builder: (_, box) => Stack(
                    children: [
                      DecoratedBox(
                        decoration: ShapeDecoration(color: Palette.white(0.25), shape: const StadiumBorder()),
                        child: const SizedBox.expand(),
                      ),
                      if (k < _slide)
                        const DecoratedBox(
                          decoration: ShapeDecoration(color: Color(0xFFFFFFFF), shape: StadiumBorder()),
                          child: SizedBox.expand(),
                        )
                      else if (k == _slide)
                        Container(
                          width: box.maxWidth * _progress.value,
                          decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _topBar(Brand b, Location l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        IconCircleButton(
          TIcon.close,
          label: 'Close',
          background: Palette.deep.o(0.45),
          blur: true,
          onTap: () => context.go(Screen.brand(widget.brandIndex)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.name, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
              Text(l.name, style: Typo.manrope(12, Typo.regular, Palette.soft)),
            ],
          ),
        ),
        Pressable(
          onTap: () => setState(() => _gallery = true),
          semanticLabel: 'Gallery',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: Palette.deep.o(0.45),
                  shape: StadiumBorder(side: hairline(Palette.white(0.2))),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TIconView(TIcon.grid, size: 16, color: Palette.text),
                    const SizedBox(width: 8),
                    Text('Gallery', style: Typo.manrope(13, Typo.extrabold, Palette.text)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _caption(Brand b, Location l) {
    final body = Typo.manrope(16, Typo.regular, Palette.soft).copyWith(height: 1.366 + 0.5);
    final children = switch (_kind) {
      SlideKind.hero => [
        Text('WELCOME TO', style: Typo.eyebrow).rise(),
        const SizedBox(height: 10),
        IText(b.name, style: Typo.h1(46)).rise(1),
        const SizedBox(height: 10),
        Row(
          children: [
            const TIconView(TIcon.pin, size: 16, color: Palette.soft),
            const SizedBox(width: 6),
            Text('${l.barangay}, ${l.name}', style: Typo.manrope(16, Typo.regular, Palette.soft)),
          ],
        ).rise(2),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              b.product,
              background: Palette.white(0.12),
              foreground: const Color(0xFFFFFFFF),
              height: 32,
              horizontalPadding: 12,
            ),
            StatusPill(
              'TCP ${l.tcp}',
              background: Palette.yellow,
              foreground: Palette.ink,
              height: 32,
              horizontalPadding: 12,
            ),
          ],
        ).rise(3),
      ],
      SlideKind.video => [
        Text('PROJECT VIDEO', style: Typo.eyebrow).rise(),
        const SizedBox(height: 10),
        IText('Take the tour', style: Typo.h1(42)).rise(1),
        const SizedBox(height: 10),
        Text('Walk the streets of ${b.name} ${l.name} before you visit.', style: body).rise(2),
      ],
      SlideKind.map => [
        Text('SITE PLAN', style: Typo.eyebrow).rise(),
        const SizedBox(height: 10),
        IText('Find your lot', style: Typo.h1(42)).rise(1),
        const SizedBox(height: 10),
        Text('Yellow lots are open. Your seller confirms the final lot when you book.', style: body).rise(2),
      ],
      SlideKind.home => [
        Text('THE HOME', style: Typo.eyebrow).rise(),
        const SizedBox(height: 10),
        IText(b.product, style: Typo.h1(40)).rise(1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _areaTile('FLOOR AREA', l.floorArea)),
            const SizedBox(width: 8),
            Expanded(child: _areaTile('LOT AREA', l.lotArea)),
          ],
        ).rise(2),
      ],
      SlideKind.invest => [
        Text('INVESTMENT', style: Typo.eyebrow).rise(),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Own it from ${l.monthlyAmortization}'),
              TextSpan(text: '/mo', style: Typo.outfit(20, Typo.semibold, Palette.muted)),
            ],
          ),
          style: Typo.h1(38),
        ).rise(1),
        const SizedBox(height: 16),
        Glass(
          fill: Palette.white(0.06),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
            children: [
              SummaryLine('Total contract price', l.tcp),
              const SummaryLine('Consultation fee', '₱10,000'),
              const SummaryLine('Downpayment', 'None needed', valueColor: Palette.acceptedText),
              SummaryLine('Required GMI', l.gmi, divider: false),
            ],
          ),
        ).rise(2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: PrimaryButton('Scan seller QR', icon: TIcon.scan, onTap: () => context.go(Screen.scan)),
            ),
            const SizedBox(width: 10),
            IconCircleButton(
              TIcon.help,
              label: 'Ask a question',
              size: 56,
              iconSize: 22,
              onTap: () => context.go(const Screen(ScreenKind.newTicket)),
            ),
          ],
        ).rise(3),
      ],
    };
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _areaTile(String label, String value) => Glass(
    radius: 18,
    fill: Palette.deep.o(0.5),
    blur: true,
    padding: const EdgeInsets.all(14),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Typo.manrope(11, Typo.extrabold, Palette.muted)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$value ', style: Typo.outfit(26, Typo.semibold, Palette.text)),
                TextSpan(text: 'sqm', style: Typo.outfit(14, Typo.semibold, Palette.muted)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Plays the `.scr` entrance on a subtree (fade, scale 1.035 → 1, blur 10 → 0, 0.75 s).
class _ScreenIn extends StatelessWidget {
  const _ScreenIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.screen,
    curve: Motion.standard,
    child: child,
    builder: (_, p, c) => p >= 1
        ? c!
        : Opacity(
            opacity: p.clamp(0, 1),
            child: Transform.scale(scale: mix(1.035, 1, p), child: blurred(10 * (1 - p), c!)),
          ),
  );
}

/// The drawn lot map: four blocks of 18 lots (open / reserved / sold), main road, highlighted Block 12 · Lot 7.
class SitePlanCard extends StatelessWidget {
  const SitePlanCard({super.key});

  static const _blocks = [
    ('BLOCK 10', 'YBYBSYYSYYSBSBSYSS'),
    ('BLOCK 12', 'BSSYSBHYSBSSSSYSBS'),
    ('BLOCK 14', 'SYYYSBSYBYYBBSSSSS'),
    ('BLOCK 16', 'SYSSSBSYSBYYSSYSYY'),
  ];

  @override
  Widget build(BuildContext context) {
    final legend = Typo.manrope(11, Typo.bold, Palette.muted);
    return Semantics(
      label: 'Site plan. Your lot is Block 12, Lot 7. Yellow lots are open, blue reserved, grey sold.',
      excludeSemantics: true,
      child: Glass(
        radius: 26,
        fill: const Color(0xB30D1C38),
        blur: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(0),
                    const SizedBox(height: 14),
                    _block(1),
                    const SizedBox(height: 14),
                    Container(
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Palette.white(0.06), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'MAIN ROAD',
                        style: Typo.manrope(10, Typo.extrabold, Palette.subtle).copyWith(letterSpacing: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _block(2),
                    const SizedBox(height: 14),
                    _block(3),
                  ],
                ),
                Positioned(
                  left: 150,
                  top: 72,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF000000).o(0.5), blurRadius: 10, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Text('Block 12 · Lot 7', style: Typo.manrope(11, Typo.extrabold, Palette.ink)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: LegendDot(color: Palette.yellow, label: 'Open', size: 10, radius: 3, style: legend),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: LegendDot(color: Palette.blue, label: 'Reserved', size: 10, radius: 3, style: legend),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: LegendDot(color: Palette.white(0.2), label: 'Sold', size: 10, radius: 3, style: legend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(int i) {
    final (name, lots) = _blocks[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Typo.manrope(10, Typo.extrabold, Palette.subtle).copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 6),
        for (var r = 0; r < 2; r++) ...[
          if (r > 0) const SizedBox(height: 4),
          Row(
            children: [
              for (var c = 0; c < 9; c++) ...[
                if (c > 0) const SizedBox(width: 4),
                Expanded(child: _lot(lots[r * 9 + c])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _lot(String ch) {
    final radius = BorderRadius.circular(4);
    return switch (ch) {
      'Y' => Container(
        height: 22,
        decoration: BoxDecoration(color: Palette.yellow.o(0.85), borderRadius: radius),
      ),
      'B' => Container(
        height: 22,
        decoration: BoxDecoration(color: Palette.blue, borderRadius: radius),
      ),
      'H' => SizedBox(
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.yellow,
                  borderRadius: radius,
                  border: Border.all(
                    color: const Color(0xFFFFFFFF),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  boxShadow: [BoxShadow(color: Palette.yellow.o(0.7), blurRadius: 9)],
                ),
              ),
            ),
            const Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: PulseRing(color: Palette.yellow, cornerRadius: 6),
            ),
          ],
        ),
      ),
      _ => Container(
        height: 22,
        decoration: BoxDecoration(color: Palette.white(0.14), borderRadius: radius),
      ),
    };
  }
}

// MARK: Gallery

/// Location gallery with filter chips; empty categories show the "Upload in admin" placeholder.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.brand, required this.location, required this.onBack});

  final Brand brand;
  final Location location;
  final VoidCallback onBack;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

typedef _Tile = ({String label, String? image, int span, String category});

class _GalleryScreenState extends State<GalleryScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Facade', 'Amenities', 'Interior', 'Nearby', 'Site map'];

  // TODO: API — gallery items per location come from the CMS (admin uploads).
  List<_Tile> get _tiles => [
    (label: 'Facade', image: widget.brand.image, span: 2, category: 'Facade'),
    (label: 'Interior', image: 'photoInterior', span: 1, category: 'Interior'),
    (label: 'Amenities', image: null, span: 1, category: 'Amenities'),
    (label: 'Streetscape', image: widget.brand.streetImage, span: 1, category: 'Facade'),
    (label: 'Nearby destinations', image: null, span: 2, category: 'Nearby'),
    (label: 'Sales map', image: null, span: 1, category: 'Site map'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.night,
      child: ScreenScroll(
        children: [
          Row(
            children: [
              BackCircleButton(label: 'Back to slides', onTap: widget.onBack),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.brand.name, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                    Text('${widget.location.name} · Gallery', style: Typo.manrope(12, Typo.regular, Palette.muted)),
                  ],
                ),
              ),
              Pressable(
                onTap: widget.onBack,
                semanticLabel: 'Slides',
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: ShapeDecoration(
                    color: Palette.white(0.06),
                    shape: StadiumBorder(side: hairline(Palette.white(0.18))),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TIconView(TIcon.play, size: 14, color: Palette.text),
                      const SizedBox(width: 8),
                      Text('Slides', style: Typo.manrope(13, Typo.extrabold, Palette.text)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: EdgeScroller(
              height: 40,
              children: [
                for (final f in _filters)
                  FilterChipButton(f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
              ],
            ),
          ).rise(1),
          Padding(padding: const EdgeInsets.only(top: 16), child: _grid()).rise(2),
        ],
      ),
    );
  }

  Widget _grid() {
    final t = _tiles;
    if (_filter == 'All') {
      // CSS grid with 150 pt rows: Facade spans 2 rows on the left, Nearby spans 2 on the right.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [_tile(t[0]), const SizedBox(height: 10), _tile(t[3]), const SizedBox(height: 10), _tile(t[5])],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [_tile(t[1]), const SizedBox(height: 10), _tile(t[2]), const SizedBox(height: 10), _tile(t[4])],
            ),
          ),
        ],
      );
    }
    final items = t.where((x) => x.category == _filter).toList();
    return LayoutBuilder(
      builder: (_, box) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final x in items) SizedBox(width: (box.maxWidth - 10) / 2, child: _tile(x, forceSpan: 1))],
      ),
    );
  }

  Widget _tile(_Tile t, {int? forceSpan}) {
    final span = (forceSpan ?? t.span).toDouble();
    return SizedBox(
      height: 150 * span + 10 * (span - 1),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.panel),
            if (t.image != null)
              Photo(t.image!)
            else
              Stack(
                fit: StackFit.expand,
                children: [
                  const DiagonalStripes(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TIconView(TIcon.image, size: 26, color: Palette.ringIdle),
                      const SizedBox(height: 6),
                      Text('Upload in admin', style: Typo.manrope(11, Typo.extrabold, Palette.ringIdle)),
                    ],
                  ),
                ],
              ),
            Positioned(
              left: 10,
              bottom: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: StatusPill(t.label, background: Palette.deep.o(0.65), foreground: const Color(0xFFFFFFFF)),
                ),
              ),
            ),
            DecoratedBox(
              decoration: ShapeDecoration(shape: squircle(22, side: hairline(Palette.white(0.08)))),
            ),
          ],
        ),
      ),
    );
  }
}
