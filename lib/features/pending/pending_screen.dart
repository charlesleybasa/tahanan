import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';

/// Stand-in for screens not yet ported from `native_ios_backup/`. Removed once every screen is migrated.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.screen});

  final Screen screen;

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      bottom: screen.tab != null ? Spacing.tabBarClearance : 40,
      children: [
        if (screen.tab == null) BackCircleButton(onTap: () => context.go(Screen.home)),
        const SizedBox(height: 26),
        Text('PORTING IN PROGRESS', style: Typo.eyebrow),
        const SizedBox(height: 12),
        Text(screen.kind.name, style: Typo.h1(34)),
        const SizedBox(height: 10),
        Text('This screen is still being migrated from the native app.', style: Typo.mutedBody()),
      ],
    );
  }
}

class PendingSheet extends StatelessWidget {
  const PendingSheet({super.key, required this.kind});

  final SheetKind kind;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kind.name, style: Typo.sectionTitle()),
        const SizedBox(height: 8),
        Text('This sheet is still being migrated.', style: Typo.mutedBody()),
        const SizedBox(height: 20),
        PrimaryButton('Close', icon: null, onTap: context.read<AppState>().closeSheet),
      ],
    );
  }
}
