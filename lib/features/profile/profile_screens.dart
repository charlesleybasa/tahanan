import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../sheets/sheets.dart';
import '../../widgets/itext.dart';

const _appVersion = '1.0';

// MARK: Profile

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _selfie(BuildContext context) async {
    final state = context.read<AppState>();
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        state.update(() => state.avatar = bytes);
        unawaited(state.run((r) => r.auth.uploadAvatar(bytes, filename: img.name)));
      }
    } catch (_) {
      state.showToast('Camera isn’t available on this device', icon: TIcon.info, tint: Palette.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    return ScreenScroll(
      bottom: Spacing.tabBarClearance,
      children: [
        Row(
          children: [
            Expanded(child: IText('Profile', style: Typo.h1(32)).rise()),
            IconCircleButton(
              TIcon.settings,
              label: 'Settings',
              onTap: () => context.go(const Screen(ScreenKind.account)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: 108,
                  height: 108,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: (108 - 170) / 2,
                        top: -10,
                        width: 170,
                        height: 150,
                        child: ArchOutline(color: Palette.yellow.o(0.35)),
                      ),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Palette.blue.o(0.6), blurRadius: 20, offset: const Offset(0, 20)),
                          ],
                        ),
                        foregroundDecoration: const ShapeDecoration(
                          shape: CircleBorder(
                            side: BorderSide(
                              color: Palette.yellow,
                              width: 3,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                        ),
                        child: ClipOval(
                          child: state.avatar != null
                              ? Image.memory(state.avatar!, fit: BoxFit.cover)
                              : DecoratedBox(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF3D7BF0), Palette.navy],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(p?.initials ?? 'MS', style: Typo.outfit(36, Typo.bold, Palette.text)),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: 0,
                        child: Tap(
                          onTap: () => _selfie(context),
                          semanticLabel: 'Update selfie',
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Palette.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Palette.night,
                                width: 3,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            child: const TIconView(TIcon.camera, size: 18, color: Palette.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  p?.fullName ?? '',
                  style: Typo.outfit(24, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.48),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(p?.role ?? 'Buyer', tone: PillTone.submitted),
                    const SizedBox(width: 6),
                    StatusPill(
                      p?.homefulId ?? '',
                      background: Palette.white(0.08),
                      foreground: Palette.softer,
                      mono: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: GlassCard(
            children: [
              NavRow(
                onTap: () => context.go(const Screen(ScreenKind.account)),
                children: [
                  IconTile(icon: TIcon.mail, tint: Palette.submittedText, background: Palette.blue.o(0.22)),
                  RowText(title: p?.email ?? '', titleSize: 14, overline: 'Email'),
                  if (state.emailVerification == EmailVerification.verified)
                    const StatusPill('Verified', tone: PillTone.accepted)
                  else
                    const StatusPill('Verify', tone: PillTone.todo),
                ],
              ),
              const RowDivider(),
              NavRow(
                onTap: () => context.go(const Screen(ScreenKind.account)),
                children: [
                  IconTile(icon: TIcon.phone, tint: Palette.submittedText, background: Palette.blue.o(0.22)),
                  RowText(title: p?.mobileMasked ?? '', titleSize: 14, overline: 'Mobile'),
                  const StatusPill('Verified', tone: PillTone.accepted),
                ],
              ),
            ],
          ),
        ).rise(2),
        _overline('Settings').rise(3),
        GlassCard(
          children: [
            _nav(
              TIcon.person,
              'Account details',
              Palette.yellow,
              Palette.yellow.o(0.16),
              () => context.go(const Screen(ScreenKind.account)),
            ),
            const RowDivider(),
            _nav(
              TIcon.shield,
              'Security',
              Palette.acceptedText,
              Palette.green.o(0.18),
              () => context.go(const Screen(ScreenKind.security)),
              trailing: state.biometricsEnabled ? 'Biometrics on' : 'Biometrics off',
            ),
            const RowDivider(),
            _nav(TIcon.help, 'Get help', Palette.todoText, Palette.orange.o(0.16), () => context.go(Screen.help)),
          ],
        ).rise(3),
        _overline('About Homeful').rise(4),
        GlassCard(
          children: [
            _nav(
              TIcon.lock,
              'Privacy Policy',
              Palette.soft,
              Palette.white(0.07),
              () => context.go(const Screen.about(0)),
            ),
            const RowDivider(),
            _nav(
              TIcon.document,
              'Terms and Conditions',
              Palette.soft,
              Palette.white(0.07),
              () => context.go(const Screen.about(1)),
            ),
          ],
        ).rise(4),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: GhostButton(
            'Log out',
            icon: TIcon.logout,
            iconSize: 20,
            tint: Palette.todoText,
            onTap: () async {
              await state.signOut();
              if (context.mounted) context.go(const Screen(ScreenKind.login));
            },
          ),
        ).rise(5),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: IText(
              'Tahanan $_appVersion · by Raemulan Lands',
              textAlign: TextAlign.center,
              style: Typo.manrope(12, Typo.regular, Palette.placeholder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _overline(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
    child: Text(text.toUpperCase(), style: Typo.overline()),
  );

  Widget _nav(TIcon icon, String title, Color tint, Color bg, VoidCallback onTap, {String? trailing}) => NavRow(
    onTap: onTap,
    label: title,
    children: [
      IconTile(icon: icon, tint: tint, background: bg),
      Expanded(child: Text(title, style: Typo.manrope(15, Typo.extrabold, Palette.text))),
      if (trailing != null) Text(trailing, style: Typo.manrope(12, Typo.bold, Palette.subtle)),
      const Chevron(),
    ],
  );
}

// MARK: Account details

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Timer? _linkTimer;

  @override
  void dispose() {
    _linkTimer?.cancel();
    super.dispose();
  }

  void _set(EmailVerification s) {
    final state = context.read<AppState>();
    state.update(() => state.emailVerification = s);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final verified = state.emailVerification == EmailVerification.verified;
    const d = Duration(milliseconds: 500);
    return ScreenScroll(
      bottom: 60,
      children: [
        ScreenHeader(title: 'Account details', onBack: () => context.go(Screen.profile)),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: d,
                    child: DecoratedBox(
                      key: ValueKey(verified),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: verified
                              ? [Palette.green.o(0.22), Palette.green.o(0.08)]
                              : const [Palette.navyLight, Palette.navy],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  right: -30,
                  width: 140,
                  height: 170,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: Palette.white(0.05), shape: const ArchBorder(bottomRadius: 0)),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: d,
                    curve: Motion.easeInOut,
                    decoration: ShapeDecoration(
                      shape: squircle(26, side: hairline(verified ? Palette.green.o(0.4) : Palette.white(0.1))),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('EMAIL VERIFICATION', style: Typo.overline(color: Palette.soft)),
                          ),
                          if (verified)
                            const StatusPill('Verified', tone: PillTone.accepted, icon: TIcon.check)
                          else
                            const StatusPill('Not verified', tone: PillTone.todo),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(state.profile?.email ?? '', style: Typo.manrope(16, Typo.extrabold, Palette.text)),
                      StepSwitch(
                        step: state.emailVerification.index,
                        child: switch (state.emailVerification) {
                          EmailVerification.idle => _idle(),
                          EmailVerification.enterCode => _enterCode(),
                          EmailVerification.openingLink => _opening(),
                          EmailVerification.verified => _done(),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: GlassCard(
            children: [
              NavRow(
                onTap: () => state.showSheet(SheetKind.changeEmail),
                children: [
                  IconTile(icon: TIcon.mail, tint: Palette.submittedText, background: Palette.blue.o(0.22)),
                  const RowText(
                    title: 'Change email address',
                    subtitle: 'New email needs verification',
                    subtitleSize: 12,
                    subtitleColor: Palette.subtle,
                  ),
                  const Chevron(),
                ],
              ),
              const RowDivider(),
              NavRow(
                onTap: () => state.showSheet(SheetKind.changeMobile),
                children: [
                  IconTile(icon: TIcon.phone, tint: Palette.submittedText, background: Palette.blue.o(0.22)),
                  const RowText(
                    title: 'Change mobile number',
                    subtitle: 'Confirmed by SMS code',
                    subtitleSize: 12,
                    subtitleColor: Palette.subtle,
                  ),
                  const Chevron(),
                ],
              ),
            ],
          ),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconTile(icon: TIcon.person, tint: Palette.yellow, background: Palette.yellow.o(0.16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Homeful ID', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                      const SizedBox(height: 2),
                      Text(state.profile?.homefulId ?? '', style: Typo.mono(15, Typo.semibold, Palette.text)),
                    ],
                  ),
                ),
                const StatusPill('Read-only'),
              ],
            ),
          ),
        ).rise(3),
      ],
    );
  }

  Widget _idle() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      IText(
        'Verify to receive booking receipts and password reset links.',
        style: Typo.manrope(14, Typo.regular, Palette.soft).copyWith(height: 1.366 + 5 / 14),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        'Send verification code',
        icon: TIcon.send,
        iconSize: 18,
        onTap: () => _set(EmailVerification.enterCode),
      ),
      const SizedBox(height: 10),
      GhostButton(
        'Email me a link instead',
        icon: TIcon.external,
        onTap: () {
          // The inbox link returns through tahanan://auth/verify-email (RootView). The mock build simulates it.
          unawaited(context.read<AppState>().run((r) => r.auth.sendEmailVerificationLink()));
          _set(EmailVerification.openingLink);
          _linkTimer = Timer(const Duration(milliseconds: 1800), () {
            if (mounted) _set(EmailVerification.verified);
          });
        },
      ),
    ],
  );

  Widget _enterCode() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Text('Enter the 6-digit code we sent.', style: Typo.manrope(14, Typo.regular, Palette.soft)),
      const SizedBox(height: 14),
      const OtpField(initial: '31705', boxWidth: 44, spacing: 7),
      const SizedBox(height: 16),
      PrimaryButton('Verify email', icon: TIcon.check, iconSize: 18, onTap: () => _set(EmailVerification.verified)),
    ],
  );

  Widget _opening() => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        const Spinner(size: 34, lineWidth: 3),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opening verification link…', style: Typo.manrope(14, Typo.extrabold, Palette.text)),
              const SizedBox(height: 2),
              Text(
                'You’ll be brought back to Tahanan automatically.',
                style: Typo.manrope(12, Typo.regular, Palette.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _done() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      children: [
        const CheckDisc(size: 48, iconSize: 24, color: Palette.green).pop(),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You’re verified', style: Typo.manrope(15, Typo.extrabold, Palette.text)),
            const SizedBox(height: 2),
            Text('Welcome back from your inbox.', style: Typo.manrope(13, Typo.regular, Palette.soft)),
          ],
        ).rise(2),
      ],
    ),
  );
}

