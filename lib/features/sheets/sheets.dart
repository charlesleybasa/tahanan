import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/itext.dart';

/// Swaps sheet steps with the prototype's `.transition(.fadeIn)`: the old step leaves at once, the new one fades in.
class StepSwitch extends StatelessWidget {
  const StepSwitch({super.key, required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey(step),
    child: FadeIn(child: child),
  );
}

/// Sheet content for [kind].
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.kind});

  final SheetKind kind;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return switch (kind) {
      SheetKind.link => LinkAccountSheet(onClose: state.closeSheet),
      SheetKind.changeEmail => ChangeEmailSheet(onClose: state.closeSheet),
      SheetKind.changeMobile => ChangeMobileSheet(onClose: state.closeSheet),
      SheetKind.upload => UploadSheet(requirementId: state.uploadRequirementId ?? '', onClose: state.closeSheet),
    };
  }
}

// MARK: Upload requirement

/// Upload a requirement with the camera or Files: picker → progress → "Submitted for review".
class UploadSheet extends StatefulWidget {
  const UploadSheet({super.key, required this.requirementId, required this.onClose});

  final String requirementId;
  final VoidCallback onClose;

  @override
  State<UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<UploadSheet> {
  int _step = 0;
  String _filename = 'IMG_2048.jpg';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPLOAD REQUIREMENT', style: Typo.eyebrow),
        const SizedBox(height: 8),
        IText(state.requirement(widget.requirementId)?.name ?? '', style: Typo.h1(26)),
        StepSwitch(
          step: _step,
          child: switch (_step) {
            0 => _chooser(),
            1 => _uploading(),
            _ => _done(),
          },
        ),
      ],
    );
  }

  Widget _chooser() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      IText('Clear photo or PDF, all four corners visible. Max 10 MB.', style: Typo.mutedBody(14)),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(child: _option(TIcon.camera, 'Take a photo', _camera)),
          const SizedBox(width: 10),
          Expanded(child: _option(TIcon.document, 'Choose a file', _file)),
        ],
      ),
    ],
  );

  Widget _option(TIcon icon, String title, VoidCallback onTap) => Pressable(
    onTap: onTap,
    semanticLabel: title,
    child: Container(
      height: 110,
      decoration: BoxDecoration(
        color: Palette.white(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.white(0.14), strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TIconView(icon, size: 26, color: Palette.yellow),
          const SizedBox(height: 10),
          Text(title, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
        ],
      ),
    ),
  );

  Future<void> _camera() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img == null) return;
      unawaited(_start('IMG_${1000 + math.Random().nextInt(9000)}.jpg', await img.readAsBytes()));
    } catch (_) {
      // No camera (simulator): continue the demo with the prototype's file name, as on iOS.
      unawaited(_start(_filename, null));
    }
  }

  Future<void> _file() async {
    final f = (await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
    )).firstOrNull;
    if (f != null) unawaited(_start(f.name, await f.readAsBytes()));
  }

  Future<void> _start(String name, List<int>? bytes) async {
    final state = context.read<AppState>();
    setState(() {
      _filename = name;
      _step = 1;
    });
    await state.repos.requirements.upload(requirementId: widget.requirementId, bytes: bytes, filename: name);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    state.markSubmitted(widget.requirementId);
    setState(() => _step = 2);
  }

  Widget _uploading() => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Glass(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconTile(icon: TIcon.image, tint: Palette.yellow, background: Palette.yellow.o(0.16)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.manrope(14, Typo.extrabold, Palette.text),
                    ),
                    const SizedBox(height: 8),
                    const _ProgressBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IText('Uploading securely…', style: Typo.mutedBody(13)),
      ],
    ),
  );

  Widget _done() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const CheckDisc(size: 84, iconSize: 40, color: Palette.blue).pop(),
          const SizedBox(height: 16),
          Text('Submitted for review', style: Typo.manrope(16, Typo.extrabold, Palette.text)),
          const SizedBox(height: 6),
          IText(
            'We’ll notify you once it’s reviewed and accepted.',
            textAlign: TextAlign.center,
            style: Typo.mutedBody(14),
          ),
          const SizedBox(height: 20),
          PrimaryButton('Done', icon: null, onTap: widget.onClose),
        ],
      ),
    ),
  );
}

/// `.upbar`: fills 0 → 100% over 1.6 s cubic-bezier(.4,0,.2,1).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 6,
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(color: Palette.white(0.1), shape: const StadiumBorder()),
            child: const SizedBox.expand(),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: Motion.upbar,
            builder: (_, p, _) => Container(
              width: box.maxWidth * p,
              decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
            ),
          ),
        ],
      ),
    ),
  );
}

// MARK: Link account

