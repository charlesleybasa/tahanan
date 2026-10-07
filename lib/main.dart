import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show kDebugMode;

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
      router: AppRouter(start: _startScreen(await _start())),
    ),
  );
}

/// Debug builds open a screen directly for design review, like the native `-start` argument:
/// `--dart-define=START=<screen>`, or a `Documents/debug_start` file in the app sandbox (read once, then deleted).
Future<String> _start() async {
  if (!kDebugMode) return '';
  const defined = String.fromEnvironment('START');
  if (defined.isNotEmpty) return defined;
  // The sandbox's tmp/ sits next to Documents/ (Platform.environment is empty on iOS).
  final f = File('${Directory.systemTemp.parent.path}/Documents/debug_start');
  if (!f.existsSync()) return '';
  final v = f.readAsStringSync().trim();
  f.deleteSync();
  return v;
}

Screen _startScreen(String start) {
  switch (start) {
    case 'ticket':
      return const Screen.ticket('TK-1042');
    case 'tradizo': // Terraces Tradizo, Imus
      return const Screen.project(8, 0);
    case 'tradizo1br':
      return const Screen.product(8, 0, 1);
    case 'pending': // Pagsikat Place: locations not named yet
      return const Screen.project(1, -1);
  }
  for (final k in ScreenKind.values) {
    if (k.name == start) return Screen(k);
  }
  return const Screen(ScreenKind.splash);
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
            // Above the Navigator so pushed routes (the gallery viewer) share the root text style.
            child: Material(
              type: MaterialType.transparency,
              // Replaces Material's inherited body style (which carries height 1.43) so text uses the fonts'
              // own line metrics, as SwiftUI does.
              child: DefaultTextStyle(
                style: rootTextStyle,
                // SwiftUI `lineSpacing` adds space only between lines, never above the first or below the last.
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                child: child!,
              ),
            ),
          );
        },
        home: const RootView(),
      ),
    );
  }
}