// MARK: Security

/// Face ID / Touch ID / fingerprint, as native `BiometricService`.
enum BiometricOutcome { success, cancelled, unavailable, failed }

Future<BiometricOutcome> authenticateBiometrics(String reason) async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.canCheckBiometrics || (await auth.getAvailableBiometrics()).isEmpty) {
      return BiometricOutcome.unavailable;
    }
    final ok = await auth.authenticate(localizedReason: reason, biometricOnly: true);
    return ok ? BiometricOutcome.success : BiometricOutcome.failed;
  } on LocalAuthException catch (e) {
    return switch (e.code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.userRequestedFallback => BiometricOutcome.cancelled,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => BiometricOutcome.unavailable,
      _ => BiometricOutcome.failed,
    };
  } catch (e) {
    if (kDebugMode) debugPrint('Biometrics unavailable: $e');
    return BiometricOutcome.unavailable;
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  String _current = '', _new = '', _confirm = '';

  Future<void> _toggle(bool on) async {
    final state = context.read<AppState>();
    if (on) {
      // Confirm with biometrics before enabling (falls through on devices without biometrics).
      final r = await authenticateBiometrics('Turn on biometric login');
      if (r != BiometricOutcome.success && r != BiometricOutcome.unavailable) return;
      state
        ..update(() => state.biometricsEnabled = true)
        ..showToast('Biometric login turned on');
    } else {
      state
        ..update(() => state.biometricsEnabled = false)
        ..showToast('Biometric login turned off');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ScreenScroll(
      bottom: 60,
      children: [
        ScreenHeader(title: 'Security', onBack: () => context.go(Screen.profile)),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                IconTile(
                  icon: TIcon.fingerprint,
                  tint: Palette.yellow,
                  background: Palette.yellow.o(0.16),
                  size: 48,
                  radius: 16,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biometric login', style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                      const SizedBox(height: 2),
                      Text('Face ID or fingerprint', style: Typo.manrope(13, Typo.regular, Palette.muted)),
                    ],
                  ),
                ),
                TahananToggle(value: state.biometricsEnabled, onChanged: _toggle, label: 'Biometric login'),
              ],
            ),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: Text('Change password', style: Typo.sectionTitle(17)),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TahananTextField(
                  label: 'Current password',
                  placeholder: 'Current password',
                  value: _current,
                  onChanged: (v) => _current = v,
                  autofill: AutofillHints.password,
                  secure: true,
                ),
                const SizedBox(height: 14),
                TahananTextField(
                  label: 'New password',
                  placeholder: 'At least 8 characters',
                  value: _new,
                  onChanged: (v) => _new = v,
                  autofill: AutofillHints.newPassword,
                  secure: true,
                ),
                const SizedBox(height: 14),
                TahananTextField(
                  label: 'Confirm new password',
                  placeholder: 'Type it again',
                  value: _confirm,
                  onChanged: (v) => _confirm = v,
                  autofill: AutofillHints.newPassword,
                  secure: true,
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  'Update password',
                  icon: null,
                  onTap: () async {
                    final ok = await state.run((r) => r.auth.changePassword(current: _current, next: _new));
                    if (!ok || !mounted) return;
                    setState(() => _current = _new = _confirm = '');
                    state.showToast('Password updated');
                  },
                ),
                const SizedBox(height: 14),
                Tap(
                  onTap: () => context.go(const Screen(ScreenKind.forgotPassword)),
                  semanticLabel: 'Forgot your current password?',
                  child: SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Forgot your current password?',
                        style: Typo.manrope(14, Typo.extrabold, Palette.yellow),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: ShapeDecoration(
              color: Palette.blue.o(0.12),
              shape: squircle(24, side: hairline(Palette.blue.o(0.3))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TIconView(TIcon.shield, color: Palette.submittedText),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure sessions', style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                      IText(
                        'Your sign-in refreshes every 3 hours. If it can’t refresh, we’ll ask you to log in again.',
                        style: Typo.manrope(13, Typo.regular, Palette.soft).copyWith(height: 1.366 + 5 / 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).rise(3),
      ],
    );
  }
}

