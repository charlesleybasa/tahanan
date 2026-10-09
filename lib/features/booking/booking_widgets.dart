import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';

/// "Attach ID & Selfie → Payment → Complete Form": the three phases of the booking flow, shared by every step screen.
/// Finished phases turn green with a check, the current one is yellow, the connector fills as you advance.
class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.active});

  /// 0, 1 or 2.
  final int active;

  static const _labels = ['Attach ID & Selfie', 'Payment', 'Complete Form'];

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final done = i < active;
      final now = i == active;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Motion.easeInOut,
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Palette.green : (now ? Palette.yellow : Palette.white(0.1)),
              boxShadow: now ? [BoxShadow(color: Palette.yellow.o(0.35), blurRadius: 14)] : null,
            ),
            child: done
                ? const TIconView(TIcon.check, size: 15, color: Color(0xFFFFFFFF)).pop()
                : Text('${i + 1}', style: Typo.manrope(13, Typo.extrabold, now ? Palette.ink : Palette.subtle)),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[i],
            maxLines: 1,
            style: Typo.manrope(10, Typo.bold, i <= active ? Palette.text : Palette.subtle),
          ),
        ],
      );
    }

    Widget line(int i) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 6, right: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: SizedBox(
            height: 2,
            child: Stack(
              children: [
                ColoredBox(color: Palette.white(0.14), child: const SizedBox.expand()),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 450),
                  curve: Motion.upbar,
                  widthFactor: i < active ? 1 : 0,
                  child: const ColoredBox(color: Palette.green, child: SizedBox.expand()),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(children: [dot(0), line(0), dot(1), line(1), dot(2)]);
  }
}

/// Full-screen blurred "working" overlay with a spinner (processing / confirming payment).
class WorkingOverlay extends StatelessWidget {
  const WorkingOverlay(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeIn(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ColoredBox(
            color: Palette.deep.o(0.82),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spinner(size: 56, lineWidth: 4),
                const SizedBox(height: 18),
                Text(message, style: Typo.manrope(16, Typo.extrabold, Palette.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Monday, Oct 12, 2026" for the 7-day completion deadline.
String deadlineLabel(DateTime from, {int days = 7}) {
  const wd = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = from.add(Duration(days: days));
  return '${wd[d.weekday - 1]}, ${mo[d.month - 1]} ${d.day}, ${d.year}';
}
