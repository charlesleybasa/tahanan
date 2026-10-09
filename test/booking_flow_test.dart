import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/app_state.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/main.dart';

import 'test_fonts.dart';

Future<void> _boot(WidgetTester tester, Screen start) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = await tester.runAsync(AppState.load);
  await tester.pumpWidget(
    TahananApp(
      state: state!,
      router: AppRouter(start: start),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Pay: choosing a method opens the reminders, Proceed shows that method', (tester) async {
    await _boot(tester, const Screen(ScreenKind.payment));
    expect(find.text('Credit / Debit card'), findsOneWidget);
    await tester.tap(find.text('InstaPay'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Before you pay'), findsOneWidget);
    await tester.tap(find.text('Proceed with InstaPay'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Scan with'), findsOneWidget);
  });

  testWidgets('My application: the first incomplete section opens by itself, Expand all opens the rest', (
    tester,
  ) async {
    await _boot(tester, Screen.application);
    expect(find.text('START HERE'), findsOneWidget);
    await tester.tap(find.text('Expand all'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Collapse all'), findsOneWidget);
  });
}
