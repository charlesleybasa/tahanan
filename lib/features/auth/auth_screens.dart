import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/scaffold.dart';
import '../profile/profile_screens.dart' show BiometricOutcome, authenticateBiometrics;
import '../../widgets/itext.dart';

/// "New to Tahanan? Create an account" style footer link.
class _FooterLink extends StatelessWidget {
  const _FooterLink(this.prompt, this.action, this.onTap);

  final String prompt, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: Typo.manrope(15, Typo.regular, Palette.muted)),
        Tap(
          onTap: onTap,
          semanticLabel: action,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(action, style: Typo.manrope(15, Typo.extrabold, Palette.yellow)),
          ),
        ),
      ],
    ),
  );
}

// MARK: Login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '', _password = '';
  bool _busy = false;

  Future<void> _logIn() async {
    if (_busy) return;
    _busy = true;
    try {
      await context.read<AppState>().signIn(email: _email, password: _password);
      if (mounted) context.go(Screen.home);
    } finally {
      _busy = false;
    }
  }

  Future<void> _biometricLogIn() async {
    switch (await authenticateBiometrics('Log in to Tahanan')) {
      case BiometricOutcome.success:
      case BiometricOutcome.unavailable:
        // TODO: API — exchange the stored refresh token for a new session instead of a mock sign-in.
        // Demo: devices without biometrics (and simulators) go straight in.
        await _logIn();
      case BiometricOutcome.cancelled:
      case BiometricOutcome.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        // Hero photo: 360 tall (under the status bar), 75% opacity, Ken Burns, fading into the night ground.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 360 + top,
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Opacity(opacity: 0.75, child: Photo('photoPH', kenBurns: true)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Palette.night.o(0.35), Palette.night.o(0.55), Palette.night],
                      stops: const [0, 0.45, 0.96],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ScreenScroll(
          horizontal: Spacing.authGutter,
          children: [
            const TahananLockup().rise(),
            const SizedBox(height: 150),
            Text('MALIGAYANG PAGBABALIK', style: Typo.eyebrow).rise(1),
            const SizedBox(height: 10),
            IText('Log in to your tahanan', style: Typo.h1(36)).rise(2),
            const SizedBox(height: 28),
            TahananTextField(
              label: 'Email address',
              placeholder: 'you@email.com',
              value: _email,
              onChanged: (v) => _email = v,
              keyboard: TextInputType.emailAddress,
              autofill: AutofillHints.email,
            ).rise(3),
            const SizedBox(height: 16),
            TahananTextField(
              label: 'Password',
              placeholder: 'Your password',
              value: _password,
              onChanged: (v) => _password = v,
              autofill: AutofillHints.password,
              secure: true,
            ).rise(4),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: LinkButton('Forgot password?', onTap: () => context.go(const Screen(ScreenKind.forgotPassword))),
            ).rise(4),
            const SizedBox(height: 16),
            PrimaryButton('Log in', onTap: _logIn).rise(5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(height: 1, child: ColoredBox(color: Palette.white(0.1))),
                  ),
                  const SizedBox(width: 12),
                  Text('OR', style: Typo.manrope(12, Typo.bold, Palette.placeholder)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(height: 1, child: ColoredBox(color: Palette.white(0.1))),
                  ),
                ],
              ),
            ).rise(6),
            GhostButton(
              'Log in with biometrics',
              icon: TIcon.fingerprint,
              iconSize: 22,
              onTap: _biometricLogIn,
            ).rise(6),
            const SizedBox(height: 16),
            _FooterLink(
              'New to Tahanan? ',
              'Create an account',
              () => context.go(const Screen(ScreenKind.signup)),
            ).rise(7),
          ],
        ),
      ],
    );
  }
}

