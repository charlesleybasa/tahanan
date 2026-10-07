import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';
import 'media_gallery.dart';

/// A brand's location page: gallery, a compare strip when there are several products, and product cards.
/// [locationIndex] is -1 for a single-project brand whose location the spreadsheet hasn't named yet.
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

    return ScreenScroll(
      children: [
        DiscoverTopBar(
          backLabel: fromHome ? 'Back to home' : 'Back to catalog',
          onBack: () => context.go(fromHome ? Screen.home : Screen.catalog),
        ).rise(),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Text(b.name.toUpperCase(), style: Typo.eyebrow),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(title, style: Typo.h1(38).copyWith(height: 1.04)),
        ).rise(1),
        if (l?.area != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const TIconView(TIcon.pin, size: 15, color: Palette.soft),
                const SizedBox(width: 6),
                Text(l!.area!, style: Typo.manrope(14, Typo.semibold, Palette.soft)),
              ],
            ),
          ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill('From ${peso(l?.from ?? b.from)}', tone: PillTone.reviewed),
              StatusPill(b.type, background: Palette.white(0.08), foreground: Palette.soft),
              if ((locations?.length ?? 0) > 1)
                Pressable(
                  onTap: () => openBrand(context, brandIndex, from: from),
                  semanticLabel: 'Change location',
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: ShapeDecoration(shape: StadiumBorder(side: hairline(Palette.white(0.14)))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Change location', style: Typo.manrope(13, Typo.bold, Palette.yellow)),
                        const SizedBox(width: 4),
                        const TIconView(TIcon.chevronDown, size: 15, color: Palette.yellow),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ).rise(2),
        const Padding(
          padding: EdgeInsets.only(top: 26),
          child: SectionRow('Project gallery', meta: 'Sample media'),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: MediaCarousel(items: projectGallery(b, l), heroPrefix: 'project-${b.id}-$locationIndex'),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: SectionRow('Available products', meta: count == null || count == 0 ? null : plural(count, 'product')),
        ).rise(4),
        if (products != null) ...[
          if (products.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Glass(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 14),
                child: Column(
                  children: [
                    for (final (i, p) in products.indexed)
                      KeyValueRow(
                        [p.name, ?p.floor].join(' · '),
                        peso(p.tcp),
                        first: i == 0,
                        valueColor: Palette.yellow,
                        onTap: () => context.go(Screen.product(brandIndex, locationIndex, i, from: from)),
                      ),
                  ],
                ),
              ),
            ).rise(4),
          for (final (i, p) in products.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ProductCard(
                product: p,
                subtitle: p.sourceCode ?? '$title · ${b.name}',
                action: products.length > 1 ? 'View ${p.name}' : 'View product',
                onTap: () => context.go(Screen.product(brandIndex, locationIndex, i, from: from)),
              ),
            ).rise(5 + i),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: l != null
                ? PendingNote(
                    lead: '${plural(l.count, 'product')} pending.',
                    text: 'Their names, areas and prices come from the source spreadsheet.',
                  )
                : PendingNote(
                    lead: 'Project details pending.',
                    text:
                        '${b.name} has ${plural(b.projects, 'project')} from ${peso(b.from)} (${b.type}). The '
                        'location name and products come from the source spreadsheet.',
                  ),
          ).rise(5),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.subtitle, required this.action, required this.onTap});

  final Product product;
  final String subtitle, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Glass(
      fill: Palette.white(0.05),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: Typo.outfit(22, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.44)),
          const SizedBox(height: 2),
          Text(subtitle, style: Typo.manrope(13, Typo.regular, Palette.soft)),
          if (p.floor != null) ...[const SizedBox(height: 14), AreaStats(floor: p.floor!, lot: p.lot ?? 'N/A')],
          const SizedBox(height: 14),
          captionText('Total contract price (TCP)'),
          const SizedBox(height: 2),
          priceText(peso(p.tcp)),
          if (p.financing != null) ...[
            const SizedBox(height: 2),
            Text(
              '${peso(p.financing!.monthly)}/mo · ${p.financing!.program}',
              style: Typo.manrope(13, Typo.semibold, Palette.muted),
            ),
          ],
          const SizedBox(height: 14),
          PrimaryButton(action, height: 48, chipSize: 38, fontSize: 15, onTap: onTap),
        ],
      ),
    );
  }
}
