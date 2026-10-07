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
  catalog,
  project,
  product,
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
  const Screen(this.kind, {this.a = 0, this.b = 0, this.c = 0, this.id});

  /// A brand's location page. [location] is -1 when the spreadsheet hasn't named it yet.
  /// [from] is where Back returns: [Discover.home] or [Discover.catalog].
  const Screen.project(int brand, int location, {String from = Discover.catalog})
    : this(ScreenKind.project, a: brand, b: location, id: from);
  const Screen.product(int brand, int location, int product, {String from = Discover.catalog})
    : this(ScreenKind.product, a: brand, b: location, c: product, id: from);
  const Screen.ticket(String ticketId) : this(ScreenKind.ticket, id: ticketId);

  /// About: 0 = privacy, 1 = terms.
  const Screen.about(int doc) : this(ScreenKind.about, a: doc);

  final ScreenKind kind;
  final int a, b, c;
  final String? id;

  static const home = Screen(ScreenKind.home);
  static const application = Screen(ScreenKind.application);
  static const help = Screen(ScreenKind.help);
  static const profile = Screen(ScreenKind.profile);
  static const scan = Screen(ScreenKind.scan);
  static const catalog = Screen(ScreenKind.catalog);

  MainTab? get tab => switch (kind) {
    ScreenKind.home => MainTab.home,
    ScreenKind.application => MainTab.application,
    ScreenKind.help => MainTab.help,
    ScreenKind.profile => MainTab.profile,
    _ => null,
  };

  /// Screens that enter without the scale/blur transition (they animate their own content).
  bool get entersPlain => kind == ScreenKind.splash || kind == ScreenKind.forgotPassword;

  @override
  bool operator ==(Object other) =>
      other is Screen && other.kind == kind && other.a == a && other.b == b && other.c == c && other.id == id;

  @override
  int get hashCode => Object.hash(kind, a, b, c, id);
}

/// Where a Discover page was opened from, so Back returns there.
abstract final class Discover {
  static const home = 'home';
  static const catalog = 'catalog';
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
