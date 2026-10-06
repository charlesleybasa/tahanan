import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'itext.dart';

/// `.glass`: white 5.5% fill + 1 pt white 9% hairline on a continuous rounded rectangle,
/// with an optional backdrop blur for floating surfaces.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    this.radius = Radii.card,
    this.fill,
    this.border,
    this.blur = false,
    this.padding,
    required this.child,
  });

  final double radius;
  final Color? fill;
  final Color? border;
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = squircle(radius, side: hairline(border ?? Palette.white(0.09)));
    Widget box = DecoratedBox(
      decoration: ShapeDecoration(color: fill ?? Palette.white(0.055), shape: shape),
      position: DecorationPosition.background,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    // Hairline drawn on top of content, like SwiftUI `.overlay(strokeBorder)`.
    box = DecoratedBox(
      decoration: ShapeDecoration(shape: shape),
      position: DecorationPosition.foreground,
      child: box,
    );
    if (blur) {
      box = ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: box),
      );
    }
    return box;
  }
}

/// Grouped rows clipped into a glass card.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, this.radius = Radii.card, this.padding = EdgeInsets.zero, required this.children});

  final double radius;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: Glass(
        radius: radius,
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }
}

// MARK: Status pills

enum PillTone {
  accepted,
  reviewed,
  submitted,
  todo,
  muted;

  (Color, Color) get colors => switch (this) {
    accepted => (Palette.green.o(0.18), Palette.acceptedText),
    reviewed => (Palette.yellow.o(0.16), Palette.reviewedText),
    submitted => (Palette.blue.o(0.24), Palette.submittedText),
    todo => (Palette.orange.o(0.17), Palette.todoText),
    muted => (Palette.white(0.08), Palette.label),
  };
}

/// `.pill`: 26 tall capsule, 12 / 800.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.text, {
    super.key,
    this.tone = PillTone.muted,
    this.background,
    this.foreground,
    this.icon,
    this.height = 26,
    this.mono = false,
    this.horizontalPadding = 10,
    this.fontSize = 12,
  });

  final String text;
  final PillTone tone;
  final Color? background, foreground;
  final TIcon? icon;
  final double height, horizontalPadding, fontSize;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone.colors;
    final f = foreground ?? fg;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(color: background ?? bg, borderRadius: BorderRadius.circular(height / 2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[TIconView(icon!, size: 13, color: f), const SizedBox(width: 6)],
          Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: mono ? Typo.mono(fontSize, Typo.semibold, f) : Typo.manrope(fontSize, Typo.extrabold, f),
          ),
        ],
      ),
    );
  }
}

// MARK: Rows

/// `.ico`: 42 rounded-square icon tile.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.background,
    this.size = 42,
    this.radius = 14,
    this.iconSize = 20,
  });

  final TIcon icon;
  final Color tint, background;
  final double size, radius, iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: background, shape: squircle(radius)),
      child: TIconView(icon, size: iconSize, color: tint),
    );
  }
}

/// `.row`: 64 min height, 12 / 16 padding, 14 gap.
class RowLayout extends StatelessWidget {
  const RowLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 14));
      spaced.add(children[i]);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64, minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(children: spaced),
      ),
    );
  }
}

/// Inset hairline between rows: 1 pt white 7%, 16 pt side margins.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key, this.inset = 16, this.opacity = 0.07});

  final double inset, opacity;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: inset),
    child: SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: Palette.white(opacity)),
    ),
  );
}

/// Two-line text block inside rows. Fills remaining row width.
class RowText extends StatelessWidget {
  const RowText({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 15,
    this.subtitleSize = 13,
    this.subtitleColor = Palette.muted,
    this.subtitleMono = false,
    this.overline,
  });

  final String title;
  final String? subtitle, overline;
  final double titleSize, subtitleSize;
  final Color subtitleColor;
  final bool subtitleMono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overline != null) ...[
            Text(overline!, style: Typo.manrope(12, Typo.bold, Palette.subtle)),
            const SizedBox(height: 2),
          ],
          IText(title, style: Typo.manrope(titleSize, Typo.extrabold, Palette.text)),
          if (subtitle != null) ...[
            SizedBox(height: subtitleMono ? 3 : 2),
            Text(
              subtitle!,
              style: subtitleMono
                  ? Typo.mono(11, Typo.medium, subtitleColor)
                  : Typo.manrope(subtitleSize, Typo.regular, subtitleColor),
            ),
          ],
        ],
      ),
    );
  }
}

