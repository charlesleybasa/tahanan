import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

enum MainTab { home, application, help, profile }

/// Glass pill (inset 14, bottom 20, 74 tall, radius 37) with a raised yellow Scan button and pulsing ring.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({super.key, required this.selected, required this.onSelect, required this.onScan});

  final MainTab? selected;
  final ValueChanged<MainTab> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    const shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(37)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: shape,
                  shadows: [
                    BoxShadow(color: const Color(0xFF000000).o(0.6), blurRadius: 22, offset: const Offset(0, 24)),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRSuperellipse(
                borderRadius: const BorderRadius.all(Radius.circular(37)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: Palette.tabGlass,
                      shape: shape.copyWith(side: hairline(Palette.white(0.1))),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item(MainTab.home, TIcon.home, 'Tahanan', 'Home'),
                    _item(MainTab.application, TIcon.document, 'My docs', 'My application'),
                    _ScanButton(onTap: onScan),
                    _item(MainTab.help, TIcon.help, 'Help', 'Help'),
                    _item(MainTab.profile, TIcon.person, 'Profile', 'Profile'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(MainTab tab, TIcon icon, String title, String label) {
    final on = selected == tab;
    return Tap(
      onTap: () => onSelect(tab),
      semanticLabel: label,
      selected: on,
      child: SizedBox(
        width: 62,
        height: 58,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: on ? Palette.yellow : Palette.tabIdle),
          duration: const Duration(milliseconds: 250),
          curve: Motion.easeInOut,
          builder: (context, c, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TIconView(icon, size: 22, color: c),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: Typo.manrope(11, Typo.extrabold, c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Scan QR',
        child: SizedBox.square(
          dimension: 66,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(left: -5, top: -5, width: 76, height: 76, child: PulseRing(color: Palette.yellow.o(0.55))),
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.ink, width: 5),
                  boxShadow: [BoxShadow(color: Palette.yellow.o(0.5), blurRadius: 12, offset: const Offset(0, 14))],
                ),
                child: const TIconView(TIcon.scan, size: 26, color: Palette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: Toast

class ToastData {
  ToastData(this.message, {this.icon = TIcon.check, this.tint = Palette.green});

  final String message;
  final TIcon icon;
  final Color tint;
}

/// `.toast`: light capsule below the status bar, `toastA` 2.4 s (drop in, hold, fade up).
class ToastView extends StatefulWidget {
  const ToastView({super.key, required this.toast});

  final ToastData toast;

  @override
  State<ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<ToastView> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  (double, double) _frame(double p) {
    const c = Motion.standard;
    if (p < 0.12) {
      final k = c.transform(p / 0.12);
      return (k, mix(-16, 0, k));
    }
    if (p < 0.82) return (1, 0);
    final k = c.transform(((p - 0.82) / 0.18).clamp(0, 1));
    return (1 - k, mix(0, -10, k));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.toast;
    return Semantics(
      liveRegion: true,
      label: t.message,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final (o, y) = _frame(_c.value);
          return Opacity(
            opacity: o,
            child: Transform.translate(offset: Offset(0, y), child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
          decoration: BoxDecoration(
            color: Palette.text,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [BoxShadow(color: const Color(0xFF000000).o(0.5), blurRadius: 16, offset: const Offset(0, 20))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.tint, shape: BoxShape.circle),
                child: TIconView(t.icon, size: 16, color: const Color(0xFFFFFFFF)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  t.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.manrope(14, Typo.extrabold, Palette.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: Bottom sheet

/// Scrim rgba(2,6,14,.62) + blur, panel #0F2142 radius 32 with a 44 × 5 handle; sheetUp .55 s.
class BottomSheetPanel extends StatefulWidget {
  const BottomSheetPanel({super.key, required this.onDismiss, required this.child});

  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<BottomSheetPanel> createState() => _BottomSheetPanelState();
}

class _BottomSheetPanelState extends State<BottomSheetPanel> with TickerProviderStateMixin {
  late final _scrim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
  late final _panel = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..forward();
  double _drag = 0;

  @override
  void dispose() {
    _scrim.dispose();
    _panel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Close',
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _scrim, curve: Motion.easeInOut),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const ColoredBox(color: Color(0x9E02060E)),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _panel,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, mix(900, 0, Motion.sheet.transform(_panel.value)) + _drag),
              child: child,
            ),
            child: GestureDetector(
              onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, double.infinity)),
              onVerticalDragEnd: (_) {
                if (_drag > 80) {
                  widget.onDismiss();
                } else {
                  setState(() => _drag = 0);
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22, 12, 22, 34 + bottom),
                decoration: BoxDecoration(
                  color: Palette.panel,
                  borderRadius: cornerBox(32, 32, 0, 0),
                  border: Border(top: BorderSide(color: Palette.white(0.12))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(color: Palette.white(0.2), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps a toast on screen for its 2.4 s run, then clears it.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.toast, required this.onDone});

  final ToastData? toast;
  final VoidCallback onDone;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  Timer? _timer;

  @override
  void didUpdateWidget(ToastHost old) {
    super.didUpdateWidget(old);
    if (widget.toast != old.toast) _arm();
  }

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    if (widget.toast != null) _timer = Timer(const Duration(milliseconds: 2500), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.toast;
    if (t == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Align(
            alignment: Alignment.topCenter,
            child: ToastView(key: ObjectKey(t), toast: t),
          ),
        ),
      ),
    );
  }
}
