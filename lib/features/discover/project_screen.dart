import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/adaptive.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';
import 'media_gallery.dart';
import 'project_info.dart';
import 'unit_widgets.dart';

/// "₱750K" / "₱1.25M" for the sun badge.
String shortPeso(num n) {
  if (n >= 1000000) {
    final m = n / 1000000;
    return '₱${m == m.roundToDouble() ? m.round() : m.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '')}M';
  }
  return '₱${(n / 1000).round()}K';
}

/// First number in "32 sqm" → 32.
double? _sqm(String? s) => s == null ? null : double.tryParse(RegExp(r'[\d.]+').firstMatch(s)?.group(0) ?? '');

/// A brand's location page: one arch photo with the starting price in a yellow sun, quiet facts, the gallery and an
/// open "Available units" ladder. [locationIndex] is -1 for a single-project brand whose location isn't named yet.
class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.brandIndex, required this.locationIndex, required this.from});

  final int brandIndex, locationIndex;
  final String from;

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AppState>().brands;
    if (brandIndex >= brands.length) return const SizedBox.shrink();
    final b = brands[brandIndex];
    final locations = b.locations;
    final l = locations != null && locationIndex >= 0 && locationIndex < locations.length
        ? locations[locationIndex]
        : null;
    final title = l?.name ?? b.name;
    final products = l?.products;
    final count = l?.count;
    final fromHome = from == Discover.home;
    final heroImage = l?.media.where((m) => m.type == 'photo').firstOrNull?.url ?? b.image;
    final startsAt = l?.from ?? b.from;

    final floors = [for (final p in products ?? const <Product>[]) ?_sqm(p.floor)];
    final terms = [for (final p in products ?? const <Product>[]) ?p.financing?.term];
    final facts = <(String, String)>[
      ('${count ?? b.projects}', (count ?? b.projects) == 1 ? 'Unit' : 'Units'),
      if (floors.isNotEmpty)
        ('${floors.reduce((a, c) => a < c ? a : c).round()} sqm', 'Floor from')
      else
        (shortPeso(startsAt), 'From'),
      if (terms.isNotEmpty) (terms.first, 'Max term') else (b.type, 'Type'),
    ];
    final maxTcp = (products ?? const <Product>[]).fold<num>(0, (m, p) => p.tcp > m ? p.tcp : m);
    final minTcp = (products ?? const <Product>[]).fold<num>(double.infinity, (m, p) => p.tcp < m ? p.tcp : m);

    final split = AdaptivePanes.splits(context);
    final paneW = split
        ? Layout.width(context) * 0.46
        : (Layout.width(context) < Layout.content + 40 ? Layout.width(context) : Layout.content + 40);
    final heroH = math.min(430.0, (paneW - 40) * 1.12);
    final info = l?.info;
    final lead = <Widget>[
      Reveal(
        dy: 8,
        child: DiscoverTopBar(
          backLabel: fromHome ? 'Back to home' : 'Back to catalog',
          onBack: () => context.go(fromHome ? Screen.home : Screen.catalog),
        ),
      ),
      const SizedBox(height: 16),
      ArchHero(
        image: heroImage,
        height: heroH,
        badge: SunBadge(label: 'FROM', value: shortPeso(startsAt)),
        children: [
          if (l?.area != null)
            Positioned(
              left: 22,
              bottom: 20,
              child: Row(
                children: [
                  const TIconView(TIcon.pin, size: 15, color: Palette.yellow),
                  const SizedBox(width: 6),
                  Text(l!.area!, style: Typo.manrope(13, Typo.bold, Palette.softer)),
                ],
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
              Text(b.name.toUpperCase(), style: Typo.eyebrow),
              const SizedBox(height: 8),
              Text(title, style: Typo.h1(44).copyWith(height: 1.02)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    b.type,
                    background: Palette.white(0.08),
                    foreground: Palette.soft,
                    height: 32,
                    fontSize: 12,
                  ),
                  if ((locations?.length ?? 0) > 1)
                    Pressable(
                      onTap: () => openBrand(context, brandIndex, from: from),
                      semanticLabel: 'Change location',
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: ShapeDecoration(shape: StadiumBorder(side: hairline(Palette.white(0.16)))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Change location', style: Typo.manrope(13, Typo.extrabold, Palette.yellow)),
                            const SizedBox(width: 4),
                            const TIconView(TIcon.chevronDown, size: 15, color: Palette.yellow),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      Reveal(
        delay: 0.22,
        child: Padding(padding: const EdgeInsets.only(top: 26), child: FactsStrip(facts)),
      ),
      if (info?.sold != null && info?.remaining != null)
        Reveal(
          delay: 0.26,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: AvailabilityBar(sold: info!.sold!, remaining: info.remaining!),
          ),
        ),
    ];
    final rest = <Widget>[
      if (info != null && (info.description != null || info.highlights.isNotEmpty)) ...[
        const Reveal(delay: 0.3, child: InfoHeading('About the project', meta: 'Project details')),
        Reveal(
          delay: 0.32,
          child: AboutProject(description: info.description, highlights: info.highlights),
        ),
      ],
      const Reveal(
        delay: 0.3,
        child: Padding(
          padding: EdgeInsets.only(top: 34),
          child: SectionRow('Gallery', meta: 'Sample media'),
        ),
      ),
      Reveal(
        delay: 0.34,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: MediaCarousel(items: projectGallery(b, l), heroPrefix: 'project-${b.id}-$locationIndex'),
        ),
      ),
      Reveal(
        delay: 0.4,
        child: Padding(
          padding: const EdgeInsets.only(top: 36, bottom: 6),
          child: SectionRow('Available units', meta: count == null || count == 0 ? null : plural(count, 'unit')),
        ),
      ),
      if (products != null)
        for (final (i, p) in products.indexed)
          Reveal(
            delay: 0.46 + 0.06 * i.clamp(0, 5),
            child: _UnitRow(
              index: i + 1,
              product: p,
              fraction: products.length < 2 || maxTcp == 0 ? null : (p.tcp / maxTcp).toDouble(),
              lowest: products.length > 1 && p.tcp == minTcp,
              first: i == 0,
              onTap: () => context.go(Screen.product(brandIndex, locationIndex, i, from: from)),
            ),
          )
      else
        Reveal(
          delay: 0.46,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: l != null
                ? PendingNote(
                    lead: '${plural(l.count, 'unit')} pending.',
                    text: 'Their names, areas and prices come from the source spreadsheet.',
                  )
                : PendingNote(
                    lead: 'Project details pending.',
                    text:
                        '${b.name} has ${plural(b.projects, 'project')} from ${peso(b.from)} (${b.type}). The '
                        'location name and units come from the source spreadsheet.',
                  ),
          ),
        ),
      if (info != null && (info.address != null || info.mapUrl != null)) ...[
        Reveal(delay: 0.5, child: InfoHeading('How to get there', meta: l?.area)),
        Reveal(
          delay: 0.52,
          child: Directions(title: title, info: info),
        ),
      ],
      if (info != null && info.stories.isNotEmpty) ...[
        Reveal(
          delay: 0.56,
          child: InfoHeading('Homeowner stories', meta: plural(info.stories.length, 'story', 'stories')),
        ),
        Reveal(delay: 0.58, child: HomeownerStories(stories: info.stories)),
      ],
      const SizedBox(height: 10),
    ];

    const top = Spacing.belowStatusBar;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (split)
          AdaptivePanes(
            start: ScreenScroll(bottom: 40, children: lead),
            end: ScreenScroll(top: top + 44, bottom: 130, children: rest),
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
            child: BottomCTABar(
              child: PrimaryButton('Book your home', icon: TIcon.scan, onTap: () => context.go(Screen.scan)),
            ),
          ),
        ),
      ],
    );
  }
}