// MARK: Sign up

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _name = '', _email = '', _mobile = '';
  bool _agreed = false;
  late final _terms = TapGestureRecognizer()..onTap = () => context.go(const Screen.about(1));
  late final _privacy = TapGestureRecognizer()..onTap = () => context.go(const Screen.about(0));

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = Typo.manrope(14, Typo.regular, Palette.yellow);
    return Stack(
      children: [
        const Positioned(
          right: -60,
          top: -40,
          width: 240,
          height: 240,
          child: GlowPulse(child: ClosestSideGlow(Palette.yellow, 0.35)),
        ),
        ScreenScroll(
          horizontal: Spacing.authGutter,
          children: [
            BackCircleButton(onTap: () => context.go(const Screen(ScreenKind.login))).rise(),
            const SizedBox(height: 28),
            Text('SUMALI · JOIN', style: Typo.eyebrow).rise(1),
            const SizedBox(height: 10),
            IText('Create your account', style: Typo.h1(36)).rise(2),
            const SizedBox(height: 12),
            IText(
              'Just three details to start. You can complete your buyer profile anytime.',
              style: Typo.mutedBody(),
            ).rise(3),
            const SizedBox(height: 26),
            TahananTextField(
              label: 'Full name',
              placeholder: 'Juan Dela Cruz',
              value: _name,
              onChanged: (v) => _name = v,
              autofill: AutofillHints.name,
              capitalization: TextCapitalization.words,
            ).rise(3),
            const SizedBox(height: 16),
            TahananTextField(
              label: 'Email address',
              placeholder: 'you@email.com',
              value: _email,
              onChanged: (v) => _email = v,
              keyboard: TextInputType.emailAddress,
              autofill: AutofillHints.email,
            ).rise(4),
            const SizedBox(height: 16),
            PhoneField(label: 'Mobile number', value: _mobile, onChanged: (v) => setState(() => _mobile = v)).rise(5),
            const SizedBox(height: 20),
            CheckboxRow(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'I agree to Homeful’s '),
                    TextSpan(text: 'Terms and Conditions', style: link, recognizer: _terms),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: Typo.manrope(14, Typo.regular, Palette.muted).copyWith(height: 1.366 + 3 / 14),
              ),
            ).rise(6),
            const SizedBox(height: 22),
            PrimaryButton(
              'Create account',
              onTap: () async {
                // New users are saved as Leads.
                await context.read<AppState>().signIn(email: _email, password: '');
                if (context.mounted) context.go(const Screen(ScreenKind.welcome));
              },
            ).rise(7),
            const SizedBox(height: 12),
            _FooterLink(
              'Already have an account? ',
              'Log in',
              () => context.go(const Screen(ScreenKind.login)),
            ).rise(8),
          ],
        ),
      ],
    );
  }
}

// MARK: Welcome

