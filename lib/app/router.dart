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
  idCapture,
  payment,
  paid,
  application,
  applicationEdit,
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

  /// Edit application, opened on [step] (0 personal … 3 co-borrower).
  const Screen.applicationEdit([int step = 0]) : this(ScreenKind.applicationEdit, a: step);
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

  /// Back-navigation origin does not make a Discover page a new destination.
  Screen get entranceIdentity => switch (kind) {
    ScreenKind.project || ScreenKind.product => Screen(kind, a: a, b: b, c: c),
    _ => this,
  };

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

  /// A unit opened from a seller's booking QR.
  static const scan = 'scan';
}

enum EnterStyle { screen, tab, plain }

class AppRouter extends ChangeNotifier {
  AppRouter({Screen start = Screen.home}) : _screen = start {
    _visited.add(start.entranceIdentity);
  }

  Screen _screen;
  int _visit = 0;
  EnterStyle _enter = EnterStyle.plain;
  final Set<Screen> _visited = {};
  bool _hasVisited = false;

  Screen get screen => _screen;

  /// Bumped on navigation to reset page state; visited pages skip entrances.
  int get visit => _visit;
  EnterStyle get enter => _enter;
  bool get tabSwitch => _enter == EnterStyle.tab;
  bool get hasVisited => _hasVisited;

  /// Callers close any open sheet first (`AppState.closeSheet`), as native `go` does.
  void go(Screen next) {
    if (next == _screen) return;
    final tab = _screen.tab != null && next.tab != null;
    _enter = next.entersPlain ? EnterStyle.plain : (tab ? EnterStyle.tab : EnterStyle.screen);
    _hasVisited = _visited.contains(next.entranceIdentity);
    _visited.add(next.entranceIdentity);
    _screen = next;
    _visit++;
    notifyListeners();
  }
}
