import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/app_state.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/main.dart';

import 'test_fonts.dart';

/// Every screen on every device class must lay out without overflow or exceptions.
class _Device {
  const _Device(this.name, this.size, this.dpr, {this.hinge});

  final String name;

  /// Logical size.
  final Size size;
  final double dpr;

  /// Vertical hinge in logical pixels (Surface Duo).
  final Rect? hinge;
}

const _devices = [
  _Device('iPhone SE (1st gen)', Size(320, 568), 2),
  _Device('iPhone 17 Pro', Size(402, 874), 3),
  _Device('Galaxy Z Fold cover', Size(344, 882), 2.625),
  _Device('Galaxy Z Fold unfolded', Size(690, 829), 2.625),
  _Device('Pixel Fold unfolded', Size(841, 701), 2.625),
  _Device('iPad 11"', Size(834, 1194), 2),
  _Device('Surface Duo spanned', Size(1114, 720), 1, hinge: Rect.fromLTWH(540, 0, 34, 720)),
];

final _screens = [
  for (final k in ScreenKind.values)
    if (k != ScreenKind.splash && k != ScreenKind.onboarding && k != ScreenKind.ticket && k != ScreenKind.scan)
      Screen(k),
  const Screen.ticket('TK-1042'),
  const Screen.project(0, 0),
  const Screen.project(8, 0),
  const Screen.product(0, 0, 0),
  const Screen.product(8, 0, 1),
  const Screen.applicationEdit(1),
];

void main() {
  setUpAll(loadAppFonts);

  for (final d in _devices) {
    testWidgets('All screens lay out on ${d.name}', (tester) async {
      tester.view.physicalSize = d.size * d.dpr;
      tester.view.devicePixelRatio = d.dpr;
      tester.view.padding = FakeViewPadding(top: 47 * d.dpr, bottom: 34 * d.dpr);
      if (d.hinge != null) {
        final h = d.hinge!;
        tester.view.displayFeatures = [
          DisplayFeature(
            bounds: Rect.fromLTWH(h.left * d.dpr, h.top * d.dpr, h.width * d.dpr, h.height * d.dpr),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ];
      }
      addTearDown(tester.view.reset);
      final state = await tester.runAsync(AppState.load);
      for (final s in _screens) {
        await tester.pumpWidget(
          TahananApp(
            state: state!,
            router: AppRouter(start: s),
          ),
          duration: Duration.zero,
        );
        for (var i = 0; i < 14; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final e = tester.takeException();
        expect(e, isNull, reason: '$s on ${d.name}: $e');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
