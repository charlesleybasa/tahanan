import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/itext.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../sheets/sheets.dart' show StepSwitch;
import 'booking_widgets.dart';

/// What the buyer attached in step 1 of the booking flow. Held in [AppState] so Back from Payment returns to
/// "Documents ready" instead of starting over.
class IdCaptureData {
  /// 0 select ID type · 1 upload ID · 2 selfie · 3 documents ready.
  int step = 0;
  String idType = '';
  String? idName, selfieName;
  Uint8List? idBytes, selfieBytes;

  bool get hasId => idName != null;
  bool get hasSelfie => selfieName != null;
}

const _idTypes = ['Driving License', 'Postal ID Card', 'UMID', 'PhilSys', 'e-PhilSys', 'Tax ID (TIN)'];
const _maxBytes = 5 * 1024 * 1024;

/// Booking step 1: choose an ID → capture or upload it → take a selfie → review. Every step fades in, the stepper and
/// header stay put, and the buyer can always go back one step.
class IdCaptureScreen extends StatefulWidget {
  const IdCaptureScreen({super.key});

  @override
  State<IdCaptureScreen> createState() => _IdCaptureScreenState();
}

class _IdCaptureScreenState extends State<IdCaptureScreen> {
  IdCaptureData get _d => context.read<AppState>().idCapture;

  void _go(int step) {
    HapticFeedback.selectionClick();
    final state = context.read<AppState>();
    state.update(() => state.idCapture.step = step);
  }

  void _back() {
    final step = _d.step;
    if (step == 0) {
      context.go(const Screen(ScreenKind.booking));
    } else {
      _go(step - 1);
    }
  }

  Future<void> _pickId({required bool camera}) async {
    final state = context.read<AppState>();
    String? name;
    Uint8List? bytes;
    try {
      if (camera) {
        final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
        if (img == null) return;
        name = 'ID_${1000 + math.Random().nextInt(9000)}.jpg';
        bytes = await img.readAsBytes();
      } else {
        final f = (await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png'],
        )).firstOrNull;
        if (f == null) return;
        name = f.name;
        bytes = await f.readAsBytes();
      }
    } catch (_) {
      // No camera / picker (simulator): continue the demo with a placeholder file.
      name = 'ID_demo.jpg';
    }
    if (!mounted) return;
    if (bytes != null && bytes.length > _maxBytes) {
      state.showToast('That file is over 5 MB', icon: TIcon.info, tint: Palette.orange);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    state.update(() {
      state.idCapture
        ..idName = name
        ..idBytes = bytes
        ..step = 2;
    });
  }

