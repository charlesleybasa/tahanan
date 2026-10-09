import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/app_state.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/main.dart';

import 'test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final k in [
    ScreenKind.about,
    ScreenKind.application,
    ScreenKind.applicationEdit,
    ScreenKind.booking,
    ScreenKind.project,
    ScreenKind.idCapture,
    ScreenKind.payment,
    ScreenKind.paid,
  ]) {
    testWidgets('$k at Android size', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      final state = await tester.runAsync(AppState.load);
      await tester.pumpWidget(
        TahananApp(
          state: state!,
          router: AppRouter(start: Screen(k)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      tester.view.reset();
    });
  }
}
