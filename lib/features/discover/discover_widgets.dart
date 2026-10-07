import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';

/// Opens a brand from Home or the catalog. Single-project brands skip the location sheet and go straight to
/// their project page; the rest open "Choose a location".
void openBrand(BuildContext context, int index, {required String from}) {
  final state = context.read<AppState>();
  final b = state.brands[index];
  final locations = b.locations;
  if (locations != null && locations.length == 1) return context.go(Screen.project(index, 0, from: from));
  if (locations == null && b.projects == 1) return context.go(Screen.project(index, -1, from: from));
  HapticFeedback.selectionClick();
  state.showSheet(SheetKind.location, brand: index, origin: from);
}

/// Back button, optional "Back to …" label, and the Tahanan lockup on the right.
class DiscoverTopBar extends StatelessWidget {
  const DiscoverTopBar({super.key, required this.onBack, this.backLabel});

  final VoidCallback onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackCircleButton(onTap: onBack, label: backLabel ?? 'Back'),
        const SizedBox(width: 12),
        Expanded(
          child: backLabel == null
              ? const SizedBox.shrink()
              : Text(
                  backLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.manrope(14, Typo.semibold, Palette.soft),
                ),
        ),
        const SizedBox(width: 12),
        const TahananLockup(markWidth: 26, fontSize: 18),
      ],
    );
  }
}

/// Small frosted label on media: "Artist’s rendering", "Sample photo".
class MediaLabel extends StatelessWidget {
  const MediaLabel(this.text, {super.key, this.dot});

  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
          color: Palette.deep.o(0.66),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(text, style: Typo.manrope(11, Typo.extrabold, Palette.soft).copyWith(letterSpacing: 0.22)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed box for content the source spreadsheet hasn't supplied yet. [lead] is the bold yellow opener.
class PendingNote extends StatelessWidget {
  const PendingNote({super.key, required this.lead, required this.text});

  final String lead, text;

  @override
  Widget build(BuildContext context) {
    final body = Typo.manrope(13, Typo.regular, Palette.soft).copyWith(height: 1.5);
    return DashedBorder(
      radius: 18,
      color: Palette.white(0.22),
      fill: Palette.white(0.03),
      dash: 5,
      gap: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$lead ',
                  style: body.copyWith(color: Palette.yellow, fontWeight: Typo.extrabold),
                ),
                TextSpan(text: text),
              ],
            ),
            style: body,
          ),
        ),
      ),
    );
  }
}

/// Section title with a quiet trailing meta ("3 products").
class SectionRow extends StatelessWidget {
  const SectionRow(this.title, {super.key, this.meta, this.trailing});

  final String title;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: Typo.sectionTitle())),
        if (meta != null) Text(meta!, style: Typo.manrope(13, Typo.regular, Palette.subtle)),
        ?trailing,
      ],
    );
  }
}

/// `.kv`: label left, bold value right, hairline above (none on the first row).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.k, this.value, {super.key, this.first = false, this.valueColor = Palette.text, this.onTap});

  final String k, value;
  final bool first;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: Palette.white(0.08))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k, style: Typo.manrope(14, Typo.regular, Palette.muted))),
          const SizedBox(width: 12),
          // The value hugs the right edge; the label takes the rest and wraps.
          Text(
            value,
            textAlign: TextAlign.right,
            style: Typo.manrope(
              14,
              Typo.extrabold,
              valueColor,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const TIconView(TIcon.chevronRight, size: 16, color: Palette.subtle),
          ],
        ],
      ),
    );
    return onTap == null ? row : Pressable(onTap: onTap, semanticLabel: '$k, $value', scale: 0.985, child: row);
  }
}

/// `.stat`: a small labelled value tile (Floor area / Lot area).
class StatTile extends StatelessWidget {
  const StatTile(this.k, this.value, {super.key});

  final String k, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: Palette.white(0.06), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: Typo.manrope(12, Typo.regular, Palette.subtle)),
          const SizedBox(height: 3),
          Text(value, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
        ],
      ),
    );
  }
}

/// Floor area / Lot area pair.
class AreaStats extends StatelessWidget {
  const AreaStats({super.key, required this.floor, required this.lot});

  final String floor, lot;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: StatTile('Floor area', floor)),
      const SizedBox(width: 8),
      Expanded(child: StatTile('Lot area', lot)),
    ],
  );
}

/// Yellow display price (Outfit 700).
Text priceText(String text, {double size = 22}) =>
    Text(text, style: Typo.outfit(size, Typo.bold, Palette.yellow).copyWith(letterSpacing: -0.01 * size));

/// Muted 13 pt caption above a value.
Text captionText(String text) => Text(text, style: Typo.manrope(13, Typo.regular, Palette.muted));

/// Body copy at 13–14 pt with the prototype's 1.5 line height.
Text noteText(String text, {double size = 13, Color color = Palette.soft}) =>
    Text(text, style: Typo.manrope(size, Typo.regular, color).copyWith(height: 1.5));
