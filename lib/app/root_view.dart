import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/home/home_screen.dart';
import '../features/pending/pending_screen.dart';
import '../theme/theme.dart';
import '../widgets/overlays.dart';
import 'app_state.dart';
import 'navigation.dart';
import 'router.dart';
import 'screen_enter.dart';

/// Native `RootView`: background, current screen, floating tab bar, sheet, toast — in that z-order.
class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final state = context.watch<AppState>();
    final screen = router.screen;
    final tab = screen.tab;
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        KeyedSubtree(
          key: ValueKey(router.visit),
          child: ScreenEnter(style: router.enter, child: _screen(screen)),
        ),
        if (tab != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: FloatingTabBar(
              selected: tab,
              onSelect: (t) => context.go(switch (t) {
                MainTab.home => Screen.home,
                MainTab.application => Screen.application,
                MainTab.help => Screen.help,
                MainTab.profile => Screen.profile,
              }),
              onScan: () => context.go(Screen.scan),
            ),
          ),
        if (state.sheet != null)
          BottomSheetPanel(
            key: ValueKey(state.sheet),
            onDismiss: state.closeSheet,
            child: PendingSheet(kind: state.sheet!),
          ),
        ToastHost(toast: state.toast, onDone: state.clearToast),
      ],
    );
  }

  Widget _screen(Screen s) => switch (s.kind) {
    ScreenKind.home => const HomeScreen(),
    _ => PendingScreen(screen: s),
  };
}