  Future<void> _pickSelfie({required bool camera}) async {
    final state = context.read<AppState>();
    String? name;
    Uint8List? bytes;
    try {
      final img = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (img == null) return;
      name = 'Selfie_${1000 + math.Random().nextInt(9000)}.jpg';
      bytes = await img.readAsBytes();
    } catch (_) {
      name = 'Selfie_demo.jpg';
    }
    if (!mounted) return;
    if (bytes != null && bytes.length > _maxBytes) {
      state.showToast('That photo is over 5 MB', icon: TIcon.info, tint: Palette.orange);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    state.update(() {
      state.idCapture
        ..selfieName = name
        ..selfieBytes = bytes
        ..step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.idCapture;
    const titles = ['Select ID', 'Upload ID', 'Take a selfie', 'Documents ready'];
    return Stack(
      children: [
        ScreenScroll(
          bottom: 130,
          children: [
            Row(
              children: [
                BackCircleButton(onTap: _back),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attach ID & Selfie', style: Typo.outfit(19, Typo.semibold, Palette.text)),
                      Text('Step 1 of 3 · ${titles[d.step]}', style: Typo.manrope(12, Typo.bold, Palette.subtle)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.fromLTRB(8, 22, 8, 0), child: BookingStepper(active: 0)),
            StepSwitch(
              step: d.step,
              child: switch (d.step) {
                0 => _select(d),
                1 => _upload(d),
                2 => _selfie(d),
                _ => _ready(d),
              },
            ),
          ],
        ),
        if (d.step == 3)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomCTABar(
              child: PrimaryButton(
                'Continue to payment',
                onTap: () {
                  context.read<AppState>().payStage = 'choose';
                  context.go(const Screen(ScreenKind.payment));
                },
              ),
            ),
          ),
      ],
    );
  }

  // Step 0

  Widget _select(IdCaptureData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 26),
      IText('Select your government ID', style: Typo.h1(28)),
      const SizedBox(height: 8),
      IText('Choose the ID you’ll upload. You can take a photo or pick a file next.', style: Typo.mutedBody(14)),
      const SizedBox(height: 18),
      for (final (i, t) in _idTypes.indexed) ...[
        if (i > 0) const SizedBox(height: 10),
        Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            final state = context.read<AppState>();
            state.update(() {
              state.idCapture
                ..idType = t
                ..step = 1;
            });
          },
          semanticLabel: t,
          child: Glass(
            radius: 20,
            fill: d.idType == t ? Palette.yellow.o(0.08) : Palette.white(0.04),
            border: d.idType == t ? Palette.yellow : null,
            child: RowLayout(
              children: [
                IconTile(icon: TIcon.card, tint: Palette.yellow, background: Palette.yellow.o(0.14)),
                RowText(title: t),
                const Chevron(),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  // Step 1

  Widget _pickCard({
    required TIcon icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
    required bool primary,
    double height = 150,
  }) {
    final tint = primary ? Palette.yellow : Palette.submittedText;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: DashedBorder(
        radius: 24,
        color: tint.o(0.55),
        width: 1.5,
        fill: tint.o(0.08),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: primary ? Palette.yellow : tint.o(0.2)),
                child: TIconView(icon, size: 26, color: primary ? Palette.ink : tint),
              ),
              const SizedBox(height: 10),
              Text(title, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
              const SizedBox(height: 2),
              Text(sub, style: Typo.manrope(12, Typo.regular, Palette.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upload(IdCaptureData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      LinkButton('Change ID type', icon: TIcon.arrowLeft, size: 13, weight: Typo.extrabold, onTap: () => _go(0)),
      IText('Upload your ${d.idType.isEmpty ? 'ID' : d.idType}', style: Typo.h1(28)),
      const SizedBox(height: 8),
      IText('Choose how to provide your ID.', style: Typo.mutedBody(14)),
      const SizedBox(height: 18),
      _pickCard(
        icon: TIcon.camera,
        title: 'Capture',
        sub: 'Use your camera',
        primary: true,
        height: 168,
        onTap: () => _pickId(camera: true),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(height: 1, child: ColoredBox(color: Palette.white(0.12))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: Typo.overline()),
            ),
            Expanded(
              child: SizedBox(height: 1, child: ColoredBox(color: Palette.white(0.12))),
            ),
          ],
        ),
      ),
      _pickCard(
        icon: TIcon.upload,
        title: 'Upload file',
        sub: 'Pick from your gallery or files',
        primary: false,
        height: 128,
        onTap: () => _pickId(camera: false),
      ),
      const SizedBox(height: 14),
      Center(child: Text('PNG or JPG · maximum 5 MB', style: Typo.manrope(12, Typo.semibold, Palette.subtle))),
      const SizedBox(height: 14),
      Glass(
        radius: 16,
        fill: Palette.blue.o(0.14),
        border: Palette.blue.o(0.3),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const TIconView(TIcon.info, size: 18, color: Palette.submittedText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Use good light, keep all four corners in view and avoid glare.',
                style: Typo.manrope(12, Typo.semibold, Palette.submittedText).copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // Step 2

  Widget _thumb(Uint8List? bytes, TIcon icon, {bool round = false}) => Container(
    width: round ? 64 : 84,
    height: round ? 64 : 62,
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Palette.navyLight,
      borderRadius: round ? null : BorderRadius.circular(12),
      shape: round ? BoxShape.circle : BoxShape.rectangle,
    ),
    child: bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
        : TIconView(icon, size: 26, color: Palette.submittedText),
  );

  Widget _docCard({
    required Widget thumb,
    required String title,
    required String file,
    required String action,
    required VoidCallback onAction,
    Color actionColor = Palette.submittedText,
    bool check = false,
  }) => Glass(
    radius: 22,
    border: Palette.green.o(0.45),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        thumb,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
              const SizedBox(height: 2),
              Text(
                file,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Typo.manrope(12, Typo.regular, Palette.subtle),
              ),
              LinkButton(action, size: 12, weight: Typo.extrabold, onTap: onAction),
            ],
          ),
        ),
        if (check) const CheckDisc(size: 26, iconSize: 14, color: Palette.green).pop(),
      ],
    ),
  );

  Widget _selfie(IdCaptureData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 26),
      Row(
        children: [
          const CheckDisc(size: 44, iconSize: 20, color: Palette.green).pop(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.idType.isEmpty ? 'ID' : d.idType} uploaded', style: Typo.sectionTitle(21)),
                const SizedBox(height: 2),
                Text('Now let’s take a selfie for verification.', style: Typo.manrope(13, Typo.regular, Palette.muted)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _docCard(
        thumb: _thumb(d.idBytes, TIcon.card),
        title: d.idType.isEmpty ? 'Government ID' : d.idType,
        file: d.idName ?? '',
        action: 'Remove & choose different ID',
        actionColor: Palette.todoText,
        onAction: () {
          final state = context.read<AppState>();
          state.update(() {
            state.idCapture
              ..idName = null
              ..idBytes = null
              ..step = 0;
          });
        },
      ),
      const SizedBox(height: 24),
      Text('Take a selfie', style: Typo.sectionTitle(18)),
      const SizedBox(height: 12),
      _pickCard(
        icon: TIcon.person,
        title: 'Capture',
        sub: 'Use your front camera',
        primary: true,
        height: 168,
        onTap: () => _pickSelfie(camera: true),
      ),
      const SizedBox(height: 12),
      GhostButton('Upload a photo instead', icon: TIcon.upload, height: 50, onTap: () => _pickSelfie(camera: false)),
      const SizedBox(height: 14),
      Center(child: Text('PNG or JPG · maximum 5 MB', style: Typo.manrope(12, Typo.semibold, Palette.subtle))),
    ],
  );

  // Step 3

  Widget _ready(IdCaptureData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 26),
      Row(
        children: [
          const CheckDisc(size: 44, iconSize: 20, color: Palette.green).pop(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IText('Documents ready', style: Typo.h1(26)),
                const SizedBox(height: 2),
                Text('Review them before you continue.', style: Typo.manrope(13, Typo.regular, Palette.muted)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _docCard(
        thumb: _thumb(d.idBytes, TIcon.card),
        title: d.idType.isEmpty ? 'Government ID' : d.idType,
        file: d.idName ?? '—',
        action: 'Replace',
        check: true,
        onAction: () => _go(1),
      ),
      const SizedBox(height: 12),
      _docCard(
        thumb: _thumb(d.selfieBytes, TIcon.person, round: true),
        title: 'Selfie photo',
        file: d.selfieName ?? '—',
        action: 'Retake',
        check: true,
        onAction: () => _go(2),
      ),
      const SizedBox(height: 16),
      Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const TIconView(TIcon.shield, size: 18, color: Palette.acceptedText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your ID and selfie are used only to verify this booking and fill in your form.',
                style: Typo.manrope(12, Typo.regular, Palette.muted).copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