/// "Maligayang pagdating!" — the logo assembles as on the splash, with looping arch rings.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Timeline(
              builder: (_, t) => Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: top + 170 - 54,
                    child: LoopingArchRing(t: t, width: 300, height: 380, color: Palette.yellow.o(0.35), delay: 0),
                  ),
                  Positioned(
                    top: top + 120 - 54,
                    child: LoopingArchRing(t: t, width: 420, height: 500, color: Palette.white(0.18), delay: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 115.38,
                    child: Timeline(builder: (_, t) => MarkIntro(width: 120, t: t)),
                  ),
                  const SizedBox(height: 40),
                  Text('ACCOUNT CREATED', style: Typo.eyebrow).riseAt(1.6),
                  const SizedBox(height: 12),
                  IText('Maligayang pagdating!', textAlign: TextAlign.center, style: Typo.h1(38)).riseAt(1.75),
                  const SizedBox(height: 14),
                  IText(
                    'You’re all set. Explore communities now, and scan your seller’s QR whenever you’re ready to book.',
                    textAlign: TextAlign.center,
                    style: Typo.mutedBody(),
                  ).riseAt(1.9),
                  const SizedBox(height: 34),
                  PrimaryButton('Explore homes', onTap: () => context.go(Screen.home)).riseAt(2.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// MARK: Forgot password

/// Forgot password: email → 6-digit code (or reset link) → new password with strength meter → success.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  String _email = '', _new = '', _confirm = '';
  int _resendIn = 42;
  Timer? _resend;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.forgotStartStep > 0) {
      _step = state.forgotStartStep;
      state.forgotStartStep = 0;
    }
  }

  @override
  void dispose() {
    _resend?.cancel();
    super.dispose();
  }

  void _go(int s) {
    setState(() => _step = s);
    if (s == 1 && _resend == null) {
      _resend = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendIn <= 1) t.cancel();
        if (mounted) setState(() => _resendIn = (_resendIn - 1).clamp(0, 99));
      });
    }
  }

  void _back() {
    if (_step == 0 || _step == 3) {
      context.go(const Screen(ScreenKind.login));
    } else {
      _go(_step - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Spacing.authGutter, top + Spacing.belowStatusBar, Spacing.authGutter, 0),
          child: Row(
            children: [
              BackCircleButton(onTap: _back),
              const Spacer(),
              Semantics(
                label: 'Step ${_step + 1} of 4',
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Motion.easeInOut,
                        width: i == _step ? 22 : 6,
                        height: 6,
                        decoration: ShapeDecoration(
                          color: i <= _step ? Palette.yellow : Palette.white(0.22),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Spacing.authGutter, 0, Spacing.authGutter, 40),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _StepEnter(
                child: switch (_step) {
                  0 => _emailStep(),
                  1 => _codeStep(),
                  2 => _passwordStep(),
                  _ => _doneStep(),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepIcon(TIcon icon, Color bg, Color fg) => Padding(
    padding: const EdgeInsets.only(top: 36),
    child: Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: bg, shape: squircle(22)),
      child: TIconView(icon, size: 28, color: fg),
    ),
  ).rise();

  Widget _emailStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIcon(TIcon.lock, Palette.yellow, Palette.ink),
      const SizedBox(height: 24),
      IText('Forgot your password?', style: Typo.h1(34)).rise(1),
      const SizedBox(height: 12),
      IText(
        'Enter your registered email. We’ll send a 6-digit code and a reset link.',
        style: Typo.mutedBody(),
      ).rise(2),
      const SizedBox(height: 28),
      TahananTextField(
        label: 'Registered email',
        placeholder: 'you@email.com',
        value: _email,
        onChanged: (v) => _email = v,
        keyboard: TextInputType.emailAddress,
        autofill: AutofillHints.email,
      ).rise(3),
      const SizedBox(height: 22),
      // TODO: API — send the password reset email
      PrimaryButton('Send reset code', icon: TIcon.send, iconSize: 18, onTap: () => _go(1)).rise(4),
    ],
  );

  Widget _codeStep() {
    final state = context.read<AppState>();
    final s = _resendIn.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIcon(TIcon.mail, Palette.blue, const Color(0xFFFFFFFF)),
        const SizedBox(height: 24),
        IText('Check your inbox', style: Typo.h1(34)).rise(1),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: state.profile?.emailMasked ?? 'm••••••@email.com',
                style: Typo.manrope(15, Typo.bold, Palette.text),
              ),
            ],
          ),
          style: Typo.mutedBody(),
        ).rise(2),
        const SizedBox(height: 28),
        const OtpField(initial: '4829').rise(3),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Resend code in ', style: Typo.manrope(14, Typo.regular, Palette.subtle)),
            Text('0:$s', style: Typo.mono(14, Typo.medium, Palette.text)),
          ],
        ).rise(4),
        const SizedBox(height: 26),
        Column(
          children: [
            PrimaryButton('Verify code', onTap: () => _go(2)),
            const SizedBox(height: 12),
            // TODO: API — the real link opens Mail; Supabase redirects back via tahanan://auth/reset.
            GhostButton('Open reset link instead', icon: TIcon.external, onTap: () => _go(2)),
          ],
        ).rise(5),
      ],
    );
  }

  Widget _passwordStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIcon(TIcon.shield, Palette.green, const Color(0xFFFFFFFF)),
      const SizedBox(height: 24),
      IText('Create a new password', style: Typo.h1(34)).rise(1),
      const SizedBox(height: 24),
      TahananTextField(
        label: 'New password',
        placeholder: 'At least 8 characters',
        value: _new,
        onChanged: (v) => setState(() => _new = v),
        autofill: AutofillHints.newPassword,
        secure: true,
      ).rise(2),
      const SizedBox(height: 14),
      TahananTextField(
        label: 'Confirm new password',
        placeholder: 'Type it again',
        value: _confirm,
        onChanged: (v) => _confirm = v,
        autofill: AutofillHints.newPassword,
        secure: true,
      ).rise(3),
      const SizedBox(height: 16),
      PasswordStrengthMeter(password: _new).rise(4),
      const SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rule('8 or more characters', _new.length >= 8),
          const SizedBox(height: 8),
          _rule('A number and a symbol', PasswordStrength.hasNumberAndSymbol(_new)),
        ],
      ).rise(5),
      const SizedBox(height: 24),
      PrimaryButton('Update password', icon: TIcon.check, iconSize: 18, onTap: () => _go(3)).rise(6),
    ],
  );

  Widget _rule(String text, bool met) => Row(
    children: [
      TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: met ? Palette.acceptedText : Palette.dim),
        duration: const Duration(milliseconds: 200),
        builder: (_, c, _) => TIconView(TIcon.check, size: 16, color: c),
      ),
      const SizedBox(width: 8),
      Text(text, style: Typo.manrope(13, Typo.regular, Palette.muted)),
    ],
  );

  Widget _doneStep() => SizedBox(
    width: double.infinity,
    child: Column(
      children: [
        const SizedBox(height: 110),
        CheckDisc(
          size: 104,
          iconSize: 54,
          color: Palette.green,
          halos: [(14, Palette.green.o(0.15)), (30, Palette.green.o(0.07))],
        ).pop(),
        const SizedBox(height: 40),
        IText('Password updated', style: Typo.h1(34)).rise(3),
        const SizedBox(height: 12),
        IText(
          'Log in with your new password. We’ve signed you out of other devices.',
          textAlign: TextAlign.center,
          style: Typo.mutedBody(),
        ).rise(4),
        const SizedBox(height: 30),
        PrimaryButton('Back to log in', onTap: () => context.go(const Screen(ScreenKind.login))).rise(5),
      ],
    ),
  );
}

