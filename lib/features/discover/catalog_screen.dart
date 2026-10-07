import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/itext.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';

/// "All brands": every brand with its type, from-price and project count, filterable by home type.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  HomeGroup? _group;

  static String _groupName(HomeGroup g) => switch (g) {
    HomeGroup.rowhouse => 'Rowhouse',
    HomeGroup.duplex => 'Duplex',
    HomeGroup.condo => 'Condo',
    HomeGroup.cluster => 'Cluster',
  };

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AppState>().brands;
    final shown = [
      for (final (i, b) in brands.indexed)
        if (_group == null || b.group == _group) (i, b),
    ];
    return ScreenScroll(
      children: [
        DiscoverTopBar(onBack: () => context.go(Screen.home)).rise(),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Text('All brands', style: Typo.h1(40)),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: IText('Choose a brand, select a location, then explore its products.', style: Typo.mutedBody()),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _FilterRow(
            children: [
              FilterChipButton(
                'All · ${brands.length}',
                height: 36,
                selected: _group == null,
                onTap: () => _select(null),
              ),
              for (final g in HomeGroup.values)
                FilterChipButton(_groupName(g), height: 36, selected: _group == g, onTap: () => _select(g)),
            ],
          ),
        ).rise(2),
        // Re-keyed per filter so the matching cards cascade in.
        KeyedSubtree(
          key: ValueKey(_group),
          child: Column(
            children: [
              for (final (n, (i, b)) in shown.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CatalogBrandCard(
                    brand: b,
                    onTap: () => openBrand(context, i, from: Discover.catalog),
                  ).rise(3 + n),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            'From-prices are the lowest actual TCP in the spreadsheet. All prices are PHP.',
            style: Typo.manrope(13, Typo.regular, Palette.subtle).copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }

  void _select(HomeGroup? g) {
    if (g == _group) return;
    HapticFeedback.selectionClick();
    setState(() => _group = g);
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: LayoutBuilder(
      builder: (context, box) => OverflowBox(
        minWidth: box.maxWidth + Spacing.gutter * 2,
        maxWidth: box.maxWidth + Spacing.gutter * 2,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    ),
  );
}

/// Catalog card: 170 pt artwork labelled "Artist’s rendering", name, type, from-price, project count, and an
/// action that names the next step.
class CatalogBrandCard extends StatelessWidget {
  const CatalogBrandCard({super.key, required this.brand, required this.onTap});

  final Brand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = brand;
    final action = b.locationCount > 1 ? 'Choose location' : 'View project';
    final shape = squircle(Radii.card, side: hairline(Palette.white(0.09)));
    return Pressable(
      onTap: onTap,
      semanticLabel: '${b.name}, ${b.type}, from ${peso(b.from)}, ${plural(b.projects, 'project')}. $action.',
      child: Container(
        decoration: ShapeDecoration(
          color: Palette.panel,
          shape: shape,
          shadows: [BoxShadow(color: const Color(0xFF000000).o(0.45), blurRadius: 24, offset: const Offset(0, 24))],
        ),
        foregroundDecoration: ShapeDecoration(shape: shape),
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(b.image),
                    const Positioned(left: 10, bottom: 10, child: MediaLabel('Artist’s rendering')),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: StatusPill(
                        b.locationLabel,
                        icon: TIcon.pin,
                        background: Palette.night.o(0.6),
                        foreground: Palette.text,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.name, style: Typo.outfit(22, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.44)),
                    const SizedBox(height: 4),
                    Text(b.type, style: Typo.manrope(13, Typo.regular, Palette.soft)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: priceText('From ${peso(b.from)}', size: 19)),
                        Text(plural(b.projects, 'project'), style: Typo.manrope(13, Typo.regular, Palette.soft)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Palette.white(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(child: Text(action, style: Typo.manrope(14, Typo.bold, Palette.yellow))),
                          const TIconView(TIcon.arrowRight, color: Palette.yellow),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
