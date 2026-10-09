import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';
import 'discover_widgets.dart';

/// "Choose a location": each row opens that location's page directly (no pre-selection, no confirm step).
class LocationSheet extends StatelessWidget {
  const LocationSheet({super.key, required this.brandIndex, required this.origin, required this.onClose});

  final int brandIndex;
  final String origin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final brands = context.read<AppState>().brands;
    if (brandIndex >= brands.length) return const SizedBox.shrink();
    final b = brands[brandIndex];
    final locations = b.locations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipPath(
              clipper: const ShapeBorderClipper(shape: ArchBorder(bottomRadius: 10)),
              child: SizedBox(width: 46, height: 56, child: Photo(b.image)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(b.name, style: Typo.outfit(24, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.48)),
                  const SizedBox(height: 4),
                  Text(
                    '${b.locationLabel} · Tap to view project',
                    style: Typo.manrope(13, Typo.regular, Palette.subtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconCircleButton(TIcon.close, label: 'Close', onTap: onClose),
          ],
        ),
        const SizedBox(height: 20),
        Text('Choose a location', style: Typo.sectionTitle(19)),
        const SizedBox(height: 12),
        if (locations == null)
          PendingNote(
            lead: '${b.locationLabel} pending.',
            text:
                'The Figma file names ${b.name}’s project count but not its locations. They come from the source '
                'spreadsheet.',
          )
        else
          for (final (i, l) in locations.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            _LocationRow(
              location: l,
              onTap: () => context.go(Screen.project(brandIndex, i, from: origin)),
            ).rise(i + 1),
          ],
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location, required this.onTap});

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = location;
    final meta = '${plural(l.count, 'unit')} · From ${peso(l.from)}';
    final sub = Typo.manrope(13, Typo.regular, Palette.soft);
    return Pressable(
      onTap: onTap,
      semanticLabel: [l.name, ?l.area, meta].join(', '),
      child: Glass(
        radius: 18,
        fill: Palette.white(0.05),
        border: Palette.white(0.1),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                  if (l.area != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const TIconView(TIcon.pin, size: 13, color: Palette.subtle),
                        const SizedBox(width: 5),
                        Text(l.area!, style: sub),
                      ],
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(meta, style: sub),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Chevron(),
          ],
        ),
      ),
    );
  }
}
