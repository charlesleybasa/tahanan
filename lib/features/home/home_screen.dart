import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../discover/discover_widgets.dart';

/// Home dashboard — maps 1:1 to native `HomeView.swift`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    return ScreenScroll(
      bottom: Spacing.tabBarClearance,
      children: [
        _Header(initials: p?.initials ?? 'MS', firstName: p?.firstName ?? 'Maria').rise(),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Find your\n'),
                TextSpan(
                  text: 'tahanan.',
                  style: TextStyle(color: Palette.yellow),
                ),
              ],
            ),
            style: Typo.h1(42),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: _SectionHeader(
            title: 'Explore all brands',
            trailing: Tap(
              onTap: () => context.go(Screen.catalog),
              semanticLabel: 'See all ${state.brands.length} brands',
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Text('See all ${state.brands.length}', style: Typo.manrope(13, Typo.extrabold, Palette.yellow)),
                    const SizedBox(width: 2),
                    const TIconView(TIcon.chevronRight, size: 16, color: Palette.yellow),
                  ],
                ),
              ),
            ),
          ),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _BrandCarousel(brands: state.brands),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: JourneyCard(todo: state.todoCount, unit: p?.unit, onTap: () => context.go(Screen.application)),
        ).rise(4),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Tap(
            onTap: () => state.showSheet(SheetKind.link),
            semanticLabel: 'Link an existing account',
            child: Glass(
              child: RowLayout(
                children: [
                  IconTile(icon: TIcon.link, tint: Palette.submittedText, background: Palette.blue.o(0.25)),
                  const RowText(
                    title: 'Link an existing account',
                    subtitle: 'Bought with Homeful before? See it here.',
                  ),
                  const Chevron(),
                ],
              ),
            ),
          ),
        ).rise(5),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: _SectionHeader(
            title: 'Transactions',
            // TODO: API — full transaction history (no destination in the design yet)
            trailing: SizedBox(
              height: 44,
              child: Center(child: Text('See all', style: Typo.manrope(13, Typo.extrabold, Palette.yellow))),
            ),
          ),
        ).rise(6),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GlassCard(
            children: [
              for (final (i, tx) in state.transactions.indexed) ...[
                if (i > 0) const RowDivider(),
                TransactionRow(tx: tx),
              ],
            ],
          ),
        ).rise(7),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.initials, required this.firstName});

  final String initials, firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(initials, ring: hairline(Palette.yellow.o(0.8), 2)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Magandang umaga,', style: Typo.manrope(13, Typo.semibold, Palette.muted)),
              Text(firstName, style: Typo.outfit(19, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.19)),
            ],
          ),
        ),
        Stack(
          children: [
            // TODO: API — notifications inbox (no destination in the design yet)
            IconCircleButton(TIcon.bell, label: 'Notifications', onTap: () {}),
            Positioned(
              top: 10,
              right: 11,
              child: IgnorePointer(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Palette.yellow,
                    shape: BoxShape.circle,
                    // SwiftUI `.stroke` straddles the edge: 1 pt outside, 1 pt inside.
                    border: Border.all(color: Palette.panel, width: 2, strokeAlign: BorderSide.strokeAlignCenter),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: Typo.sectionTitle())),
        trailing,
      ],
    );
  }
}

// MARK: Carousel

class _BrandCarousel extends StatelessWidget {
  const _BrandCarousel({required this.brands});

  final List<Brand> brands;

  static const _card = 252.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    // Bleeds to the screen edges (`.padding(.horizontal, -gutter)`); the scroll view clips like SwiftUI's.
    return SizedBox(
      height: 4 + 340 + 8,
      child: LayoutBuilder(
        builder: (context, box) => OverflowBox(
          minWidth: box.maxWidth + Spacing.gutter * 2,
          maxWidth: box.maxWidth + Spacing.gutter * 2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Spacing.gutter, 4, Spacing.gutter, 8),
            physics: const SnapPhysics(_card + _gap),
            itemCount: brands.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) => BrandArchCard(
              brand: brands[i],
              onTap: () => openBrand(context, i, from: Discover.home),
            ),
          ),
        ),
      ),
    );
  }
}

/// 252 × 340 arch card with Ken Burns photo, location pill, name, "STARTS AT" price and arrow chip.
class BrandArchCard extends StatelessWidget {
  const BrandArchCard({super.key, required this.brand, required this.onTap});

  final Brand brand;
  final VoidCallback onTap;

  static const _shape = ArchBorder(bottomRadius: 28);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${brand.name}, ${brand.locationLabel}, starts at ${peso(brand.from)}',
      child: Container(
        width: 252,
        height: 340,
        decoration: ShapeDecoration(
          color: Palette.panel,
          shape: _shape,
          shadows: [BoxShadow(color: const Color(0xFF000000).o(0.6), blurRadius: 24, offset: const Offset(0, 30))],
        ),
        foregroundDecoration: ShapeDecoration(
          shape: _shape.copyWith(side: BorderSide(color: Palette.white(0.14))),
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: _shape),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Photo(brand.image, kenBurns: true),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Palette.night.o(0), Palette.night.o(0.55), Palette.night.o(0.96)],
                    stops: const [0.3, 0.55, 1],
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 74),
                  _LocationPill(label: brand.locationLabel),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          style: Typo.outfit(24, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.48),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STARTS AT', style: Typo.manrope(11, Typo.bold, Palette.muted)),
                                  Text(peso(brand.from), style: Typo.outfit(20, Typo.bold, Palette.yellow)),
                                ],
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
                              child: const TIconView(TIcon.arrowUpRight, color: Palette.ink),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(shape: StadiumBorder(side: hairline(Palette.white(0.14)))),
          child: StatusPill(label, icon: TIcon.pin, background: Palette.night.o(0.6), foreground: Palette.text),
        ),
      ),
    );
  }
}