// MARK: Chips

/// `.chipb`: 40 tall filter chip.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton(
    this.title, {
    super.key,
    required this.selected,
    required this.onTap,
    this.selectedFill = Palette.yellow,
    this.height = 40,
    this.radius,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedFill;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? height / 2;
    return Tap(
      onTap: onTap,
      selected: selected,
      semanticLabel: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Motion.easeInOut,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: selected ? selectedFill : Palette.white(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r),
            side: hairline(selected ? selectedFill : Palette.white(0.14)),
          ),
        ),
        // Hug the label, except fixed-radius chips (Male / Female), which fill their slot as in native.
        child: Center(
          widthFactor: radius == null ? 1 : null,
          heightFactor: 1,
          child: Text(title, maxLines: 1, style: Typo.manrope(14, Typo.bold, selected ? Palette.ink : Palette.softer)),
        ),
      ),
    );
  }
}

/// Two-option segmented control in a glass pill (Personal info / Requirements, Privacy / Terms).
class SegmentedPill extends StatelessWidget {
  const SegmentedPill({super.key, required this.options, required this.selection, required this.onChanged, this.badge});

  final List<String> options;
  final int selection;
  final ValueChanged<int> onChanged;
  final int? Function(int)? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Glass(
        radius: 27,
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - 4 * (options.length - 1)) / options.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Motion.easeInOut,
                  left: selection * (w + 4),
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      SizedBox(
                        width: w,
                        child: Tap(
                          onTap: () => onChanged(i),
                          selected: selection == i,
                          semanticLabel: options[i],
                          child: _segment(i),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(int i) {
    final n = badge?.call(i);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Motion.easeInOut,
            style: Typo.manrope(14, Typo.extrabold, selection == i ? Palette.ink : Palette.soft),
            child: Text(options[i]),
          ),
          if (n != null) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const ShapeDecoration(color: Palette.orange, shape: StadiumBorder()),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text('$n', style: Typo.manrope(11, Typo.extrabold, const Color(0xFFFFFFFF))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// MARK: Progress ring

/// conic-gradient ring with an inner disc.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.size,
    required this.inner,
    this.track,
    this.innerFill = Palette.panelDeep,
    this.child,
  });

  final double fraction, size, inner;
  final Color color;
  final Color? track;
  final Color innerFill;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(fraction, color, track ?? Palette.white(0.1)),
        child: Center(
          child: Container(
            width: inner,
            height: inner,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: innerFill, shape: BoxShape.circle),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);

  final double fraction;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = track);
    if (fraction <= 0) return;
    canvas.drawArc(rect, -1.5707963267948966, 6.283185307179586 * fraction.clamp(0, 1), true, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}

// MARK: Misc

/// Avatar circle with initials (Outfit 700).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 46, this.fontSize = 16, this.ring});

  final String initials;
  final double size, fontSize;
  final BorderSide? ring;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: Palette.avatarGradient, shape: BoxShape.circle),
        foregroundDecoration: ring == null ? null : ShapeDecoration(shape: CircleBorder(side: ring!)),
        child: Text(initials, style: Typo.outfit(fontSize, Typo.bold, Palette.text)),
      ),
    );
  }
}

/// Key / value line inside summary cards.
class SummaryLine extends StatelessWidget {
  const SummaryLine(
    this.k,
    this.value, {
    super.key,
    this.valueColor = Palette.text,
    this.divider = true,
    this.verticalPadding = 12,
    this.mono = false,
  });

  final String k, value;
  final Color valueColor;
  final bool divider, mono;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            children: [
              Text(k, style: Typo.manrope(14, Typo.regular, Palette.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: mono ? Typo.mono(14, Typo.semibold, valueColor) : Typo.manrope(14, Typo.extrabold, valueColor),
                ),
              ),
            ],
          ),
        ),
        if (divider)
          SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: Palette.white(0.08)),
          ),
      ],
    );
  }
}

/// Chevron used at the end of navigation rows.
class Chevron extends StatelessWidget {
  const Chevron({super.key});

  @override
  Widget build(BuildContext context) => const TIconView(TIcon.chevronRight, color: Palette.muted);
}

/// A full-width glass row that navigates.
class NavRow extends StatelessWidget {
  const NavRow({super.key, required this.onTap, required this.children, this.label});

  final VoidCallback onTap;
  final List<Widget> children;
  final String? label;

  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    semanticLabel: label,
    child: RowLayout(children: children),
  );
}
