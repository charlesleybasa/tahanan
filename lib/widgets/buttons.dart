import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// `.btnY`: the yellow pill, the only primary-action color. 56 tall, navy label, navy chip with an icon.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.title, {
    super.key,
    required this.onTap,
    this.icon = TIcon.arrowRight,
    this.iconSize = 20,
    this.height = 56,
    this.chipSize = 44,
    this.centered = false,
    this.fontSize = 16,
    this.dimmed = false,
  });

  final String title;
  final VoidCallback? onTap;
  final TIcon? icon;
  final double iconSize, height, chipSize, fontSize;
  final bool centered, dimmed;

  @override
  Widget build(BuildContext context) {
    final center = centered || icon == null;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.55 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Motion.easeInOut,
        child: Container(
          height: height,
          padding: EdgeInsets.only(left: 24, right: center ? 24 : (height - chipSize) / 2),
          decoration: BoxDecoration(
            color: Palette.yellow,
            borderRadius: BorderRadius.circular(height / 2),
            // box-shadow: 0 14px 34px -12px rgba(255,196,46,.6)
            boxShadow: [BoxShadow(color: Palette.yellow.o(0.45), blurRadius: 12, offset: const Offset(0, 14))],
          ),
          child: Row(
            mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Flexible(
                fit: center ? FlexFit.loose : FlexFit.tight,
                child: Align(
                  alignment: center ? Alignment.center : Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, maxLines: 1, style: Typo.manrope(fontSize, Typo.extrabold, Palette.ink)),
                  ),
                ),
              ),
              if (!center) ...[
                const SizedBox(width: 8),
                Container(
                  width: chipSize,
                  height: chipSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                  child: TIconView(icon!, size: iconSize, color: Palette.yellow),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.btnG`: ghost pill, 52 tall, white 6% fill with a 14% hairline.
class GhostButton extends StatelessWidget {
  const GhostButton(
    this.title, {
    super.key,
    required this.onTap,
    this.icon,
    this.iconSize = 18,
    this.height = 52,
    this.tint = Palette.text,
  });

  final String title;
  final VoidCallback? onTap;
  final TIcon? icon;
  final double iconSize, height;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        height: height,
        decoration: ShapeDecoration(
          color: Palette.white(0.06),
          shape: StadiumBorder(side: hairline(Palette.white(0.14))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[TIconView(icon!, size: iconSize, color: tint), const SizedBox(width: 10)],
            Text(title, style: Typo.manrope(15, Typo.bold, tint)),
          ],
        ),
      ),
    );
  }
}

/// `.ib`: 44 circle icon button, optionally over a backdrop blur.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton(
    this.icon, {
    super.key,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.border,
    this.noBorder = false,
    this.blur = false,
  });

  final TIcon icon;
  final String label;
  final VoidCallback? onTap;
  final double size, iconSize;
  final Color? background;
  final Color? border;
  final bool noBorder, blur;

  @override
  Widget build(BuildContext context) {
    Widget disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background ?? Palette.white(0.07),
        shape: CircleBorder(side: noBorder ? BorderSide.none : hairline(border ?? Palette.white(0.12))),
      ),
      child: TIconView(icon, size: iconSize, color: Palette.text),
    );
    if (blur) {
      disc = ClipOval(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: disc),
      );
    }
    return Pressable(onTap: onTap, semanticLabel: label, child: disc);
  }
}

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, required this.onTap, this.label = 'Back'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => IconCircleButton(TIcon.arrowLeft, label: label, onTap: onTap);
}

/// Yellow text button (Forgot password?, See all, Edit …) with a 44 touch target.
class LinkButton extends StatelessWidget {
  const LinkButton(this.title, {super.key, required this.onTap, this.size = 14, this.weight = Typo.bold, this.icon});

  final String title;
  final VoidCallback? onTap;
  final double size;
  final FontWeight weight;
  final TIcon? icon;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[TIconView(icon!, size: 16, color: Palette.yellow), const SizedBox(width: 8)],
            Text(title, style: Typo.manrope(size, weight, Palette.yellow)),
          ],
        ),
      ),
    );
  }
}
