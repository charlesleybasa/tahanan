import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/itext.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import 'booking_widgets.dart';

// MARK: Terms sheet

/// Terms & Conditions and Privacy Policy prompt. "I agree and continue" stays off until the text is read to the end.
class TermsSheet extends StatefulWidget {
  const TermsSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends State<TermsSheet> {
  final _scroll = ScrollController();
  bool _atEnd = false;

  // TODO: API — the official Terms & Conditions and Privacy Policy text comes from Homeful (CMS).
  static const _sections = [
    ('Terms & Conditions', 'Welcome to Homeful. [Official wording from Homeful.]'),
    ('1 · Acceptance of terms', '[Official wording from Homeful.]'),
    ('2 · Eligibility', '[Official wording from Homeful.]'),
    ('3 · Account registration', '[Official wording from Homeful.]'),
    ('4 · Privacy Policy', '[Official wording from Homeful.]'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent - _scroll.position.pixels < 24;
    if (end != _atEnd) setState(() => _atEnd = end);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BEFORE YOU BOOK', style: Typo.eyebrow),
        const SizedBox(height: 8),
        IText('Terms & Conditions and Privacy Policy', style: Typo.h1(26)),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ShaderMask(
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF),
                _atEnd ? const Color(0xFFFFFFFF) : const Color(0x00FFFFFF),
              ],
              stops: const [0, 0.85, 1],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (t, b) in _sections) ...[
                    Text(t, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                    const SizedBox(height: 6),
                    IText(b, style: Typo.mutedBody(14)),
                    const SizedBox(height: 18),
                  ],
                  // Placeholder body so the scroll gate is exercised until the real text lands.
                  for (var i = 0; i < 6; i++) ...[
                    IText('[Official wording from Homeful.] ' * 4, style: Typo.mutedBody(14)),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _atEnd ? 'Thanks for reading' : 'Scroll to the bottom to continue',
              key: ValueKey(_atEnd),
              style: Typo.manrope(12, Typo.bold, _atEnd ? Palette.acceptedText : Palette.todoText),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: GhostButton('Cancel', height: 56, onTap: widget.onClose)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                'I agree and continue',
                icon: null,
                dimmed: !_atEnd,
                onTap: () {
                  if (!_atEnd) {
                    HapticFeedback.lightImpact();
                    return;
                  }
                  context.go(const Screen(ScreenKind.idCapture));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// MARK: Payment

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final d = next.text.replaceAll(RegExp(r'\D'), '');
    final t = d.length > 16 ? d.substring(0, 16) : d;
    final out = [for (var i = 0; i < t.length; i += 4) t.substring(i, i + 4 > t.length ? t.length : i + 4)].join(' ');
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final d = next.text.replaceAll(RegExp(r'\D'), '');
    final t = d.length > 4 ? d.substring(0, 4) : d;
    final out = t.length > 2 ? '${t.substring(0, 2)}/${t.substring(2)}' : t;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Booking step 2 — a single screen that moves through three views: method list, card form, InstaPay QR. The Payment
/// reminders sheet opens between choosing a method and entering its details. Details never leave the device here.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _card = '', _expiry = '', _cvv = '';
  String? _working;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _cardValid => _card.replaceAll(' ', '').length >= 13 && _expiry.length == 5 && _cvv.length >= 3;

  Future<void> _pay(String label) async {
    final state = context.read<AppState>();
    setState(() => _working = label);
    String? checkout;
    final ok = await state.run((r) async {
      checkout = await r.payments.createConsultationPayment(
        unitCode: state.profile?.unit.code ?? '',
        method: state.payMethod,
      );
      return checkout;
    });
    if (!mounted) return;
    if (!ok) {
      setState(() => _working = null);
      return;
    }
    // TODO: API — open `checkout` (provider page or SDK) and wait for the payment webhook/deep link before showing the
    // receipt. The mock returns null, so the demo goes straight to the receipt.
    debugPrint('Checkout: $checkout');
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      state.payStage = 'choose';
      context.go(const Screen(ScreenKind.paid));
    });
  }

  void _back() {
    final state = context.read<AppState>();
    if (state.payStage == 'choose') {
      context.go(const Screen(ScreenKind.idCapture));
    } else {
      state.update(() => state.payStage = 'choose');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stage = state.payStage;
    final u = state.profile?.unit;
    final title = switch (stage) {
      'card' => 'Card payment',
      'instapay' => 'InstaPay payment',
      _ => 'Choose payment',
    };
    return Stack(
      children: [
        ScreenScroll(
          bottom: 140,
          children: [
            Row(
              children: [
                BackCircleButton(onTap: _back),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Typo.outfit(19, Typo.semibold, Palette.text)),
                      Text('Step 2 of 3 · Consultation fee', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                    ],
                  ),
                ),
                const TIconView(TIcon.lock, size: 15, color: Palette.acceptedText),
                const SizedBox(width: 6),
                Text('Secure', style: Typo.manrope(12, Typo.extrabold, Palette.acceptedText)),
              ],
            ),
            const Padding(padding: EdgeInsets.fromLTRB(8, 22, 8, 0), child: BookingStepper(active: 1)),
            StepSwitchKeyed(
              keyValue: stage,
              child: switch (stage) {
                'card' => _cardView(state, u),
                'instapay' => _instaView(state, u),
                _ => _chooseView(state, u),
              },
            ),
          ],
        ),
        if (stage == 'card')
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomCTABar(
              child: PrimaryButton(
                'Pay ${u?.consultationFee ?? '₱10,000.00'}',
                icon: TIcon.lock,
                iconSize: 18,
                dimmed: !_cardValid,
                onTap: () {
                  if (!_cardValid) {
                    HapticFeedback.lightImpact();
                    state.showToast('Check your card details', icon: TIcon.info, tint: Palette.orange);
                    return;
                  }
                  unawaited(_pay('Processing payment…'));
                },
              ),
            ),
          ),
        if (_working != null) WorkingOverlay(_working!),
      ],
    );
  }

  Widget _amount(Unit? u) => Padding(
    padding: const EdgeInsets.only(top: 26),
    child: SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: -30,
            width: 260,
            height: 150,
            child: GlowPulse(child: ClosestSideGlow(Palette.yellow, 0.22)),
          ),
          Column(
            children: [
              Text('Amount due', style: Typo.manrope(13, Typo.bold, Palette.muted)),
              const SizedBox(height: 4),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: '₱10,000',
                      style: TextStyle(color: Palette.text),
                    ),
                    TextSpan(
                      text: '.00',
                      style: TextStyle(color: Palette.subtle),
                    ),
                  ],
                ),
                style: Typo.outfit(46, Typo.bold).copyWith(letterSpacing: -0.035 * 46),
              ),
              const SizedBox(height: 6),
              Text('Consultation fee · ${u?.code ?? ''}', style: Typo.mono(12, Typo.medium, Palette.muted)),
            ],
          ),
        ],
      ),
    ),
  );

  // Method list

  Widget _chooseView(AppState state, Unit? u) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _amount(u),
      Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Text('Pay with', style: Typo.sectionTitle(17)),
      ),
      const SizedBox(height: 12),
      _method(state, 'card', 'Credit / Debit card', 'Pay securely with your card', TIcon.card),
      const SizedBox(height: 10),
      _method(state, 'instapay', 'InstaPay', 'Scan QR code to pay', TIcon.bolt),
    ],
  );

  Widget _method(AppState state, String id, String name, String sub, TIcon icon) {
    final on = state.payMethod == id;
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        state.update(() => state.payMethod = id);
        state.showSheet(SheetKind.paymentReminders);
      },
      semanticLabel: name,
      child: Container(
        decoration: BoxDecoration(
          color: on ? Palette.yellow.o(0.08) : Palette.white(0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? Palette.yellow : Palette.white(0.1),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: RowLayout(
          children: [
            IconTile(icon: icon, tint: Palette.yellow, background: Palette.white(0.08)),
            RowText(title: name, subtitle: sub, subtitleSize: 12, subtitleColor: Palette.subtle),
            const Chevron(),
          ],
        ),
      ),
    );
  }

  // Card

  Widget _cardView(AppState state, Unit? u) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 18),
      LinkButton('Change payment method', icon: TIcon.arrowLeft, size: 13, weight: Typo.extrabold, onTap: _back),
      Row(
        children: [
          Expanded(child: Text('Card details', style: Typo.sectionTitle(20))),
          for (final b in const ['VISA', 'MC', 'JCB']) ...[
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(color: Palette.white(0.08), borderRadius: BorderRadius.circular(6)),
              child: Text(b, style: Typo.manrope(10, Typo.extrabold, Palette.soft)),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      TahananTextField(
        label: 'Card number',
        placeholder: '1234 5678 9012 3456',
        value: _card,
        mono: true,
        keyboard: TextInputType.number,
        autofill: AutofillHints.creditCardNumber,
        inputFormatters: [_CardNumberFormatter()],
        onChanged: (v) => setState(() => _card = v),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: TahananTextField(
              label: 'Expiration date',
              placeholder: 'MM/YY',
              value: _expiry,
              mono: true,
              keyboard: TextInputType.number,
              autofill: AutofillHints.creditCardExpirationDate,
              inputFormatters: [_ExpiryFormatter()],
              onChanged: (v) => setState(() => _expiry = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: TahananTextField(
              label: 'CVV',
              placeholder: '123',
              value: _cvv,
              mono: true,
              secure: true,
              keyboard: TextInputType.number,
              autofill: AutofillHints.creditCardSecurityCode,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              onChanged: (v) => setState(() => _cvv = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const TIconView(TIcon.lock, size: 15, color: Palette.acceptedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Card details go straight to the payment provider and are never stored in the app.',
              style: Typo.manrope(12, Typo.semibold, Palette.subtle).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    ],
  );

  // InstaPay

  Widget _instaView(AppState state, Unit? u) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 18),
      LinkButton('Change payment method', icon: TIcon.arrowLeft, size: 13, weight: Typo.extrabold, onTap: _back),
      Glass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text('InstaPay payment', style: Typo.sectionTitle(20)),
              const SizedBox(height: 4),
              Text('₱10,000', style: Typo.outfit(26, Typo.bold, Palette.yellow)),
              const SizedBox(height: 16),
              // TODO: API — replace with the QR Ph payload returned by createConsultationPayment.
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Palette.softer, borderRadius: BorderRadius.circular(20)),
                child: const DecorativeQR(),
              ).pop(),
              const SizedBox(height: 16),
              Text('Scan with', style: Typo.manrope(12, Typo.extrabold, Palette.muted)),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in const ['GCash', 'Maya', 'Hello Money', 'AUB']) StatusPill(a, height: 28),
                ],
              ),
              const SizedBox(height: 10),
              Text('or any mobile banking app', style: Typo.manrope(13, Typo.regular, Palette.muted)),
              const SizedBox(height: 12),
              const StatusPill('Transfer fee may apply', fontSize: 11),
            ],
          ),
        ),
      ).rise(1),
      const SizedBox(height: 14),
      Glass(
        radius: 16,
        fill: Palette.blue.o(0.14),
        border: Palette.blue.o(0.3),
        padding: const EdgeInsets.all(14),
        child: Text.rich(
          TextSpan(
            style: Typo.manrope(13, Typo.regular, Palette.soft).copyWith(height: 1.5),
            children: [
              const TextSpan(text: 'Thank you for choosing InstaPay for your '),
              TextSpan(text: 'Home Loan Consultation Fee', style: Typo.manrope(13, Typo.extrabold, Palette.text)),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text('To proceed, follow the instructions below:', style: Typo.manrope(13, Typo.extrabold, Palette.text)),
      const SizedBox(height: 12),
      for (final (i, t) in const [
        'Download or screenshot the QR code.',
        'Open your mobile banking app.',
        'Scan or upload the InstaPay QR code to proceed with payment.',
      ].indexed) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.blue.o(0.28)),
                child: Text('${i + 1}', style: Typo.manrope(12, Typo.extrabold, Palette.submittedText)),
              ),
              const SizedBox(width: 12),
              Expanded(child: IText(t, style: Typo.manrope(14, Typo.semibold, Palette.soft).copyWith(height: 1.45))),
            ],
          ),
        ),
      ],
      Text(
        'After payment is received, an SMS and email confirmation with the payment details will be sent to you.',
        style: Typo.manrope(12, Typo.regular, Palette.subtle).copyWith(height: 1.5),
      ),
      const SizedBox(height: 18),
      GhostButton(
        'Download QR code',
        icon: TIcon.upload,
        onTap: () {
          // TODO: API — save the real QR image to Photos once the provider returns it.
          state.showToast('Screenshot this QR to pay from your banking app', icon: TIcon.info, tint: Palette.blue);
        },
      ),
      const SizedBox(height: 10),
      PrimaryButton(
        'I’ve completed the payment',
        icon: TIcon.check,
        iconSize: 18,
        onTap: () => unawaited(_pay('Confirming payment…')),
      ),
    ],
  );
}

