import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/app/screen_enter.dart';
import 'package:tahanan/theme/motion.dart';

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount});
  final VoidCallback onMount;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}

void main() {
  for (final style in [EnterStyle.screen, EnterStyle.tab]) {
    testWidgets('$style finishing does not remount page or replay entrance', (tester) async {
      var mounts = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenEnter(
            style: style,
            child: Rise(child: _MountProbe(onMount: () => mounts++)),
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(mounts, 1);
      expect(
        tester.widget<Opacity>(find.descendant(of: find.byType(Rise), matching: find.byType(Opacity)).first).opacity,
        1,
      );
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('revisited page is fully visible immediately', (tester) async {
    final router = AppRouter();
    router.go(Screen.catalog);
    Widget page() => Directionality(
      textDirection: TextDirection.ltr,
      child: ScreenEnter(
        key: ValueKey(router.visit),
        style: router.enter,
        skip: router.hasVisited,
        child: const SizedBox().riseAt(0.5),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pump(const Duration(milliseconds: 50));
    router.go(Screen.home);
    await tester.pumpWidget(const SizedBox());
    router.go(Screen.catalog);
    await tester.pumpWidget(page());
    expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('same project or product from another entry point is still visited', () {
    final router = AppRouter();
    for (final page in [const Screen.project(0, 0), const Screen.product(0, 0, 0)]) {
      router.go(page);
      expect(router.hasVisited, isFalse);
      router.go(Screen.home);
      router.go(Screen(page.kind, a: page.a, b: page.b, c: page.c, id: Discover.home));
      expect(router.hasVisited, isTrue);
    }
    router.go(const Screen.product(0, 0, 1));
    expect(router.hasVisited, isFalse);
  });
}
