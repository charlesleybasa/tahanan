import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData,
        showCupertinoModalPopup;
import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'spouse_model.dart';
import '../../widgets/itext.dart';

final _filledFromID = Palette.green.o(0.55);

/// Complete spouse details: intro (scan / type / invite) → ID scan → 4 steps → Done, or Invite → Invite sent.
class SpouseFlowScreen extends StatefulWidget {
  const SpouseFlowScreen({super.key});

  @override
  State<SpouseFlowScreen> createState() => _SpouseFlowScreenState();
}

class _SpouseFlowScreenState extends State<SpouseFlowScreen> {
  late final SpouseFlowModel _m;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _m = p == null ? SpouseFlowModel() : SpouseFlowModel(mine: p.grossMonthlyIncome, required: p.requiredIncome);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _m.dispose();
    super.dispose();
  }

  String get _key => switch (_m.screen) {
    SpouseScreen.step => 's${_m.step}',
    SpouseScreen.invite => 'invite${_m.inviteSent}',
    final s => s.name,
  };

  void _go(SpouseScreen s, [int step = 0]) => _m.set(() {
    _m.screen = s;
    _m.step = step;
  });

  void _backToApplication() {
    final state = context.read<AppState>();
    state.update(() => state.applicationTab = ApplicationTab.info);
    context.go(Screen.application);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _m,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Palette.night),
          CssRadialGradient(
            rx: 1.1,
            ry: 0.5,
            cx: 0.9,
            cy: -0.08,
            colors: [Palette.blue.o(0.3), Palette.blue.o(0)],
            stops: const [0, 0.6],
          ),
          KeyedSubtree(
            key: ValueKey(_key),
            child: _ScreenIn(
              child: switch (_m.screen) {
                SpouseScreen.intro => _intro(),
                SpouseScreen.idScan => _idScan(),
                SpouseScreen.step => _stepScreen(_m.step),
                SpouseScreen.done => _done(),
                SpouseScreen.invite => _invite(),
              },
            ),
          ),
        ],
      ),
    );
  }

  // MARK: Intro (S00)

  Widget _intro() {
    final initials = context.read<AppState>().profile?.initials ?? 'MS';
    Widget check(TIcon icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            tint: Palette.submittedText,
            background: Palette.blue.o(0.22),
            size: 36,
            radius: 12,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Typo.manrope(14, Typo.bold, Palette.text))),
        ],
      ),
    );
    final divider = SizedBox(
      width: double.infinity,
      height: 1,
      child: ColoredBox(color: Palette.white(0.07)),
    );

    return ScreenScroll(
      children: [
        BackCircleButton(label: 'Back to my application', onTap: _backToApplication),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 120,
                  top: 10,
                  width: 150,
                  height: 150,
                  child: GlowPulse(child: ClosestSideGlow(Palette.yellow, 0.45)),
                ),
                Positioned(
                  left: 70,
                  top: 40,
                  width: 118,
                  height: 150,
                  child: Floating(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A85F5), Color(0xFF2459C9)],
                        ),
                        shape: const ArchBorder(),
                        shadows: [
                          BoxShadow(color: const Color(0xFF000000).o(0.6), blurRadius: 24, offset: const Offset(0, 30)),
                        ],
                      ),
                      child: Text(initials, style: Typo.outfit(34, Typo.bold, Palette.text)),
                    ),
                  ),
                ),
                Positioned(
                  left: 172,
                  top: 56,
                  width: 118,
                  height: 150,
                  child: Floating(
                    period: 7,
                    phase: 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Glass(
                          radius: 0,
                          blur: true,
                          border: const Color(0x00000000),
                          fill: Palette.white(0.06),
                          child: const SizedBox.expand(),
                        ).clipArch(),
                        DashedArch(color: Palette.yellow.o(0.6)),
                        const Center(child: TIconView(TIcon.plus, size: 30, color: Palette.yellow)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text('ASAWA · SPOUSE', style: Typo.eyebrow),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: IText('Add your spouse to your application', style: Typo.h1(34)),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IText(
            'You’re married, so your spouse is part of the home loan. Their income can also count toward your household income.',
            style: Typo.mutedBody(),
          ),
        ).rise(4),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Glass(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Column(
              children: [
                check(TIcon.card, 'Their valid government ID'),
                divider,
                check(TIcon.document, 'TIN and employer details'),
                divider,
                check(TIcon.calendar, 'About 3 minutes · saves as you go'),
              ],
            ),
          ),
        ).rise(5),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              PrimaryButton(
                'Scan their ID to autofill',
                icon: TIcon.scan,
                onTap: () {
                  _m.scan = ScanState.idle;
                  _go(SpouseScreen.idScan);
                },
              ),
              const SizedBox(height: 10),
              GhostButton(
                'Type details myself',
                onTap: () {
                  _m.resetManual();
                  _go(SpouseScreen.step, 0);
                },
              ),
              const SizedBox(height: 10),
              Tap(
                onTap: () {
                  _m.inviteSent = false;
                  _go(SpouseScreen.invite);
                },
                semanticLabel: 'Let my spouse fill it in',
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TIconView(TIcon.send, size: 18, color: Palette.yellow),
                      const SizedBox(width: 8),
                      Text('Let my spouse fill it in', style: Typo.manrope(14, Typo.extrabold, Palette.yellow)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).rise(6),
      ],
    );
  }

  // MARK: ID scan (S01)

  Widget _idScan() => _IdScan(
    model: _m,
    onCancel: () {
      _m.scan = ScanState.idle;
      _go(SpouseScreen.intro);
    },
    onCapture: (scanned) {
      if (_m.scan != ScanState.idle) return;
      _m.set(() => _m.scan = ScanState.reading);
      _timers.add(
        Timer(const Duration(milliseconds: 1600), () {
          _m.set(() => _m.scan = ScanState.ok);
          _timers.add(
            Timer(const Duration(milliseconds: 1100), () {
              // TODO: API — full ID parsing (name, birthdate) server-side; the demo autofills from the prototype.
              _m.applyScannedID(scanned);
              _go(SpouseScreen.step, 0);
            }),
          );
        }),
      );
    },
  );

  // MARK: Form steps (S02–S05)

  Widget _stepScreen(int i) {
    final state = context.read<AppState>();
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            Spacing.gutter,
            insets.top + 150 - 54,
            Spacing.gutter,
            insets.bottom + Spacing.tabBarClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: switch (i) {
              0 => spousePersonalStep(context, _m),
              1 => spouseAddressStep(_m, state.profile?.address ?? ''),
              2 => spouseWorkStep(_m),
              _ => spouseReviewStep(_m, (s) => _go(SpouseScreen.step, s)),
            },
          ),
        ),
        Positioned(left: 0, right: 0, top: 0, child: _stepHeader(i, insets.top)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomCTABar(
            child: PrimaryButton(
              i == 3 ? 'Save spouse details' : 'Continue',
              dimmed: !_m.isValid(i),
              onTap: () => _next(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepHeader(int i, double top) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.night, Palette.night.o(0)],
        stops: const [0.78, 1],
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(Spacing.gutter, top + 52 - 54 + 2, Spacing.gutter, 12),
      child: Column(
        children: [
          Row(
            children: [
              BackCircleButton(onTap: () => i == 0 ? _go(SpouseScreen.intro) : _go(SpouseScreen.step, i - 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spouse information', style: Typo.outfit(19, Typo.semibold, Palette.text)),
                    Text(
                      'Step ${i + 1} of 4 · ${SpouseFlowModel.steps[i]}',
                      style: Typo.manrope(12, Typo.bold, Palette.subtle),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const TIconView(TIcon.check, size: 16, color: Palette.acceptedText),
                  const SizedBox(width: 6),
                  Text('Saved', style: Typo.manrope(12, Typo.extrabold, Palette.acceptedText)),
                ],
              ).fadeIn(0.6),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Step ${i + 1} of 4',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var j = 0; j < 4; j++) ...[
                  if (j > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 4,
                          child: LayoutBuilder(
                            builder: (_, box) => Stack(
                              children: [
                                DecoratedBox(
                                  decoration: ShapeDecoration(color: Palette.white(0.14), shape: const StadiumBorder()),
                                  child: const SizedBox.expand(),
                                ),
                                Container(
                                  width: box.maxWidth * (j < i ? 1 : (j == i ? 0.5 : 0)),
                                  decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            SpouseFlowModel.steps[j],
                            maxLines: 1,
                            style: Typo.manrope(
                              10,
                              Typo.extrabold,
                              j <= i ? Palette.text : Palette.dim,
                            ).copyWith(letterSpacing: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _next(int i) {
    final state = context.read<AppState>();
    if (!_m.isValid(i)) {
      _m.set(() => _m.touched = true);
      state.showToast(
        i == 3 ? 'Please confirm your spouse’s consent' : 'Fill in the highlighted fields',
        icon: TIcon.info,
        tint: Palette.orange,
      );
      return;
    }
    if (i < 3) {
      _go(SpouseScreen.step, i + 1);
    } else {
      _saveSpouse(state);
      _go(SpouseScreen.done);
    }
  }

  void _saveSpouse(AppState state) {
    unawaited(state.run((r) => r.buyer.saveSpouse(_m.toJson())));
    final idx = state.sections.indexWhere((s) => s.id == 'spouse');
    if (idx < 0) return;
    final s = state.sections[idx];
    state.update(() {
      state.sections[idx] = ApplicationSection(
        id: s.id,
        title: s.title,
        subtitle: 'Complete',
        percent: 100,
        cta: 'Edit spouse details',
        fields: [
          SectionField('Full name', _m.fullName),
          SectionField('Employer', _m.employmentType == 'none' ? 'Not working' : _m.employer),
          SectionField('Monthly income', SpouseFlowModel.peso(_m.spouseIncome)),
        ],
      );
    });
  }

  // MARK: Done (S06)

  Widget _done() {
    final top = MediaQuery.paddingOf(context).top;
    Widget todo(TIcon icon, String text) => RowLayout(
      children: [
        IconTile(icon: icon, tint: Palette.todoText, background: Palette.orange.o(0.16)),
        Expanded(child: Text(text, style: Typo.manrope(14, Typo.extrabold, Palette.text))),
        const StatusPill('To upload', tone: PillTone.todo),
      ],
    );
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
                    top: top + 80 - 54,
                    child: LoopingArchRing(t: t, width: 320, height: 360, color: Palette.green.o(0.45), delay: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
        ScreenScroll(
          horizontal: 24,
          top: 140 - 54,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const ProgressRing(
                    fraction: 1,
                    color: Palette.green,
                    size: 120,
                    inner: 100,
                    innerFill: Palette.night,
                    child: TIconView(TIcon.check, size: 48, color: Palette.acceptedText),
                  ).pop(),
                  const SizedBox(height: 36),
                  Text('SPOUSE INFO COMPLETE', style: Typo.eyebrow).rise(3),
                  const SizedBox(height: 10),
                  IText(
                    '${_m.first.isEmpty ? 'Jose' : _m.first} is on your application',
                    textAlign: TextAlign.center,
                    style: Typo.h1(34),
                  ).rise(4),
                  const SizedBox(height: 12),
                  IText(
                    'Your profile is now 84% complete. Next, upload 2 spouse documents.',
                    textAlign: TextAlign.center,
                    style: Typo.mutedBody(),
                  ).rise(5),
                  const SizedBox(height: 22),
                  GlassCard(
                    children: [
                      todo(TIcon.card, 'Spouse valid government ID'),
                      const RowDivider(),
                      todo(TIcon.document, 'Marriage contract (PSA)'),
                    ],
                  ).rise(6),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      PrimaryButton(
                        'Upload documents',
                        icon: TIcon.upload,
                        onTap: () {
                          final state = context.read<AppState>();
                          state.update(() => state.applicationTab = ApplicationTab.requirements);
                          context.go(Screen.application);
                        },
                      ),
                      const SizedBox(height: 10),
                      GhostButton('Back to my application', onTap: _backToApplication),
                    ],
                  ).rise(7),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // MARK: Invite (S07–S08)

  Widget _invite() {
    if (!_m.inviteSent) {
      return ScreenScroll(
        children: [
          BackCircleButton(onTap: () => _go(SpouseScreen.intro)),
          const Padding(
            padding: EdgeInsets.only(top: 26),
            child: IconTile(
              icon: TIcon.send,
              tint: Color(0xFFFFFFFF),
              background: Palette.blue,
              size: 64,
              radius: 22,
              iconSize: 28,
            ),
          ).rise(1),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: IText('Send your spouse a secure link', style: Typo.h1(32)),
          ).rise(2),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: IText(
              'They’ll fill in their own details and ID — no account needed. The link expires in 7 days.',
              style: Typo.mutedBody(),
            ),
          ).rise(3),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              children: [
                TahananTextField(
                  label: 'Spouse’s first name',
                  placeholder: 'Jose',
                  value: _m.inviteName,
                  onChanged: (v) => _m.inviteName = v,
                  autofill: AutofillHints.givenName,
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                PhoneField(label: 'Their mobile number', value: _m.inviteMobile, onChanged: (v) => _m.inviteMobile = v),
              ],
            ),
          ).rise(4),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: PrimaryButton(
              'Send link by SMS',
              icon: TIcon.send,
              iconSize: 18,
              onTap: () {
                unawaited(
                  context.read<AppState>().run(
                    (r) => r.buyer.inviteSpouse(name: _m.inviteName, mobile: _m.inviteMobile),
                  ),
                );
                _m.set(() => _m.inviteSent = true);
              },
            ),
          ).rise(5),
        ],
      );
    }
    final name = _m.inviteName.isEmpty ? 'Jose' : _m.inviteName;
    return ScreenScroll(
      children: [
        BackCircleButton(onTap: () => _go(SpouseScreen.intro)),
        const SizedBox(height: 70),
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              CheckDisc(
                size: 104,
                iconSize: 44,
                color: Palette.blue,
                icon: TIcon.send,
                halos: [(14, Palette.blue.o(0.18))],
              ).pop(),
              const SizedBox(height: 34),
              IText('Link sent to $name', textAlign: TextAlign.center, style: Typo.h1(32)).rise(3),
              const SizedBox(height: 12),
              IText(
                'We’ll notify you when he finishes. You’ll review his details before they’re submitted.',
                textAlign: TextAlign.center,
                style: Typo.mutedBody(),
              ).rise(4),
              const SizedBox(height: 22),
              Glass(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    const Spinner(size: 22, lineWidth: 3),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Waiting for $name', style: Typo.manrope(14, Typo.bold, Palette.text))),
                    Tap(
                      semanticLabel: 'Resend invite',
                      onTap: () async {
                        final state = context.read<AppState>();
                        final ok = await state.run(
                          (r) => r.buyer.inviteSpouse(name: _m.inviteName, mobile: _m.inviteMobile),
                        );
                        if (ok) state.showToast('Invite sent again');
                      },
                      child: SizedBox(
                        height: 40,
                        child: Center(child: Text('Resend', style: Typo.manrope(13, Typo.extrabold, Palette.yellow))),
                      ),
                    ),
                  ],
                ),
              ).rise(5),
              const SizedBox(height: 22),
              GhostButton('Back to my application', onTap: _backToApplication).rise(6),
            ],
          ),
        ),
      ],
    );
  }
}

extension on Widget {
  Widget clipArch() => ClipPath(
    clipper: const ShapeBorderClipper(shape: ArchBorder()),
    child: this,
  );
}

/// Plays the `.scr` entrance on a subtree (fade, scale 1.035 → 1, blur 10 → 0, 0.75 s).
class _ScreenIn extends StatelessWidget {
  const _ScreenIn({required this.child});

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

// MARK: ID scan screen

class _IdScan extends StatefulWidget {
  const _IdScan({required this.model, required this.onCancel, required this.onCapture});

  final SpouseFlowModel model;
  final VoidCallback onCancel;
  final ValueChanged<String?> onCapture;

  @override
  State<_IdScan> createState() => _IdScanState();
}

class _IdScanState extends State<_IdScan> {
  late final MobileScannerController _camera = MobileScannerController(autoStart: false);
  bool _hasCamera = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _camera.start();
      if (mounted) setState(() => _hasCamera = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    // Throws if the camera never started (simulator, permission denied); nothing to release then.
    _camera.dispose().catchError((Object _) {});
    super.dispose();
  }

  String get _message => switch (widget.model.scan) {
    ScanState.ok => 'Got it — Jose R. Santos',
    ScanState.reading => 'Reading the ID…',
    ScanState.idle => 'Place the front of their ID inside the frame',
  };

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final insets = MediaQuery.paddingOf(context);
    final border = m.scan == ScanState.ok
        ? Palette.green
        : (m.scan == ScanState.reading ? Palette.yellow : Palette.white(0.5));
    return LayoutBuilder(
      builder: (context, box) {
        final frame = Rect.fromLTWH(24, 230 - 54 + insets.top, box.maxWidth - 48, 216);
        return ColoredBox(
          color: Palette.scanGround,
          child: Stack(
            children: [
              Positioned.fill(
                child: _hasCamera
                    ? MobileScanner(controller: _camera, fit: BoxFit.cover)
                    : OverflowBox(
                        maxWidth: box.maxWidth + 80,
                        maxHeight: box.maxHeight + 80,
                        child: adjusted(blurred(20, const Photo('photoInterior')), brightness: -0.6),
                      ),
              ),
              Positioned.fill(
                child: DimmedSurround(hole: frame, radius: 22, color: const Color(0x9902060E)),
              ),
              Positioned.fromRect(
                rect: frame,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!_hasCamera) const Padding(padding: EdgeInsets.all(14), child: _FakeID()).fadeIn(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Motion.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: border, width: 3, strokeAlign: BorderSide.strokeAlignInside),
                      ),
                    ),
                    if (m.scan != ScanState.ok)
                      const ScanLine(inset: 14)
                    else
                      Center(
                        child: CheckDisc(
                          size: 76,
                          iconSize: 36,
                          color: Palette.green,
                          halos: [(12, Palette.green.o(0.25))],
                        ).pop(),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 470 - 54 + insets.top,
                child: IText(
                  _message,
                  textAlign: TextAlign.center,
                  style: Typo.manrope(15, Typo.regular, Palette.softer).copyWith(height: 1.366 + 7 / 15),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: insets.top,
                child: Row(
                  children: [
                    IconCircleButton(TIcon.close, label: 'Cancel', onTap: widget.onCancel),
                    Expanded(
                      child: Center(child: Text('Scan spouse ID', style: Typo.outfit(18, Typo.semibold, Palette.text))),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: insets.bottom - 10,
                child: SheetUp(
                  child: Glass(
                    radius: 28,
                    fill: const Color(0xD90D1C38),
                    blur: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IText(
                          'Accepted: PhilSys National ID, UMID, Passport, Driver’s license, PRC ID. We only read the name, birthdate and ID number.',
                          style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.366 + 4 / 13),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton('Capture ID', icon: null, onTap: () => widget.onCapture(null)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FakeID extends StatelessWidget {
  const _FakeID();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -2 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9EEF7), Color(0xFFC9D4E8)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 78,
              height: 96,
              decoration: BoxDecoration(color: const Color(0xFF9DB0CF), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPUBLIKA NG PILIPINAS',
                    style: Typo.manrope(9, Typo.extrabold, Palette.navy).copyWith(letterSpacing: 0.9),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (_, box) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (w, a) in const [(0.8, 0.35), (0.6, 0.25), (0.7, 0.25)]) ...[
                          Container(
                            width: box.maxWidth * w,
                            height: 8,
                            decoration: ShapeDecoration(color: Palette.navy.o(a), shape: const StadiumBorder()),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('•••• •••• 2048', style: Typo.mono(10, Typo.medium, Palette.navy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: Step 1: Personal (S02)

Color? _border(SpouseFlowModel m, String value) => m.fromId && value.isNotEmpty ? _filledFromID : null;

List<Widget> spousePersonalStep(BuildContext context, SpouseFlowModel m) => [
  if (m.fromId)
    Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: Palette.green.o(0.14), borderRadius: BorderRadius.circular(16)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.green.o(0.35), strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Row(
          children: [
            const TIconView(TIcon.check, size: 18, color: Palette.acceptedText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Filled from their ID — please double-check.',
                style: Typo.manrope(13, Typo.regular, const Color(0xFFBFEBD3)),
              ),
            ),
          ],
        ),
      ),
    ).rise(),
  IText('Who is your spouse?', style: Typo.h1(26)).rise(1),
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: IText('Use their name exactly as it appears on their ID.', style: Typo.mutedBody(14)),
  ).rise(1),
  Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TahananTextField(
          label: 'First name',
          placeholder: 'Jose',
          value: m.first,
          onChanged: (v) => m.set(() => m.first = v),
          autofill: AutofillHints.givenName,
          border: _border(m, m.first),
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: m.noMiddleName ? 0.5 : 1,
                child: TahananTextField(
                  label: 'Middle name',
                  placeholder: 'Reyes',
                  value: m.middle,
                  onChanged: (v) => m.set(() => m.middle = v),
                  autofill: AutofillHints.middleName,
                  border: _border(m, m.middle),
                  capitalization: TextCapitalization.words,
                  enabled: !m.noMiddleName,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: TahananTextField(
                label: 'Suffix',
                placeholder: 'Jr.',
                value: m.suffix,
                onChanged: (v) => m.set(() => m.suffix = v),
                autofill: AutofillHints.nameSuffix,
                capitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CheckboxRow(
          value: m.noMiddleName,
          size: 20,
          onChanged: (v) => m.set(() {
            m.noMiddleName = v;
            if (v) m.middle = '';
          }),
          child: Text('No middle name', style: Typo.manrope(13, Typo.regular, Palette.muted)),
        ),
        const SizedBox(height: 14),
        TahananTextField(
          label: 'Last name',
          placeholder: 'Santos',
          value: m.last,
          onChanged: (v) => m.set(() => m.last = v),
          autofill: AutofillHints.familyName,
          border: _border(m, m.last),
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        BirthdateField(
          date: m.birthdate,
          border: m.fromId && m.birthdate != null ? _filledFromID : null,
          onChanged: (d) => m.set(() => m.birthdate = d),
        ),
        const SizedBox(height: 14),
        const FieldLabel('Sex'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final s in const ['Male', 'Female']) ...[
              if (s == 'Female') const SizedBox(width: 8),
              Expanded(
                child: FilterChipButton(
                  s,
                  selected: m.sex == s,
                  height: 52,
                  radius: 16,
                  onTap: () => m.set(() => m.sex = s),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        TahananTextField(
          label: 'Citizenship',
          placeholder: 'Filipino',
          value: m.citizenship,
          onChanged: (v) => m.set(() => m.citizenship = v),
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        PhoneField(
          label: 'Mobile number',
          value: m.mobile,
          onChanged: (v) => m.set(() {
            m.mobile = v;
            m.touched = true;
          }),
          border: m.mobileError ? Palette.orange : null,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Motion.easeInOut,
          child: m.mobileError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const TIconView(TIcon.info, size: 14, color: Palette.todoText),
                      const SizedBox(width: 6),
                      Text('Enter 10 digits, starting with 9', style: Typo.manrope(12, Typo.bold, Palette.todoText)),
                    ],
                  ),
                ).fadeIn(0.2)
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 14),
        TahananTextField(
          label: 'Email',
          labelSuffix: '(optional)',
          placeholder: 'name@email.com',
          value: m.email,
          onChanged: (v) => m.set(() => m.email = v),
          keyboard: TextInputType.emailAddress,
          autofill: AutofillHints.email,
        ),
      ],
    ),
  ).rise(2),
];

/// Date input styled as `.field`; tapping opens an iOS-style wheel picker.
class BirthdateField extends StatelessWidget {
  const BirthdateField({super.key, required this.date, required this.onChanged, this.border, this.label = 'Birthdate'});

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final Color? border;

  static String format(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    var picked = date ?? DateTime(now.year - 30, now.month, now.day);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300 + MediaQuery.paddingOf(ctx).bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
        decoration: BoxDecoration(color: Palette.panel, borderRadius: cornerBox(24, 24, 0, 0)),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: LinkButton('Done', onTap: () => Navigator.of(ctx).pop()).padRight(16),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  primaryColor: Palette.yellow,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: Typo.manrope(21, Typo.regular, Palette.text),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: picked,
                  maximumDate: now,
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        Tap(
          onTap: () => _pick(context),
          semanticLabel: '$label${date == null ? '' : ', ${format(date!)}'}',
          child: FieldChrome(
            focused: false,
            border: border,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null ? 'mm/dd/yyyy' : format(date!),
                      style: Typo.manrope(16, Typo.regular, date == null ? Palette.placeholder : Palette.text),
                    ),
                  ),
                  const TIconView(TIcon.calendar, size: 18, color: Palette.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on Widget {
  Widget padRight(double r) => Padding(
    padding: EdgeInsets.only(right: r),
    child: this,
  );
}

// MARK: Step 2: Address & ID (S03)

Widget _dashedNote(Widget child) =>
    DashedBorder(radius: 18, color: Palette.white(0.14), fill: Palette.white(0.04), child: child);

List<Widget> spouseAddressStep(SpouseFlowModel m, String address) => [
  IText('Address and ID', style: Typo.h1(26)).rise(),
  Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Glass(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconTile(icon: TIcon.home, tint: Palette.yellow, background: Palette.yellow.o(0.16)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lives with me', style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                const SizedBox(height: 2),
                Text('Use my current address', style: Typo.manrope(12, Typo.regular, Palette.subtle)),
              ],
            ),
          ),
          TahananToggle(
            value: m.sameAddress,
            label: 'Same address as mine',
            onChanged: (v) => m.set(() => m.sameAddress = v),
          ),
        ],
      ),
    ),
  ).rise(1),
  AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    switchInCurve: Motion.easeInOut,
    switchOutCurve: Motion.easeInOut,
    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
    child: m.sameAddress
        ? Padding(
            key: const ValueKey('same'),
            padding: const EdgeInsets.only(top: 10),
            child: _dashedNote(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TIconView(TIcon.pin, size: 18, color: Palette.subtle),
                    const SizedBox(width: 10),
                    Expanded(
                      child: IText(
                        address,
                        style: Typo.manrope(14, Typo.regular, Palette.soft).copyWith(height: 1.366 + 6 / 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Padding(
            key: const ValueKey('separate'),
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                TahananTextField(
                  label: 'House no., street',
                  placeholder: 'Blk 4 Lot 12, Sampaguita St.',
                  value: m.street,
                  onChanged: (v) => m.street = v,
                  autofill: AutofillHints.streetAddressLine1,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TahananTextField(
                        label: 'Barangay',
                        placeholder: 'San Juan I',
                        value: m.barangay,
                        onChanged: (v) => m.barangay = v,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TahananTextField(
                        label: 'City',
                        placeholder: 'Ternate',
                        value: m.city,
                        onChanged: (v) => m.city = v,
                        autofill: AutofillHints.addressCity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TahananTextField(
                        label: 'Province',
                        placeholder: 'Cavite',
                        value: m.province,
                        onChanged: (v) => m.province = v,
                        autofill: AutofillHints.addressState,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: TahananTextField(
                        label: 'ZIP',
                        placeholder: '4111',
                        value: m.zip,
                        onChanged: (v) => m.zip = v,
                        keyboard: TextInputType.number,
                        autofill: AutofillHints.postalCode,
                        mono: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
  ),
  Padding(
    padding: const EdgeInsets.only(top: 26),
    child: Text('Valid ID', style: Typo.sectionTitle(17)),
  ).rise(2),
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: EdgeScroller(
      height: 40,
      children: [
        for (final t in SpouseFlowModel.idTypes)
          FilterChipButton(t.label, selected: m.idType == t.id, onTap: () => m.set(() => m.idType = t.id)),
      ],
    ),
  ).rise(2),
  Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TahananTextField(
          label: '${m.idTypeInfo.label} number',
          placeholder: m.idTypeInfo.placeholder,
          value: m.idNumber,
          onChanged: (v) => m.set(() => m.idNumber = v),
          mono: true,
          border: m.fromId && m.idNumber.isNotEmpty
              ? _filledFromID
              : (m.touched && m.idNumber.isEmpty ? Palette.orange : null),
          capitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        TahananTextField(
          label: 'TIN',
          placeholder: '000-000-000-000',
          value: m.tin,
          onChanged: (v) => m.tin = v,
          keyboard: TextInputType.number,
          mono: true,
        ),
        const SizedBox(height: 8),
        Text(
          'No TIN yet? You can add it later — it’s needed before loan approval.',
          style: Typo.manrope(12, Typo.regular, Palette.subtle),
        ),
      ],
    ),
  ).rise(3),
];

// MARK: Step 3: Work & income (S04)

List<Widget> spouseWorkStep(SpouseFlowModel m) => [
  IText('Work and income', style: Typo.h1(26)).rise(),
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: IText('This helps us size your loan. Only Homeful processors see it.', style: Typo.mutedBody(14)),
  ).rise(),
  Padding(
    padding: const EdgeInsets.only(top: 18),
    child: LayoutBuilder(
      builder: (_, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in SpouseFlowModel.employment)
            SizedBox(width: (box.maxWidth - 8) / 2, child: _employmentTile(m, o)),
        ],
      ),
    ),
  ).rise(1),
  AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
    child: m.employmentType != 'none'
        ? Padding(
            key: const ValueKey('working'),
            padding: const EdgeInsets.only(top: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TahananTextField(
                  label: m.employerLabel,
                  placeholder: m.employmentType == 'self' ? 'e.g. Santos Sari-sari Store' : 'Company name',
                  value: m.employer,
                  onChanged: (v) => m.set(() => m.employer = v),
                  autofill: AutofillHints.organizationName,
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                TahananTextField(
                  label: 'Position',
                  placeholder: 'e.g. Staff nurse',
                  value: m.position,
                  onChanged: (v) => m.position = v,
                  autofill: AutofillHints.jobTitle,
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                const FieldLabel('Years in this work'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: Glass(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        _stepper('−', 'Fewer years', () => m.set(() => m.years = math.max(0, m.years - 1))),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${m.years} ${m.years == 1 ? 'year' : 'years'}',
                              style: Typo.outfit(20, Typo.semibold, Palette.text),
                            ),
                          ),
                        ),
                        _stepper(null, 'More years', () => m.set(() => m.years = math.min(40, m.years + 1))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Gross monthly income'),
                const SizedBox(height: 8),
                _IncomeField(model: m),
              ],
            ),
          )
        : Padding(
            key: const ValueKey('none'),
            padding: const EdgeInsets.only(top: 18),
            child: _dashedNote(
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: IText(
                    'No problem — we’ll use your income only. You can update this anytime.',
                    style: Typo.manrope(14, Typo.regular, Palette.soft).copyWith(height: 1.366 + 6 / 14),
                  ),
                ),
              ),
            ),
          ),
  ),
  Padding(
    padding: const EdgeInsets.only(top: 20),
    child: HouseholdIncomeCard(model: m),
  ).rise(3),
];

Widget _employmentTile(SpouseFlowModel m, Employment o) {
  final on = m.employmentType == o.id;
  return Pressable(
    onTap: () => m.set(() => m.employmentType = o.id),
    semanticLabel: o.label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Motion.easeInOut,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: on ? Palette.yellow.o(0.1) : Palette.white(0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: on ? Palette.yellow : Palette.white(0.12),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.label, style: Typo.manrope(14, Typo.extrabold, on ? Palette.yellow : Palette.text)),
          const SizedBox(height: 2),
          Text(o.sub, style: Typo.manrope(11, Typo.regular, Palette.subtle)),
        ],
      ),
    ),
  );
}

Widget _stepper(String? text, String label, VoidCallback onTap) => Tap(
  onTap: onTap,
  semanticLabel: label,
  child: Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Palette.white(0.07), shape: BoxShape.circle),
    child: text != null
        ? Text(text, style: Typo.manrope(20, Typo.bold, Palette.text))
        : const TIconView(TIcon.plus, color: Palette.text),
  ),
);

class _IncomeField extends StatefulWidget {
  const _IncomeField({required this.model});

  final SpouseFlowModel model;

  @override
  State<_IncomeField> createState() => _IncomeFieldState();
}

class _IncomeFieldState extends State<_IncomeField> {
  late final _c = TextEditingController(text: widget.model.incomeDisplay);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    return FieldChrome(
      focused: false,
      border: m.touched && m.incomeDigits.isEmpty ? Palette.orange : null,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text('₱', style: Typo.outfit(18, Typo.semibold, Palette.yellow)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              onChanged: (v) {
                m.set(() => m.incomeDigits = v);
                final shown = m.incomeDisplay;
                _c.value = TextEditingValue(
                  text: shown,
                  selection: TextSelection.collapsed(offset: shown.length),
                );
              },
              style: Typo.outfit(20, Typo.semibold, Palette.text),
              cursorColor: Palette.yellow,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: Typo.outfit(20, Typo.semibold, Palette.placeholder),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// Live household income bar against the required GMI.
class HouseholdIncomeCard extends StatelessWidget {
  const HouseholdIncomeCard({super.key, required this.model});

  final SpouseFlowModel model;

  @override
  Widget build(BuildContext context) {
    final m = model;
    final scale = m.scale;
    final legend = Typo.manrope(12, Typo.bold, Palette.ink);
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Palette.yellow,
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              width: 150,
              height: 180,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: Palette.white(0.22), shape: const ArchBorder(bottomRadius: 0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          'HOUSEHOLD INCOME',
                          style: Typo.manrope(12, Typo.extrabold, Palette.ink).copyWith(letterSpacing: 0.96),
                        ),
                      ),
                      Text(SpouseFlowModel.peso(m.total), style: Typo.outfit(24, Typo.bold, Palette.ink)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 14,
                    child: LayoutBuilder(
                      builder: (_, box) {
                        final w = box.maxWidth;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(end: m.spouseIncome.toDouble()),
                          duration: const Duration(milliseconds: 600),
                          curve: Motion.standard,
                          builder: (_, spouse, _) => Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              DecoratedBox(
                                decoration: ShapeDecoration(color: Palette.ink.o(0.14), shape: const StadiumBorder()),
                                child: const SizedBox.expand(),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: w * m.mine / scale,
                                    decoration: BoxDecoration(color: Palette.ink, borderRadius: cornerBox(7, 0, 0, 7)),
                                  ),
                                  ClipRRect(
                                    borderRadius: cornerBox(0, 7, 7, 0),
                                    child: SizedBox(
                                      width: w * spouse / scale,
                                      height: 14,
                                      child: const CustomPaint(painter: StripesPainter()),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                left: w * m.required / scale,
                                top: -6,
                                width: 2,
                                height: 26,
                                child: const ColoredBox(color: Palette.orange),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _legend(
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: Palette.ink, borderRadius: BorderRadius.circular(3)),
                        ),
                        'You ${SpouseFlowModel.peso(m.mine)}',
                        legend,
                      ),
                      _legend(
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: const SizedBox(width: 10, height: 10, child: CustomPaint(painter: StripesPainter())),
                        ),
                        'Spouse ${SpouseFlowModel.peso(m.spouseIncome)}',
                        legend,
                      ),
                      _legend(
                        const SizedBox(width: 10, height: 2, child: ColoredBox(color: Palette.orange)),
                        'Required ${SpouseFlowModel.peso(m.required)}',
                        legend,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(m.gmiMessage, style: Typo.manrope(13, Typo.extrabold, Palette.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Widget swatch, String text, TextStyle style) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      swatch,
      const SizedBox(width: 6),
      Text(text, style: style),
    ],
  );
}

// MARK: Step 4: Review (S05)

List<Widget> spouseReviewStep(SpouseFlowModel m, ValueChanged<int> edit) {
  Widget card(String title, int step, List<(String, String)> rows) => Glass(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title.toUpperCase(), style: Typo.overline(em: 0.08))),
            Tap(
              onTap: () => edit(step),
              semanticLabel: 'Edit $title',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TIconView(TIcon.edit, size: 14, color: Palette.yellow),
                    const SizedBox(width: 6),
                    Text('Edit', style: Typo.manrope(13, Typo.extrabold, Palette.yellow)),
                  ],
                ),
              ),
            ),
          ],
        ),
        for (final (k, v) in rows)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Palette.white(0.06))),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k, style: Typo.manrope(14, Typo.regular, Palette.subtle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(v, textAlign: TextAlign.right, style: Typo.manrope(14, Typo.bold, Palette.text)),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  final work = m.employmentType == 'none'
      ? [('Status', 'Not working')]
      : [
          ('Status', SpouseFlowModel.employment.firstWhere((e) => e.id == m.employmentType).label),
          (m.employerLabel, m.employer.isEmpty ? '—' : m.employer),
          ('Monthly income', SpouseFlowModel.peso(m.spouseIncome)),
        ];

  return [
    IText('Review and confirm', style: Typo.h1(26)).rise(),
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: IText('Tap Edit to fix anything.', style: Typo.mutedBody(14)),
    ).rise(),
    Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          card('Personal', 0, [
            ('Name', m.fullName.isEmpty ? '—' : m.fullName),
            ('Birthdate', m.birthdateText),
            ('Sex', m.sex),
            ('Mobile', m.mobile.isEmpty ? '—' : '+63 ${m.mobile}'),
          ]),
          const SizedBox(height: 10),
          card('Address & ID', 1, [
            ('Address', m.sameAddress ? 'Same as mine' : 'Separate address'),
            (m.idTypeInfo.label, m.idNumber.isEmpty ? '—' : m.idNumber),
            ('TIN', m.tin.isEmpty ? 'Add later' : m.tin),
          ]),
          const SizedBox(height: 10),
          card('Work & income', 2, work),
        ],
      ),
    ).rise(1),
    Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CheckboxRow(
        value: m.consent,
        onChanged: (v) => m.set(() => m.consent = v),
        child: IText(
          'My spouse agreed to share this information with Homeful for our home loan, under the Data Privacy Act of 2012.',
          style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.366 + 4 / 13),
        ),
      ),
    ).rise(3),
  ];
}