/// Fades a new child in whenever [keyValue] changes (the old one leaves at once).
class StepSwitchKeyed extends StatelessWidget {
  const StepSwitchKeyed({super.key, required this.keyValue, required this.child});

  final String keyValue;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey(keyValue),
    child: FadeIn(child: child),
  );
}

// MARK: Payment reminders sheet

class PaymentRemindersSheet extends StatelessWidget {
  const PaymentRemindersSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    const items = [
      'Payment of Home Loan Consulting Fee is non-refundable.',
      'Payment of Home Loan Consulting Fee does not guarantee reservation. Reservation is subject to final confirmation.',
      'You will receive an SMS and email notification if payment is successful.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT REMINDERS', style: Typo.eyebrow),
        const SizedBox(height: 8),
        IText('Before you pay', style: Typo.h1(26)),
        const SizedBox(height: 14),
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CheckDisc(size: 24, iconSize: 13, color: Palette.green),
                const SizedBox(width: 12),
                Expanded(child: IText(t, style: Typo.manrope(14, Typo.semibold, Palette.soft).copyWith(height: 1.45))),
              ],
            ),
          ),
        const SizedBox(height: 6),
        PrimaryButton(
          state.payMethod == 'card' ? 'Proceed with card' : 'Proceed with InstaPay',
          onTap: () {
            state.update(() => state.payStage = state.payMethod);
            onClose();
          },
        ),
      ],
    );
  }
}