/// One line of the "Available units" ladder: outlined numeral, name and areas, price and monthly, and a bar that
/// shows the price against the dearest unit.
class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.index,
    required this.product,
    required this.fraction,
    required this.lowest,
    required this.first,
    required this.onTap,
  });

  final int index;
  final Product product;
  final double? fraction;
  final bool lowest, first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final meta = [
      if (p.floors > 1) '${p.floors} floors',
      if (p.floor != null) '${p.floor} floor',
      if (p.lot != null) '${p.lot} lot',
    ].join(' · ');
    return Pressable(
      onTap: onTap,
      semanticLabel: 'View ${p.name}, ${peso(p.tcp)}',
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.only(top: 18, bottom: 18),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: Palette.white(0.09))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lowest)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                  child: Text(
                    'LOWEST PRICE',
                    style: Typo.manrope(9.5, Typo.extrabold, Palette.ink).copyWith(letterSpacing: 1),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 62, child: OutlineNumber(index)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Typo.outfit(20, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.4)),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(meta, style: Typo.manrope(12, Typo.semibold, Palette.muted)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(peso(p.tcp), style: Typo.outfit(21, Typo.bold, Palette.yellow).copyWith(letterSpacing: -0.4)),
                    if (p.financing != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${peso(p.financing!.monthly.roundToDouble())}/mo',
                        style: Typo.manrope(11, Typo.semibold, Palette.subtle),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (fraction != null)
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 62),
                child: _PriceBar(fraction: fraction!),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: LayoutBuilder(
      builder: (_, box) => Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: Palette.white(0.09), borderRadius: BorderRadius.circular(2)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: introDuration(context, 900),
            curve: Motion.upbar,
            builder: (_, f, _) => Container(
              width: box.maxWidth * f,
              decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    ),
  );
}
