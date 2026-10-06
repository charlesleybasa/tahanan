import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// `.field` chrome: radius 16, white 6% fill, 13% border; focus turns the border yellow with a 4 pt yellow ring.
class FieldChrome extends StatelessWidget {
  const FieldChrome({
    super.key,
    required this.focused,
    this.height = 56,
    this.border,
    this.radius = Radii.input,
    required this.child,
  });

  final bool focused;
  final double? height;
  final Color? border;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const d = Duration(milliseconds: 200);
    return AnimatedContainer(
      duration: d,
      curve: Motion.easeInOut,
      height: height,
      // box-shadow: 0 0 0 4px rgba(255,196,46,.12) — an outer ring only
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Palette.yellow.o(focused ? 0.12 : 0),
          width: 4,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: AnimatedContainer(
        duration: d,
        curve: Motion.easeInOut,
        decoration: BoxDecoration(
          color: focused ? Palette.yellow.o(0.05) : Palette.white(0.06),
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: focused ? Palette.yellow : (border ?? Palette.white(0.13)),
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Label above a field (`.lbl`), with an optional muted suffix such as "(optional)".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.suffix});

  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(text, style: Typo.fieldLabel),
      if (suffix != null) ...[
        const SizedBox(width: 4),
        Text(suffix!, style: Typo.manrope(13, Typo.semibold, Palette.placeholder)),
      ],
    ],
  );
}

/// A labeled text input matching the prototype's `.lbl` + `.field` pair.
class TahananTextField extends StatefulWidget {
  const TahananTextField({
    super.key,
    this.label,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.keyboard = TextInputType.text,
    this.autofill,
    this.secure = false,
    this.mono = false,
    this.border,
    this.capitalization = TextCapitalization.sentences,
    this.labelSuffix,
    this.leadingIcon,
    this.enabled = true,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final String? label, labelSuffix;
  final String placeholder, value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboard;
  final String? autofill;
  final bool secure, mono, enabled;
  final Color? border;
  final TextCapitalization capitalization;
  final TIcon? leadingIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<TahananTextField> createState() => _TahananTextFieldState();
}

class _TahananTextFieldState extends State<TahananTextField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  bool _reveal = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(TahananTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.keyboard == TextInputType.emailAddress;
    final style = widget.mono ? Typo.mono(16, Typo.medium, Palette.text) : Typo.manrope(16, Typo.regular, Palette.text);
    final field = FieldChrome(
      focused: _focus.hasFocus,
      border: widget.border,
      child: Row(
        children: [
          if (widget.leadingIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TIconView(widget.leadingIcon!, color: Palette.subtle),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: widget.leadingIcon == null ? 16 : 12, right: widget.secure ? 0 : 16),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                obscureText: widget.secure && !_reveal,
                keyboardType: widget.keyboard,
                autofillHints: widget.autofill == null ? null : [widget.autofill!],
                textCapitalization: email ? TextCapitalization.none : widget.capitalization,
                autocorrect: !(email || widget.secure || widget.mono),
                enableSuggestions: !(email || widget.secure || widget.mono),
                inputFormatters: widget.inputFormatters,
                style: style,
                cursorColor: Palette.yellow,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: style.copyWith(color: Palette.placeholder),
                ),
              ),
            ),
          ),
          if (widget.secure)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tap(
                onTap: () => setState(() => _reveal = !_reveal),
                semanticLabel: _reveal ? 'Hide password' : 'Show password',
                child: const SizedBox.square(
                  dimension: 44,
                  child: Center(child: TIconView(TIcon.eye, color: Palette.muted)),
                ),
              ),
            ),
        ],
      ),
    );
    final tappable = GestureDetector(behavior: HitTestBehavior.translucent, onTap: _focus.requestFocus, child: field);
    if (widget.label == null) return tappable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label!, suffix: widget.labelSuffix),
        const SizedBox(height: 8),
        tappable,
      ],
    );
  }
}

/// "+63" prefix box + mobile input.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.placeholder = '917 123 4567',
    this.border,
  });

  final String? label;
  final String value, placeholder;
  final ValueChanged<String> onChanged;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Palette.white(0.06), borderRadius: BorderRadius.circular(16)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Palette.white(0.13), strokeAlign: BorderSide.strokeAlignInside),
          ),
          child: Text('+63', style: Typo.mono(15, Typo.semibold, Palette.text)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TahananTextField(
            placeholder: placeholder,
            value: value,
            onChanged: onChanged,
            keyboard: TextInputType.phone,
            autofill: AutofillHints.telephoneNumberNational,
            border: border,
          ),
        ),
      ],
    );
    if (label == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(label!), const SizedBox(height: 8), row],
    );
  }
}

/// A 22 pt checkbox in the browser's yellow accent color, with a 44 pt touch target.
class TCheckbox extends StatelessWidget {
  const TCheckbox({super.key, required this.value, required this.onChanged, this.size = 22});

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: Tap(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: size,
          height: size,
          child: OverflowBox(
            maxWidth: 44,
            maxHeight: 44,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value ? Palette.yellow : Palette.white(0.95),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: value ? Palette.yellow : Palette.checkboxIdleBorder,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: value ? TIconView(TIcon.check, size: size - 4, color: Palette.ink) : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox + wrapping text, like the prototype's `<label>` rows.
class CheckboxRow extends StatelessWidget {
  const CheckboxRow({super.key, required this.value, required this.onChanged, this.size = 22, required this.child});

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TCheckbox(value: value, onChanged: onChanged, size: size),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => onChanged(!value), child: child),
        ),
      ],
    );
  }
}

/// `.toggle`: 52 × 32 switch, green when on.
class TahananToggle extends StatelessWidget {
  const TahananToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    const d = Duration(milliseconds: 250);
    return Semantics(
      toggled: value,
      label: label,
      child: Tap(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: d,
              curve: Motion.easeInOut,
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? Palette.green : Palette.white(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: d,
                curve: Motion.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF000000).o(0.3), blurRadius: 3, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Six `.otp` boxes (46 × 58, radius 14, JetBrains Mono 24) with a blinking caret in the active box.
/// Typing goes to a hidden field; [initial] holds the digits shown in the prototype.
class OtpField extends StatefulWidget {
  const OtpField({super.key, this.initial = '', this.length = 6, this.boxWidth = 46, this.spacing = 8, this.onChanged});

  final String initial;
  final int length;
  final double boxWidth, spacing;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Semantics(
      label: 'Verification code, ${code.length} of ${widget.length} digits',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: (v) {
                    setState(() {});
                    widget.onChanged?.call(v);
                  },
                  decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[if (i > 0) SizedBox(width: widget.spacing), _box(i, code)],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i, String code) {
    final active = i == code.length.clamp(0, widget.length - 1) && code.length < widget.length;
    return Container(
      width: widget.boxWidth,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.white(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? Palette.yellow : Palette.white(0.13),
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Palette.yellow.o(active ? 0.14 : 0),
          width: 4,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: i < code.length
          ? Text(code[i], textScaler: TextScaler.noScaling, style: Typo.mono(24, Typo.semibold, Palette.text))
          : (active ? const BlinkingCaret() : null),
    );
  }
}