/// The `.scr` entrance for in-screen step changes (fade, scale 1.035 → 1, blur 10 → 0, 0.75 s).
class _StepEnter extends StatelessWidget {
  const _StepEnter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.screen,
    curve: Motion.standard,
    child: child,
    builder: (_, p, c) => p >= 1
        ? c!
        : Opacity(
            opacity: p.clamp(0, 1),
            child: Transform.scale(scale: mix(1.035, 1, p), child: blurred(10 * (1 - p), c!)),
          ),
  );
}

abstract final class PasswordStrength {
  static bool hasNumberAndSymbol(String p) =>
      p.contains(RegExp(r'\d')) && p.contains(RegExp(r'[^\p{L}\p{N}\s]', unicode: true));

  /// 0–4 lit bars.
  static int score(String p) {
    if (p.isEmpty) return 0;
    var s = 1;
    if (p.length >= 8) s++;
    if (hasNumberAndSymbol(p)) s++;
    if (p.length >= 12 && p.contains(RegExp(r'[A-Z]'))) s++;
    return s;
  }
}

/// Four 5 pt bars + label.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final score = PasswordStrength.score(password);
    final (label, color, text) = score >= 3
        ? ('Strong', Palette.green, Palette.acceptedText)
        : (score == 2 ? ('Fair', Palette.yellow, Palette.reviewedText) : ('Weak', Palette.orange, Palette.todoText));
    const d = Duration(milliseconds: 250);
    return Semantics(
      label: score > 0 ? 'Password strength: $label' : 'Password strength',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: d,
                curve: Motion.easeInOut,
                height: 5,
                decoration: ShapeDecoration(
                  color: i < score ? color : Palette.white(0.12),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
          if (score > 0) ...[const SizedBox(width: 12), Text(label, style: Typo.manrope(12, Typo.extrabold, text))],
        ],
      ),
    );
  }
}
