import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/app_state.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/main.dart';

import 'test_fonts.dart';

Future<(AppState, AppRouter)> _pumpApp(WidgetTester tester, Screen start) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = await tester.runAsync(AppState.load);
  final router = AppRouter(start: start);
  await tester.pumpWidget(TahananApp(state: state!, router: router));
  await _settle(tester);
  return (state, router);
}

/// Steps frame by frame (Ken Burns and video loops never settle, so `pumpAndSettle` can't be used).
Future<void> _settle(WidgetTester tester, [int frames = 25]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Catalog lists 9 brands and filters by home type', (tester) async {
    await _pumpApp(tester, Screen.catalog);
    expect(find.text('All brands'), findsOneWidget);
    await tester.tap(find.text('Condo'));
    await _settle(tester);
    expect(find.text('Pasinaya Heights'), findsOneWidget);
    expect(find.text('Pasinaya Homes'), findsNothing);
  });

  testWidgets('Multi-location brand opens the sheet; a row opens the project', (tester) async {
    final (state, router) = await _pumpApp(tester, Screen.catalog);
    await tester.tap(find.text('Choose location').first);
    await _settle(tester);
    expect(state.sheet, SheetKind.location);
    await tester.tap(find.text('PH Muzon'));
    await _settle(tester);
    expect(router.screen, const Screen.project(0, 1));
  });

  testWidgets('Single-project brand skips the sheet', (tester) async {
    final (state, router) = await _pumpApp(tester, Screen.catalog);
    await tester.dragUntilVisible(find.text('Cluster'), find.text('Condo'), const Offset(-120, 0));
    await _settle(tester, 10);
    await tester.tap(find.text('Cluster'));
    await _settle(tester);
    await tester.tap(find.text('View project'));
    await _settle(tester);
    expect(state.sheet, isNull);
    expect(router.screen, const Screen.project(6, -1));
  });

  testWidgets('Gallery viewer opens on the tapped item and closes back to the page', (tester) async {
    final (_, router) = await _pumpApp(tester, const Screen.project(0, 0));
    await tester.ensureVisible(find.text('Project tour'));
    await _settle(tester, 5);
    await tester.tap(find.text('Project tour'));
    await _settle(tester);
    expect(find.text('1 of 8'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await _settle(tester);
    expect(find.text('1 of 8'), findsNothing);
    expect(router.screen, const Screen.project(0, 0));
  });

  testWidgets('Product page shows the affordability check', (tester) async {
    await _pumpApp(tester, const Screen.product(8, 0, 1));
    expect(find.text('Below the required income'), findsOneWidget);
    expect(find.text('Add spouse income'), findsOneWidget);
  });
}
