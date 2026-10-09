import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/adaptive.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';
import 'media_gallery.dart';
import 'unit_widgets.dart';

/// Unit page: arch photo, price first, spec strip, an income gauge, the gallery, a "what you pay" receipt and a docked
/// bar. Opened from a brand location, or straight from a seller's booking QR (`from == Discover.scan`), where the dock
/// becomes "Proceed booking" and the page shows who is assisting.
class ProductScreen extends StatelessWidget {
  const ProductScreen({
    super.key,
    required this.brandIndex,
    required this.locationIndex,
    required this.productIndex,
    required this.from,
  });

  final int brandIndex, locationIndex, productIndex;
  final String from;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final brands = state.brands;
    if (brandIndex >= brands.length) return const SizedBox.shrink();
    final b = brands[brandIndex];
    final l = b.locations?.elementAtOrNull(locationIndex);
    final p = l?.products?.elementAtOrNull(productIndex);
    if (l == null || p == null) return const SizedBox.shrink();
    final fin = p.financing;
    final code = p.sourceCode;
    final income = state.profile?.grossMonthlyIncome ?? 0;
    final scanned = from == Discover.scan;
    final unit = state.profile?.unit;
    final heroImage =
        p.media.where((m) => m.type == 'photo').firstOrNull?.url ??
        l.media.where((m) => m.type == 'photo').firstOrNull?.url ??
        b.image;