// MARK: About

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, required this.doc});

  final int doc;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late int _doc = widget.doc;

  // TODO: API — legal copy from the CMS
  static const _privacy = (
    'Privacy Policy',
    [
      ('What we collect', 'Personal data collected at sign-up and during your application'),
      ('How we use it', 'Purposes of processing'),
      ('Your rights', 'Rights under the Data Privacy Act of 2012'),
      ('Contact our DPO', 'Data Protection Officer contact details'),
    ],
  );
  static const _terms = (
    'Terms and Conditions',
    [
      ('Using Tahanan', 'Account and eligibility terms'),
      ('Bookings and payments', 'Reservation, consultation fee and refund terms'),
      ('Limitations', 'Liability terms'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final (title, sections) = _doc == 0 ? _privacy : _terms;
    return ScreenScroll(
      bottom: 60,
      children: [
        ScreenHeader(title: 'About Homeful', onBack: () => context.go(Screen.profile)),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SegmentedPill(
            options: const ['Privacy Policy', 'Terms'],
            selection: _doc,
            onChanged: (i) => setState(() => _doc = i),
          ),
        ).rise(1),
        KeyedSubtree(
          key: ValueKey(_doc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: IText(title, style: Typo.h1(32)),
              ).rise(2),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Last updated [DATE]', style: Typo.manrope(13, Typo.regular, Palette.subtle)),
              ).rise(2),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, s) in sections.indexed) ...[
                      if (i > 0) const SizedBox(height: 18),
                      Text(s.$1, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                      const SizedBox(height: 4),
                      IText(
                        '[${s.$2} — content from Homeful legal]',
                        style: Typo.manrope(15, Typo.regular, Palette.soft).copyWith(height: 1.366 + 6 / 15),
                      ),
                    ],
                  ],
                ),
              ).rise(3),
            ],
          ),
        ),
      ],
    );
  }
}
