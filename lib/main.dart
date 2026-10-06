import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app_state.dart';
import 'app/root_view.dart';
import 'app/router.dart';
import 'theme/theme.dart';
import 'widgets/scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait is locked in Info.plist / AndroidManifest. Edge-to-edge with light bar content over the dark ground.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  final state = await AppState.load();
  runApp(
    TahananApp(
      state: state,
      router: AppRouter(start: _startScreen),
    ),
  );
}

/// Debug builds accept `--dart-define=START=<screen>` to open a screen directly, like native `-start`.
const _start = String.fromEnvironment('START');

Screen get _startScreen {
  for (final k in ScreenKind.values) {
    if (k.name == _start) return Screen(k);
  }
  return Screen.home;
}

class TahananApp extends StatelessWidget {
  const TahananApp({super.key, required this.state, required this.router});

  final AppState state;
  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: router),
      ],
      child: MaterialApp(
        title: 'Tahanan',
        debugShowCheckedModeBanner: false,
        theme: TahananTheme.dark,
        darkTheme: TahananTheme.dark,
        themeMode: ThemeMode.dark,
        scrollBehavior: const TahananScrollBehavior(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: maxTextScale)),
            child: child!,
          );
        },
        home: const Material(
          type: MaterialType.transparency,
          // Replaces Material's inherited body style (which carries height 1.43) so text uses the fonts'
          // own line metrics, as SwiftUI does.
          child: DefaultTextStyle(style: rootTextStyle, child: RootView()),
        ),
      ),
    );
  }
}