    final split = AdaptivePanes.splits(context);
    final paneW = split ? Layout.width(context) * 0.46 : math.min(Layout.width(context), Layout.content + 40);
    final heroH = math.min(400.0, (paneW - 40) * 1.05);
    final lead = <Widget>[
      Reveal(
        dy: 8,
        child: DiscoverTopBar(
          backLabel: scanned ? 'Back to home' : 'Back to ${l.name}',
          onBack: () => context.go(scanned ? Screen.home : Screen.project(brandIndex, locationIndex, from: from)),
        ),
      ),
      const SizedBox(height: 16),
      ArchHero(
        image: heroImage,
        height: heroH,
        children: [
          if (scanned)
            const Positioned(
              right: 18,
              bottom: 22,
              child: StatusPill('From seller QR', tone: PillTone.accepted, icon: TIcon.scan),
            ),
          if (scanned && unit != null)
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(10)),
                child: Text(unit.code, style: Typo.mono(12, Typo.semibold, Palette.ink)),
              ),
            ),
        ],
      ),
      Reveal(
        delay: 0.14,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.name} · ${b.name}'.toUpperCase(), style: Typo.eyebrow.copyWith(fontSize: 11.5)),
              const SizedBox(height: 10),
              Text(p.name, style: Typo.h1(40).copyWith(height: 1.04)),
              if (code != null) ...[
                const SizedBox(height: 6),
                Text('Source product: $code', style: Typo.manrope(13, Typo.regular, Palette.soft)),
              ],
              if (scanned && unit != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Assisted by ${unit.seller.name} · Homeful seller',
                  style: Typo.manrope(13, Typo.semibold, Palette.muted),
                ),
              ],
            ],
          ),
        ),
      ),
      Reveal(
        delay: 0.2,
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL CONTRACT PRICE', style: Typo.overline(em: 0.08).copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    CountUp(
                      value: p.tcp,
                      builder: (s) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          s,
                          style: Typo.outfit(50, Typo.bold, Palette.text).copyWith(letterSpacing: -1.8, height: 1.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 10),
                child: TIconView(TIcon.home, size: 44, color: Color(0x66FFFFFF)),
              ),
            ],
          ),
        ),
      ),
      if (fin != null)
        Reveal(
          delay: 0.24,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: ShapeDecoration(color: Palette.yellow.o(0.14), shape: const StadiumBorder()),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${peso(fin.monthly)} / month',
                        style: Typo.manrope(13, Typo.extrabold, Palette.yellow),
                      ),
                      TextSpan(
                        text: '  ·  ${fin.term} · ${fin.program}',
                        style: Typo.manrope(13, Typo.semibold, const Color(0xFFE6C46A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      Reveal(
        delay: 0.28,
        child: Padding(
          padding: const EdgeInsets.only(top: 26),
          child: p.floor != null
              ? FactsStrip([
                  (p.floor!, 'Floor area'),
                  (p.lot ?? 'N/A', 'Lot area'),
                  ('${p.floors}', p.floors == 1 ? 'Floor' : 'Floors'),
                ], size: 22)
              : Text('Floor and lot area pending.', style: Typo.manrope(13, Typo.regular, Palette.subtle)),
        ),
      ),
    ];
    final rest = <Widget>[
      if (fin != null) ...[
        const Reveal(delay: 0.32, child: _Title('Can you afford it?')),
        Reveal(
          delay: 0.36,
          child: AffordabilityCheck(
            income: income,
            required: fin.gmi,
            onAddSpouse: () => context.go(const Screen(ScreenKind.spouse)),
          ),
        ),
      ],
      const Reveal(
        delay: 0.4,
        child: Padding(
          padding: EdgeInsets.only(top: 34),
          child: SectionRow('Gallery', meta: 'Sample media'),
        ),
      ),
      Reveal(
        delay: 0.44,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: MediaCarousel(items: productGallery(b, p), heroPrefix: 'product-${b.id}-$locationIndex-$productIndex'),
        ),
      ),
      const Reveal(delay: 0.48, child: _Title('What you pay')),
      Reveal(delay: 0.5, child: _Receipt(product: p)),
      Reveal(delay: 0.54, child: _Title(scanned ? 'Your booking' : 'Your next step')),
      Reveal(delay: 0.56, child: _Steps(scanned: scanned)),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        if (split)
          AdaptivePanes(
            start: ScreenScroll(bottom: 40, children: lead),
            end: ScreenScroll(top: Spacing.belowStatusBar + 44, bottom: 130, children: rest),
          )
        else
          ScreenScroll(bottom: 130, children: [...lead, ...rest]),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Reveal(
            delay: 0.3,
            dy: 30,
            child: _PriceDock(
              tcp: peso(p.tcp),
              monthly: fin == null ? null : peso(fin.monthly),
              label: scanned ? 'Proceed booking' : 'Scan seller QR',
              icon: scanned ? TIcon.arrowRight : TIcon.scan,
              onTap: () {
                if (scanned) {
                  HapticFeedback.mediumImpact();
                  state.showSheet(SheetKind.terms);
                } else {
                  context.go(Screen.scan);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 34, bottom: 14),
    child: Text(text, style: Typo.sectionTitle(22)),
  );
}

/// "What you pay": fees and the monthly amortization as a receipt with dotted leaders.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final fin = p.financing;
    final fees = p.fees;
    if (fin == null) {
      return PendingNote(
        lead: 'Financing pending.',
        text:
            'TCP is ${peso(p.tcp)}. Monthly amortization, required income, loan program and fees come from the source spreadsheet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fees != null)
          for (final (k, v) in fees.rows) ReceiptRow(k, v, valueColor: v == '₱0' ? Palette.acceptedText : Palette.text),
        if (fees?.highlight case (final k, final v)) ReceiptRow(k, v, valueColor: Palette.yellow),
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Palette.white(0.12))),
          ),
          child: ReceiptRow('Monthly amortization', peso(fin.monthly), valueColor: Palette.yellow, strong: true),
        ),
        const SizedBox(height: 4),
        Text(
          [?fees?.note, fin.note].join(' '),
          style: Typo.manrope(12, Typo.regular, Palette.subtle).copyWith(height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'All prices are PHP; all areas are sqm. Figures follow the source spreadsheet.',
          style: Typo.manrope(12, Typo.regular, Palette.subtle).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// Three-step path from here to a booked unit. When the buyer already scanned, the first step is ticked off.
class _Steps extends StatelessWidget {
  const _Steps({required this.scanned});

  final bool scanned;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Scan your seller’s QR', 'It opens this unit for you. Nothing to retype.'),
      ('Attach ID & selfie', 'Takes about two minutes.'),
      ('Pay the consultation fee', 'Consultation is not a reservation fee. Then complete your form within 7 days.'),
    ];
    return Column(
      children: [
        for (final (i, s) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 && scanned ? Palette.green : Palette.yellow.o(0.16),
                        ),
                        child: i == 0 && scanned
                            ? const TIconView(TIcon.check, size: 15, color: Color(0xFFFFFFFF))
                            : Text('${i + 1}', style: Typo.manrope(13, Typo.extrabold, Palette.yellow)),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Palette.white(0.14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$1, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                        const SizedBox(height: 3),
                        Text(s.$2, style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Income gauge: the buyer's gross monthly income against the unit's requirement, with a marker at the requirement.
/// Below it, suggests adding a spouse's income.
class AffordabilityCheck extends StatelessWidget {
  const AffordabilityCheck({super.key, required this.income, required this.required, required this.onAddSpouse});

  final num income, required;
  final VoidCallback onAddSpouse;

  @override
  Widget build(BuildContext context) {
    final ok = income >= required;
    final tint = ok ? Palette.green : Palette.orange;
    final top = (income > required ? income : required) * 1.3;
    final fill = top == 0 ? 0.0 : (income / top).clamp(0.0, 1.0).toDouble();
    final mark = top == 0 ? 0.0 : (required / top).clamp(0.0, 1.0).toDouble();
    return Glass(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: TIconView(ok ? TIcon.check : TIcon.info, size: 16, color: const Color(0xFFFFFFFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ok ? 'Your income meets the requirement' : 'Below the required income',
                  style: Typo.manrope(15, Typo.extrabold, Palette.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _Gauge(fill: fill, mark: mark, color: ok ? Palette.acceptedText : Palette.todoText),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('₱0', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
              Expanded(
                child: Text(
                  '${peso(required)} needed',
                  textAlign: TextAlign.center,
                  style: Typo.manrope(12, Typo.extrabold, Palette.yellow),
                ),
              ),
              Text(
                'You ${peso(income)}',
                style: Typo.manrope(12, Typo.extrabold, ok ? Palette.acceptedText : Palette.todoText),
              ),
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: 10),
            Text(
              'Your ${peso(income)}/mo vs required ${peso(required)}. Adding your spouse’s income can close the gap.',
              style: Typo.manrope(13, Typo.regular, Palette.soft).copyWith(height: 1.5),
            ),
            const SizedBox(height: 4),
            Pressable(
              onTap: onAddSpouse,
              semanticLabel: 'Add spouse income',
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add spouse income', style: Typo.manrope(13, Typo.extrabold, Palette.yellow)),
                    const SizedBox(width: 2),
                    const TIconView(TIcon.chevronRight, size: 16, color: Palette.yellow),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.fill, required this.mark, required this.color});

  final double fill, mark;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 10,
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(color: Palette.white(0.1), borderRadius: BorderRadius.circular(5)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fill),
            duration: introDuration(context, 1100),
            curve: Motion.upbar,
            builder: (_, f, _) => Container(
              width: box.maxWidth * f,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            ),
          ),
          Positioned(
            left: box.maxWidth * mark - 1,
            top: -20,
            child: Container(width: 2, height: 30, color: Palette.yellow),
          ),
        ],
      ),
    ),
  );
}

/// Docked bar: TCP · monthly on the left, the primary action on the right; fades the content beneath it.
class _PriceDock extends StatelessWidget {
  const _PriceDock({
    required this.tcp,
    required this.monthly,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String tcp, label;
  final String? monthly;
  final TIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.night.o(0), Palette.night],
          stops: const [0, 0.34],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 8 + bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: ShapeDecoration(
                color: const Color(0xF00D1C38),
                shape: StadiumBorder(side: hairline(Palette.white(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthly == null ? 'TCP' : 'TCP · monthly',
                          style: Typo.manrope(12, Typo.regular, Palette.subtle),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: tcp),
                                if (monthly != null)
                                  TextSpan(text: ' · $monthly', style: Typo.outfit(14, Typo.semibold, Palette.soft)),
                              ],
                            ),
                            maxLines: 1,
                            style: Typo.outfit(17, Typo.bold, Palette.yellow),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    onTap: onTap,
                    semanticLabel: label,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.only(left: 18, right: 5),
                      decoration: BoxDecoration(
                        color: Palette.yellow,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Palette.yellow.o(0.4), blurRadius: 12, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: Typo.manrope(15, Typo.extrabold, Palette.ink)),
                          const SizedBox(width: 10),
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                            child: TIconView(icon, size: 18, color: Palette.yellow),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The unit a seller's booking QR points at: resolves the buyer's booked unit to its catalog page and shows it in
/// booking mode. TODO: API — resolve by the QR payload's unit code instead of the profile's unit.
class ScannedUnitScreen extends StatelessWidget {
  const ScannedUnitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final brands = state.brands;
    final u = state.profile?.unit;
    var bi = brands.indexWhere((b) => b.id == u?.brandId);
    if (bi < 0) bi = brands.indexWhere((b) => (b.locations?.any((l) => l.products?.isNotEmpty ?? false)) ?? false);
    if (bi < 0) return const SizedBox.shrink();
    final locs = brands[bi].locations ?? const <Location>[];
    final place = (u?.location ?? '').split(',').first.trim().toLowerCase();
    var li = locs.indexWhere(
      (l) => place.isNotEmpty && (l.name.toLowerCase().contains(place) || (l.area ?? '').toLowerCase().contains(place)),
    );
    if (li < 0) li = locs.indexWhere((l) => l.products?.isNotEmpty ?? false);
    if (li < 0) return const SizedBox.shrink();
    final prods = locs[li].products ?? const <Product>[];
    var pi = prods.indexWhere((p) => p.name.toLowerCase() == (u?.product ?? '').toLowerCase());
    if (pi < 0) pi = 0;
    return ProductScreen(brandIndex: bi, locationIndex: li, productIndex: pi, from: Discover.scan);
  }
}
