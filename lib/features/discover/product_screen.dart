import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';
import 'media_gallery.dart';

/// Product page: summary chips, an affordability check against the buyer's income, the gallery, details,
/// investment & financing, fees, and a docked price bar with "Scan seller QR".
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

    return Stack(
      fit: StackFit.expand,
      children: [
        ScreenScroll(
          bottom: 120,
          children: [
            DiscoverTopBar(
              backLabel: 'Back to ${l.name}',
              onBack: () => context.go(Screen.project(brandIndex, locationIndex, from: from)),
            ).rise(),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Text(b.name.toUpperCase(), style: Typo.eyebrow),
            ).rise(1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p.name, style: Typo.h1(38).copyWith(height: 1.04)),
            ).rise(1),
            if (code != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Source product: $code', style: Typo.manrope(14, Typo.regular, Palette.soft)),
              ).rise(2),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text([l.name, ?l.area].join(' · '), style: Typo.manrope(14, Typo.regular, Palette.soft)),
            ).rise(2),
            if (fin != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill('${peso(fin.monthly)}/mo', tone: PillTone.reviewed),
                    StatusPill('${fin.program} · ${fin.term}', tone: PillTone.submitted),
                    if (p.floor != null)
                      StatusPill(p.floor!, background: Palette.white(0.08), foreground: Palette.soft),
                  ],
                ),
              ).rise(2),
            if (fin != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AffordabilityCheck(
                  income: income,
                  required: fin.gmi,
                  onAddSpouse: () => context.go(const Screen(ScreenKind.spouse)),
                ),
              ).rise(3),
            const Padding(
              padding: EdgeInsets.only(top: 26),
              child: SectionRow('Product gallery', meta: 'Sample media'),
            ).rise(3),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: MediaCarousel(
                items: productGallery(b, p),
                heroPrefix: 'product-${b.id}-$locationIndex-$productIndex',
              ),
            ).rise(4),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Text('Product details', style: Typo.sectionTitle()),
            ).rise(5),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Glass(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text([p.name, ?code].join(' · '), style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                    if (p.floor != null) ...[
                      const SizedBox(height: 12),
                      AreaStats(floor: p.floor!, lot: p.lot ?? 'N/A'),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text('Floor and lot area pending.', style: Typo.manrope(13, Typo.regular, Palette.subtle)),
                    ],
                  ],
                ),
              ),
            ).rise(5),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Text('Investment & financing', style: Typo.sectionTitle()),
            ).rise(6),
            ..._financing(p).map((w) => w.rise(6)),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Text('Your next step', style: Typo.sectionTitle()),
            ).rise(7),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: noteText('${b.name} · ${l.name} · ${p.name}${code == null ? '' : ' ($code)'}', size: 14),
            ).rise(7),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: noteText(
                'Scan your seller’s QR to continue with a consultation. Consultation is not a reservation fee.',
                size: 14,
              ),
            ).rise(7),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _PriceDock(
            tcp: peso(p.tcp),
            monthly: fin == null ? null : peso(fin.monthly),
            onScan: () => context.go(Screen.scan),
          ).rise(4),
        ),
      ],
    );
  }

  List<Widget> _financing(Product p) {
    final fin = p.financing;
    final fees = p.fees;
    if (fin == null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PendingNote(
            lead: 'Financing pending.',
            text:
                'TCP is ${peso(p.tcp)}. Monthly amortization, required income, loan program and fees come from the '
                'source spreadsheet.',
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Glass(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              captionText('Total contract price (TCP)'),
              priceText(peso(p.tcp)),
              const SizedBox(height: 12),
              captionText('Monthly amortization'),
              priceText(peso(fin.monthly)),
              const SizedBox(height: 8),
              noteText(fin.note),
              const SizedBox(height: 6),
              KeyValueRow('Required gross monthly income (GMI)', peso(fin.gmi)),
              KeyValueRow('Loan program', fin.program),
              KeyValueRow('Loan term', fin.term),
            ],
          ),
        ),
      ),
      if (fees != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Glass(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fees.title, style: Typo.outfit(19, Typo.semibold, Palette.text)),
                const SizedBox(height: 6),
                for (final (k, v) in fees.rows) KeyValueRow(k, v),
                if (fees.highlight case (final k, final v)) ...[
                  const SizedBox(height: 12),
                  captionText(k),
                  priceText(v, size: 20),
                ],
                const SizedBox(height: 10),
                noteText(fees.note),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          'All prices are PHP; all areas are sqm. Product specifications and investment figures follow the source '
          'spreadsheet.',
          style: Typo.manrope(13, Typo.regular, Palette.subtle).copyWith(height: 1.45),
        ),
      ),
    ];
  }
}

/// Compares the buyer's gross monthly income (from their profile) with the product's required GMI, with a meter
/// that fills toward the requirement. Below it, suggests adding a spouse's income.
class AffordabilityCheck extends StatelessWidget {
  const AffordabilityCheck({super.key, required this.income, required this.required, required this.onAddSpouse});

  final num income, required;
  final VoidCallback onAddSpouse;

  @override
  Widget build(BuildContext context) {
    final ok = income >= required;
    final tint = ok ? Palette.green : Palette.orange;
    final fraction = required == 0 ? 1.0 : (income / required).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
      decoration: ShapeDecoration(color: tint.o(0.16), shape: squircle(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Your income meets the requirement' : 'Below the required income',
                  style: Typo.manrope(14, Typo.extrabold, Palette.text),
                ),
                const SizedBox(height: 3),
                noteText(
                  'Your ${peso(income)}/mo vs required ${peso(required)}.'
                  '${ok ? '' : ' Adding your spouse’s income can close the gap.'}',
                ),
                const SizedBox(height: 10),
                _Meter(fraction: fraction, color: ok ? Palette.acceptedText : Palette.todoText),
                if (!ok) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${(fraction * 100).round()}% of the required income',
                    style: Typo.manrope(12, Typo.semibold, Palette.muted),
                  ),
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: onAddSpouse,
                    semanticLabel: 'Add spouse income',
                    child: SizedBox(
                      height: 32,
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
          ),
        ],
      ),
    );
  }
}

/// Animated income meter (fills on entry).
class _Meter extends StatelessWidget {
  const _Meter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 6,
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: Palette.white(0.12), borderRadius: BorderRadius.circular(3)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 1200),
            curve: Motion.upbar,
            builder: (_, f, _) => Container(
              width: box.maxWidth * f,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Docked bar: TCP · monthly on the left, "Scan seller QR" on the right; fades the content beneath it.
class _PriceDock extends StatelessWidget {
  const _PriceDock({required this.tcp, required this.monthly, required this.onScan});

  final String tcp;
  final String? monthly;
  final VoidCallback onScan;

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
                  // A hugging `.btnY.sm`: PrimaryButton fills its width, which a Row can't give it here.
                  Pressable(
                    onTap: onScan,
                    semanticLabel: 'Scan seller QR',
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
                          Text('Scan seller QR', style: Typo.manrope(15, Typo.extrabold, Palette.ink)),
                          const SizedBox(width: 10),
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                            child: const TIconView(TIcon.scan, size: 18, color: Palette.yellow),
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