// MARK: Journey card

/// The yellow "My home journey" card: family → house track across five stages.
class JourneyCard extends StatefulWidget {
  const JourneyCard({super.key, required this.todo, required this.unit, required this.onTap});

  final int todo;
  final Unit? unit;
  final VoidCallback onTap;

  @override
  State<JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<JourneyCard> with SingleTickerProviderStateMixin {
  // .upbar: width 0 → 38%, 1.6 s cubic-bezier(.4,0,.2,1), .6 s delay
  late final _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final _t = CurvedAnimation(parent: _grow, curve: Motion.upbar);
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_grow.status != AnimationStatus.dismissed || _delay != null) return;
    if (SkipEntrance.of(context)) {
      _grow.value = 1;
      return;
    }
    _delay = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _grow.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final todo = widget.todo;
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(Radii.hero),
      child: ColoredBox(
        color: Palette.yellow,
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              width: 170,
              height: 200,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: Palette.white(0.22), shape: const ArchBorder(bottomRadius: 0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Palette.ink),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'MY HOME JOURNEY',
                            style: Typo.manrope(12, Typo.extrabold, Palette.ink).copyWith(letterSpacing: 1.2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                          decoration: BoxDecoration(color: Palette.ink.o(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            unit?.code ?? '4PHCL-01-008-085',
                            style: Typo.mono(11, Typo.semibold, Palette.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Documents in review',
                      style: Typo.outfit(27, Typo.semibold, Palette.ink).copyWith(letterSpacing: -0.675),
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: 0.78,
                      child: Text(
                        '${unit?.brandName ?? 'Pasinaya Homes'} · ${unit?.location ?? 'Ternate, Cavite'}',
                        style: Typo.manrope(13, Typo.semibold, Palette.ink),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const _EndCap(TIcon.family),
                        const SizedBox(width: 10),
                        Expanded(child: _track()),
                        const SizedBox(width: 10),
                        const _EndCap(TIcon.home),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        // Scales down on narrow phones (Galaxy Z Fold cover, iPhone SE) instead of overflowing.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              for (final (i, s) in const ['Booked', 'Docs', 'Pre-qual', 'Loan', 'Move-in'].indexed) ...[
                                if (i > 0) const SizedBox(width: 18),
                                Text(
                                  s.toUpperCase(),
                                  style: Typo.manrope(10, Typo.extrabold, Palette.ink).copyWith(letterSpacing: 0.4),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Pressable(
                      onTap: widget.onTap,
                      semanticLabel: 'Next: upload $todo document${todo == 1 ? '' : 's'}',
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.only(left: 20, right: 6),
                        decoration: const ShapeDecoration(color: Palette.ink, shape: StadiumBorder()),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Next: upload $todo document${todo == 1 ? '' : 's'}',
                                style: Typo.manrope(14, Typo.extrabold, Palette.text),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
                              child: const TIconView(TIcon.arrowRight, size: 18, color: Palette.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _track() {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(color: Palette.ink.o(0.16), shape: const StadiumBorder()),
              child: const SizedBox.expand(),
            ),
            AnimatedBuilder(
              animation: _t,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: box.maxWidth * 0.38 * _t.value,
                  height: 12,
                  child: const CustomPaint(painter: StripesPainter()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: i < 2 ? Palette.yellow : Palette.ink, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndCap extends StatelessWidget {
  const _EndCap(this.icon);

  final TIcon icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
    child: TIconView(icon, size: 22, color: Palette.yellow),
  );
}

// MARK: Transactions

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.tx});

  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final tone = switch (tx.tone) {
      TxTone.acc => PillTone.accepted,
      TxTone.sub => PillTone.submitted,
      TxTone.mut => PillTone.muted,
    };
    final tile = switch (tx.icon) {
      TxKind.wallet => IconTile(icon: TIcon.wallet, tint: Palette.acceptedText, background: Palette.green.o(0.2)),
      TxKind.home => IconTile(icon: TIcon.home, tint: Palette.submittedText, background: Palette.blue.o(0.24)),
      TxKind.calendar => IconTile(icon: TIcon.calendar, tint: Palette.muted, background: Palette.white(0.07)),
    };
    return RowLayout(
      children: [
        tile,
        RowText(
          title: tx.title,
          subtitle: tx.subtitle,
          titleSize: 14,
          subtitleSize: 12,
          subtitleColor: Palette.subtle,
          subtitleMono: tx.mono,
        ),
        if (tx.amount != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx.amount!, style: Typo.outfit(15, Typo.bold, Palette.text)),
              const SizedBox(height: 4),
              StatusPill(tx.status, tone: tone, height: 22),
            ],
          )
        else
          StatusPill(tx.status, tone: tone),
      ],
    );
  }
}
