import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/application/application_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/discover/catalog_screen.dart';
import '../features/discover/product_screen.dart';
import '../features/discover/project_screen.dart';
import '../features/booking/booking_screens.dart';
import '../features/help/help_screens.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/sheets/sheets.dart';
import '../features/splash/splash_screen.dart';
import '../features/spouse/spouse_flow.dart';
import '../theme/theme.dart';
import '../widgets/overlays.dart';
import 'app_state.dart';
import 'navigation.dart';
import 'router.dart';
import 'screen_enter.dart';

/// Native `RootView`: background, current screen, floating tab bar, sheet, toast — in that z-order.
/// Also receives `tahanan://` deep links (Supabase email and reset redirects).
class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation info) async {
    final uri = info.uri;
    final path = '${uri.host}${uri.path}'.replaceAll(RegExp('^/+'), '');
    final state = context.read<AppState>();
    switch (path) {
      case 'auth/verify-email':
        state.update(() => state.emailVerification = EmailVerification.verified);
        context.go(const Screen(ScreenKind.account));
        return true;
      case 'auth/reset':
        state.forgotStartStep = 2;
        context.go(const Screen(ScreenKind.forgotPassword));
        return true;
    }
    return false;
  }

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
            child: SheetBody(kind: state.sheet!),
          ),
        ToastHost(toast: state.toast, onDone: state.clearToast),
      ],
    );
  }

  Widget _screen(Screen s) => switch (s.kind) {
    ScreenKind.splash => const SplashScreen(),
    ScreenKind.onboarding => const OnboardingScreen(),
    ScreenKind.login => const LoginScreen(),
    ScreenKind.signup => const SignupScreen(),
    ScreenKind.welcome => const WelcomeScreen(),
    ScreenKind.forgotPassword => const ForgotPasswordScreen(),
    ScreenKind.home => const HomeScreen(),
    ScreenKind.catalog => const CatalogScreen(),
    ScreenKind.project => ProjectScreen(brandIndex: s.a, locationIndex: s.b, from: s.id ?? Discover.catalog),
    ScreenKind.product => ProductScreen(
      brandIndex: s.a,
      locationIndex: s.b,
      productIndex: s.c,
      from: s.id ?? Discover.catalog,
    ),
    ScreenKind.scan => const ScanScreen(),
    ScreenKind.booking => const BookingScreen(),
    ScreenKind.payment => const PaymentScreen(),
    ScreenKind.paid => const PaidScreen(),
    ScreenKind.application => const ApplicationScreen(),
    ScreenKind.spouse => const SpouseFlowScreen(),
    ScreenKind.profile => const ProfileScreen(),
    ScreenKind.account => const AccountScreen(),
    ScreenKind.security => const SecurityScreen(),
    ScreenKind.about => AboutScreen(doc: s.a),
    ScreenKind.help => const HelpScreen(),
    ScreenKind.ticket => TicketChatScreen(ticketId: s.id ?? ''),
    ScreenKind.newTicket => const NewTicketScreen(),
  };
}