/// Link an existing account: Homeful ID → SMS OTP → linked.
class LinkAccountSheet extends StatefulWidget {
  const LinkAccountSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<LinkAccountSheet> {
  int _step = 0;
  String _homefulId = '';
  String _code = '50261';

  void _next() => setState(() => _step++);

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return StepSwitch(
      step: _step,
      child: switch (_step) {
        0 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: TIcon.link,
              tint: Palette.submittedText,
              background: Palette.blue.o(0.25),
              size: 56,
              radius: 18,
              iconSize: 26,
            ),
            const SizedBox(height: 16),
            IText('Link your Homeful account', style: Typo.h1(26)),
            const SizedBox(height: 8),
            IText('Find past bookings using your Homeful ID or contract number.', style: Typo.mutedBody(14)),
            const SizedBox(height: 18),
            TahananTextField(
              label: 'Homeful ID or contract no.',
              placeholder: 'HF-0000-000000',
              value: _homefulId,
              onChanged: (v) => _homefulId = v,
              mono: true,
              capitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            PrimaryButton('Send code to my mobile', icon: TIcon.send, iconSize: 18, onTap: _next),
          ],
        ),
        1 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IText('Enter the SMS code', style: Typo.h1(26)),
            const SizedBox(height: 8),
            IText('Sent to ${state.profile?.mobileMasked ?? '+63 917 ••• 4821'}', style: Typo.mutedBody(14)),
            const SizedBox(height: 18),
            OtpField(initial: _code, onChanged: (v) => _code = v),
            const SizedBox(height: 18),
            PrimaryButton(
              'Link account',
              icon: TIcon.link,
              iconSize: 18,
              onTap: () {
                unawaited(state.repos.buyer.linkAccount(homefulId: _homefulId, otp: _code));
                _next();
              },
            ),
          ],
        ),
        _ => SheetSuccess(
          title: 'Account linked',
          message: 'We found 1 past transaction. It now shows on your home.',
          onDone: widget.onClose,
        ),
      },
    );
  }
}

// MARK: Change email / mobile

class ChangeEmailSheet extends StatefulWidget {
  const ChangeEmailSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  int _step = 0;
  String _email = '';

  void _next() => setState(() => _step++);

  @override
  Widget build(BuildContext context) => StepSwitch(
    step: _step,
    child: switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IText('Change email address', style: Typo.h1(26)),
          const SizedBox(height: 8),
          IText('We’ll keep your current email until the new one is verified.', style: Typo.mutedBody(14)),
          const SizedBox(height: 18),
          TahananTextField(
            label: 'New email address',
            placeholder: 'you@newmail.com',
            value: _email,
            onChanged: (v) => _email = v,
            keyboard: TextInputType.emailAddress,
            autofill: AutofillHints.email,
          ),
          const SizedBox(height: 16),
          // TODO: API — update the user's email; Supabase sends the code and link
          PrimaryButton('Send code to new email', icon: TIcon.send, iconSize: 18, onTap: _next),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IText('Verify your new email', style: Typo.h1(26)),
          const SizedBox(height: 8),
          IText('Enter the code, or tap the link in that inbox.', style: Typo.mutedBody(14)),
          const SizedBox(height: 18),
          const OtpField(initial: '9418'),
          const SizedBox(height: 18),
          PrimaryButton('Verify and update', icon: TIcon.check, iconSize: 18, onTap: _next),
        ],
      ),
      _ => SheetSuccess(
        title: 'Email updated',
        message: 'Receipts and reset links now go to your new email.',
        onDone: widget.onClose,
      ),
    },
  );
}

class ChangeMobileSheet extends StatefulWidget {
  const ChangeMobileSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ChangeMobileSheet> createState() => _ChangeMobileSheetState();
}

class _ChangeMobileSheetState extends State<ChangeMobileSheet> {
  int _step = 0;
  String _mobile = '';

  void _next() => setState(() => _step++);

  @override
  Widget build(BuildContext context) => StepSwitch(
    step: _step,
    child: switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IText('Change mobile number', style: Typo.h1(26)),
          const SizedBox(height: 8),
          IText('We’ll text a code to confirm it’s yours.', style: Typo.mutedBody(14)),
          const SizedBox(height: 18),
          PhoneField(label: 'New mobile number', value: _mobile, onChanged: (v) => setState(() => _mobile = v)),
          const SizedBox(height: 16),
          // TODO: API — send SMS OTP to the new number
          PrimaryButton('Send SMS code', icon: TIcon.send, iconSize: 18, onTap: _next),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IText('Enter the SMS code', style: Typo.h1(26)),
          const SizedBox(height: 18),
          const OtpField(initial: '773'),
          const SizedBox(height: 18),
          PrimaryButton('Confirm number', icon: TIcon.check, iconSize: 18, onTap: _next),
        ],
      ),
      _ => SheetSuccess(title: 'Mobile number updated', onDone: widget.onClose),
    },
  );
}
