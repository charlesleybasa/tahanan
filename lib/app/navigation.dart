import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'router.dart';

extension Navigate on BuildContext {
  /// Native `router.go(screen, state:)`: closes any sheet, then navigates.
  void go(Screen screen) {
    read<AppState>().closeSheet();
    read<AppRouter>().go(screen);
  }
}
