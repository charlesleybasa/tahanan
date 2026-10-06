import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'router.dart';

/// Plays a screen's entrance. The outgoing screen is removed immediately, as in the prototype.
///
/// * [EnterStyle.screen] — `.scr`: opacity 0 → 1, scale 1.035 → 1, blur 10 → 0, 0.75 s standard.
/// * [EnterStyle.tab] — 0.18 s ease-out fade; `.rise` content shows in place.
/// * [EnterStyle.plain] — no transition.
class ScreenEnter extends StatefulWidget {
  const ScreenEnter({super.key, required this.style, required this.child});

  final EnterStyle style;
  final Widget child;

  @override
  State<ScreenEnter> createState() => _ScreenEnterState();
}

class _ScreenEnterState extends State<ScreenEnter> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: widget.style == EnterStyle.tab ? Motion.tabSwitch : Motion.screen,
    value: widget.style == EnterStyle.plain ? 1 : 0,
  )..forward();

  late final _t = CurvedAnimation(parent: _c, curve: widget.style == EnterStyle.tab ? Curves.easeOut : Motion.standard);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = SkipEntrance(skip: widget.style == EnterStyle.tab, child: widget.child);
    if (widget.style == EnterStyle.plain) return child;
    final scaled = widget.style == EnterStyle.screen;
    return AnimatedBuilder(
      animation: _t,
      child: child,
      builder: (context, child) {
        final p = _t.value;
        if (p >= 1) return child!;
        Widget w = Opacity(opacity: p.clamp(0, 1), child: child);
        if (scaled) {
          w = Transform.scale(scale: mix(1.035, 1, p), child: blurred(10 * (1 - p), w));
        }
        return w;
      },
    );
  }
}