// MARK: Paid

/// Payment successful: receipt details, then Complete form (opens Getting started) or Fill out later.
class PaidScreen extends StatefulWidget {
  const PaidScreen({super.key});

  @override
  State<PaidScreen> createState() => _PaidScreenState();
}

class _PaidScreenState extends State<PaidScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.heavyImpact());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.profile?.unit;
    final top = MediaQuery.paddingOf(context).top;
    final method = state.payMethod == 'card' ? 'Credit / Debit card' : 'InstaPay';
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
                    top: top + 70 - 54,
                    child: LoopingArchRing(t: t, width: 300, height: 340, color: Palette.green.o(0.45), delay: 0),
                  ),
                  Positioned(
                    top: top + 20 - 54,
                    child: LoopingArchRing(t: t, width: 440, height: 460, color: Palette.yellow.o(0.3), delay: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        ScreenScroll(
          horizontal: 24,
          bottom: 40,
          children: [
            Row(
              children: [
                const SizedBox(width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment confirmation', style: Typo.outfit(19, Typo.semibold, Palette.text)),
                      Text('Step 3 of 3', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.fromLTRB(8, 22, 8, 0), child: BookingStepper(active: 2)),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Palette.green.o(0.35), blurRadius: 40)],
                    ),
                    child: CheckDisc(
                      size: 96,
                      iconSize: 44,
                      color: Palette.green,
                      halos: [(14, Palette.green.o(0.16))],
                    ),
                  ).pop(),
                  const SizedBox(height: 34),
                  Text('SALAMAT!', style: Typo.eyebrow).rise(3),
                  const SizedBox(height: 10),
                  IText('Payment successful!', style: Typo.h1(34)).rise(4),
                  const SizedBox(height: 10),
                  IText(
                    'Your consultation fee has been received.',
                    textAlign: TextAlign.center,
                    style: Typo.mutedBody(),
                  ).rise(5),
                  const SizedBox(height: 22),
                  Glass(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                    child: Column(
                      children: [
                        SummaryLine('Unit', u?.code ?? '', mono: true),
                        SummaryLine('Amount paid', u?.consultationFee ?? ''),
                        SummaryLine('Payment method', method),
                        const SummaryLine('Status', 'Paid', valueColor: Palette.acceptedText),
                        SummaryLine('Reference no.', u?.referenceNo ?? '', divider: false, mono: true),
                      ],
                    ),
                  ).rise(6),
                  const SizedBox(height: 22),
                  Column(
                    children: [
                      PrimaryButton(
                        'Complete form',
                        icon: TIcon.document,
                        iconSize: 18,
                        onTap: () => state.showSheet(SheetKind.gettingStarted),
                      ),
                      const SizedBox(height: 10),
                      GhostButton(
                        'Fill out later',
                        onTap: () {
                          state.showToast('We’ve sent your access link by email and SMS', icon: TIcon.mail);
                          context.go(Screen.home);
                        },
                      ),
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
}

// MARK: Getting started sheet

/// Getting started: the 3 rules of the customer form and the 7-day deadline, before the buyer begins editing.
class GettingStartedSheet extends StatelessWidget {
  const GettingStartedSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  Widget _step(int n, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Palette.yellow),
          child: Text('$n', style: Typo.manrope(13, Typo.extrabold, Palette.ink)),
        ).pop(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
              const SizedBox(height: 3),
              IText(body, style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT RECEIVED', style: Typo.eyebrow),
        const SizedBox(height: 8),
        IText('Getting started', style: Typo.h1(28)),
        const SizedBox(height: 18),
        _step(1, 'Complete the data form', 'Submit all required documents and fill in all necessary information.'),
        _step(
          2,
          'Fill required fields',
          'If you don’t have everything yet, at least fill in every field marked with an asterisk (*).',
        ),
        _step(
          3,
          '7-day completion window',
          'Once the required information is in, you can log out. You’ll have 7 days to provide the remaining information and documents.',
        ),
        Glass(
          radius: 16,
          fill: Palette.orange.o(0.12),
          border: Palette.orange.o(0.4),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TIconView(TIcon.calendar, size: 18, color: Palette.todoText),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Typo.manrope(13, Typo.semibold, Palette.todoText).copyWith(height: 1.5),
                    children: [
                      const TextSpan(text: 'Deadline: compliance submission is on or before '),
                      TextSpan(
                        text: deadlineLabel(DateTime.now()),
                        style: Typo.manrope(13, Typo.extrabold, Palette.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          'Continue form',
          icon: TIcon.edit,
          iconSize: 18,
          onTap: () => context.go(const Screen.applicationEdit()),
        ),
        const SizedBox(height: 10),
        GhostButton(
          'Fill out later',
          onTap: () {
            context.read<AppState>().showToast('We’ve sent your access link by email and SMS', icon: TIcon.mail);
            context.go(Screen.home);
          },
        ),
      ],
    );
  }
}
