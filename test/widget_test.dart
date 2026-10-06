import 'package:flutter_test/flutter_test.dart';
import 'package:tahanan/app/app_state.dart';
import 'package:tahanan/app/router.dart';
import 'package:tahanan/main.dart';

void main() {
  testWidgets('Home renders the dashboard from bundled data', (tester) async {
    final state = await tester.runAsync(AppState.load);
    await tester.pumpWidget(TahananApp(state: state!, router: AppRouter()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Explore communities'), findsOneWidget);
    expect(find.text('Pasinaya Homes'), findsWidgets);
    expect(find.text('Documents in review'), findsOneWidget);
  });

  test('Tab to tab is a tab switch; same tab is a no-op', () {
    final r = AppRouter();
    r.go(Screen.help);
    expect(r.enter, EnterStyle.tab);
    final v = r.visit;
    r.go(Screen.help);
    expect(r.visit, v);
    r.go(const Screen.brand(0));
    expect(r.enter, EnterStyle.screen);
  });
}
