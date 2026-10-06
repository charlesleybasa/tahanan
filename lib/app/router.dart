import 'package:flutter/foundation.dart';

import '../widgets/overlays.dart';

enum ScreenKind {
  splash,
  onboarding,
  login,
  signup,
  welcome,
  forgotPassword,
  home,
  brand,
  location,
  scan,
  booking,
  payment,
  paid,
  application,
  spouse,
  profile,
  account,
  security,
  about,
  help,
  ticket,
  newTicket,
}

/// A screen in the buyer prototype's `go(screen)` state machine.
@immutable
class Screen {
  const Screen(this.kind, {this.a = 0, this.b = 0, this.id});

  const Screen.brand(int index) : this(ScreenKind.brand, a: index);
  const Screen.location(int brand, int location) : this(ScreenKind.location, a: brand, b: location);
  const Screen.ticket(String ticketId) : this(ScreenKind.ticket, id: ticketId);

  /// About: 0 = privacy, 1 = terms.
  const Screen.about(int doc) : this(ScreenKind.about, a: doc);

  final ScreenKind kind;
  final int a, b;
  final String? id;

  static const home = Screen(ScreenKind.home);
  static const application = Screen(ScreenKind.application);
  static const help = Screen(ScreenKind.help);
  static const profile = Screen(ScreenKind.profile);
  static const scan = Screen(ScreenKind.scan);

  MainTab? get tab => switch (kind) {
    ScreenKind.home => MainTab.home,
    ScreenKind.application => MainTab.application,
    ScreenKind.help => MainTab.help,
    ScreenKind.profile => MainTab.profile,
    _ => null,
  };

  /// Screens that enter without the scale/blur transition (they animate their own content).
  bool get entersPlain => kind == ScreenKind.splash || kind == ScreenKind.location || kind == ScreenKind.forgotPassword;

  @override
  bool operator ==(Object other) =>
      other is Screen && other.kind == kind && other.a == a && other.b == b && other.id == id;

  @override
  int get hashCode => Object.hash(kind, a, b, id);
}

enum EnterStyle { screen, tab, plain }

class AppRouter extends ChangeNotifier {
  AppRouter({Screen start = Screen.home}) : _screen = start;

  Screen _screen;
  int _visit = 0;
  EnterStyle _enter = EnterStyle.plain;

  Screen get screen => _screen;

  /// Bumped on every navigation so re-entering a screen replays its entrance.
  int get visit => _visit;
  EnterStyle get enter => _enter;
  bool get tabSwitch => _enter == EnterStyle.tab;

  /// Callers close any open sheet first (`AppState.closeSheet`), as native `go` does.
  void go(Screen next) {
    if (next == _screen && next.tab != null) return;
    final tab = _screen.tab != null && next.tab != null;
    _enter = next.entersPlain ? EnterStyle.plain : (tab ? EnterStyle.tab : EnterStyle.screen);
    _screen = next;
    _visit++;
    notifyListeners();
  }
}
