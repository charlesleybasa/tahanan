import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/adaptive.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/itext.dart';
import '../../widgets/surfaces.dart';
import '../spouse/spouse_flow.dart' show BirthdateField;
import 'application_form.dart';

/// Edit application: the whole Customer Information Form, one step at a time, with a step rail, live "required left"
/// counter and a Save & continue bar. Missing required fields never block saving (the buyer has 7 days to finish).
class ApplicationEditScreen extends StatefulWidget {
  const ApplicationEditScreen({super.key, this.startStep = 0});

  final int startStep;

  @override
  State<ApplicationEditScreen> createState() => _ApplicationEditScreenState();
}

class _ApplicationEditScreenState extends State<ApplicationEditScreen> {
  late int _step = widget.startStep.clamp(0, formSteps.length - 1);
  int _cob = 0;
  bool _attempted = false;
  String? _openSelect;
  final _chips = ScrollController();

  @override
  void dispose() {
    _chips.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    HapticFeedback.selectionClick();
    setState(() {
      _step = step;
      _attempted = false;
      _openSelect = null;
    });
    if (_chips.hasClients) {
      _chips.animateTo(
        (step * 112.0).clamp(0, _chips.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Motion.easeInOut,
      );
    }
  }

  void _save() {
    final state = context.read<AppState>();
    final step = formSteps[_step];
    final left = state.form.missing(step);
    HapticFeedback.mediumImpact();
    if (left > 0 && !_attempted) {
      // First tap: point at what is missing but still let the buyer continue on the next tap.
      setState(() => _attempted = true);
      state.showToast(
        '$left required ${left == 1 ? 'field' : 'fields'} left · tap again to continue',
        icon: TIcon.info,
        tint: Palette.orange,
      );
      return;
    }
    // TODO: API — persist the answers (PATCH /me/application) once the endpoint exists.
    if (_step == formSteps.length - 1) {
      state.update(() => state.applicationTab = ApplicationTab.requirements);
      state.showToast('Saved · now your documents');
      context.go(Screen.application);
    } else {
      state.showToast('${step.title} saved');
      _goTo(_step + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final form = state.form;
    final step = formSteps[_step];
    final insets = MediaQuery.paddingOf(context);
    final left = form.missing(step);
    final last = _step == formSteps.length - 1;
    return Stack(
      children: [
        MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(Spacing.gutter, insets.top + Spacing.belowStatusBar, Spacing.gutter, 0),
                child: Row(
                  children: [
                    BackCircleButton(label: 'Back to my application', onTap: () => context.go(Screen.application)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit application', style: Typo.outfit(20, Typo.semibold, Palette.text)),
                          Text(
                            'Customer information form · Step ${_step + 1} of 5',
                            style: Typo.manrope(12, Typo.bold, Palette.subtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(
                  controller: _chips,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
                  children: [
                    for (final (i, s) in formSteps.indexed) ...[
                      _StepChip(
                        n: i + 1,
                        label: s.title,
                        state: i == _step ? _Chip.active : (form.missing(s) == 0 ? _Chip.done : _Chip.idle),
                        onTap: () => _goTo(i),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _StepChip(
                      n: 5,
                      label:
                          'Docs ${state.requirements.where((r) => r.status != RequirementStatus.todo).length}/${state.requirements.length}',
                      state: _Chip.idle,
                      onTap: () {
                        state.update(() => state.applicationTab = ApplicationTab.requirements);
                        context.go(Screen.application);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.gutter, 14, Spacing.gutter, 0),
                child: _Progress(value: form.overallPercent / 100, left: left),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey('$_step-$_cob'),
                  child: FadeIn(
                    duration: 0.3,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(Spacing.gutter, 8, Spacing.gutter, insets.bottom + 140),
                      child: _stepBody(state, step),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomCTABar(
            child: Row(
              children: [
                if (_step > 0) ...[
                  SizedBox(width: 104, child: GhostButton('Back', height: 56, onTap: () => _goTo(_step - 1))),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: PrimaryButton(
                    last ? 'Save & go to documents' : 'Save & continue',
                    icon: last ? TIcon.document : TIcon.arrowRight,
                    iconSize: 18,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepBody(AppState state, FormStep step) {
    final form = state.form;
    final children = <Widget>[];
    final groups = step.id == 'coborrower' ? [step.groups[_cob]] : step.groups;
    if (step.id == 'coborrower') {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: SegmentedPill(
            options: ['Co-borrower 1', form.secondCoBorrower ? 'Co-borrower 2' : '+ Co-borrower 2'],
            selection: _cob,
            onChanged: (i) {
              if (i == 1) form.setSecondCoBorrower(true);
              setState(() {
                _cob = i;
                _openSelect = null;
              });
            },
          ),
        ),
      );
    }
    for (final g in groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 12),
          child: Text(g.title.toUpperCase(), style: Typo.eyebrow.copyWith(fontSize: 11)),
        ),
      );
      if (g.sameAsKey != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Glass(
              radius: 18,
              fill: form.samePermanent ? Palette.blue.o(0.14) : null,
              border: form.samePermanent ? Palette.blue.o(0.45) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: CheckboxRow(
                value: form.samePermanent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  form.setSamePermanent(v);
                },
                child: Text('Same as present address', style: Typo.manrope(14, Typo.bold, Palette.text)),
              ),
            ),
          ),
        );
        if (form.samePermanent) {
          children.add(
            IText('Your permanent address will mirror the present address above.', style: Typo.mutedBody(13)),
          );
          continue;
        }
      }
      for (final f in g.fields) {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: _field(form, f)));
      }
    }
    if (step.id == 'coborrower' && _cob == 1) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GhostButton(
            'Remove co-borrower 2',
            tint: Palette.todoText,
            onTap: () {
              for (final f in step.groups[1].fields) {
                form.values.remove(f.id);
              }
              form.setSecondCoBorrower(false);
              setState(() => _cob = 0);
            },
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _field(ApplicationForm form, FieldSpec f) {
    final value = form.get(f.id);
    final error = _attempted && f.required && value.trim().isEmpty;
    final border = error ? Palette.orange : null;
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.kind) {
      case FieldKind.select:
        return _SelectField(
          label: label,
          value: value,
          placeholder: f.hint,
          options: f.options,
          error: error,
          open: _openSelect == f.id,
          onToggle: () => setState(() => _openSelect = _openSelect == f.id ? null : f.id),
          onPick: (v) {
            HapticFeedback.selectionClick();
            form.set(f.id, v);
            setState(() => _openSelect = null);
          },
        );
      case FieldKind.date:
        final d = DateTime.tryParse(value);
        return BirthdateField(
          label: label,
          date: d,
          border: border,
          onChanged: (v) => form.set(
            f.id,
            '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}',
          ),
        );
      default:
        return TahananTextField(
          label: label,
          placeholder: f.hint,
          value: value,
          border: border,
          mono: f.kind == FieldKind.mono,
          keyboard: switch (f.kind) {
            FieldKind.email => TextInputType.emailAddress,
            FieldKind.phone => TextInputType.phone,
            FieldKind.number => TextInputType.number,
            _ => TextInputType.text,
          },
          capitalization: f.kind == FieldKind.text ? TextCapitalization.words : TextCapitalization.none,
          inputFormatters: f.kind == FieldKind.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: (v) => form.values[f.id] = v,
        );
    }
  }
}

enum _Chip { idle, active, done }

class _StepChip extends StatelessWidget {
  const _StepChip({required this.n, required this.label, required this.state, required this.onTap});

  final int n;
  final String label;
  final _Chip state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = state == _Chip.active;
    final done = state == _Chip.done;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Step $n, $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Motion.easeInOut,
        height: 40,
        padding: const EdgeInsets.only(left: 6, right: 14),
        decoration: ShapeDecoration(
          color: active ? Palette.yellow : Palette.white(0.06),
          shape: StadiumBorder(side: hairline(active ? Palette.yellow : Palette.white(0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Palette.ink : (done ? Palette.green : Palette.white(0.1)),
              ),
              child: done && !active
                  ? const TIconView(TIcon.check, size: 14, color: Color(0xFFFFFFFF))
                  : Text('$n', style: Typo.manrope(12, Typo.extrabold, active ? Palette.yellow : Palette.muted)),
            ),
            const SizedBox(width: 8),
            Text(label, style: Typo.manrope(13, Typo.extrabold, active ? Palette.ink : Palette.soft)),
          ],
        ),
      ),
    );
  }
}

/// Overall completion bar with the live "N required left on this step" note.
class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.left});

  final double value;
  final int left;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${(value * 100).round()}% of the form complete',
                style: Typo.manrope(12, Typo.bold, Palette.muted),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                left == 0 ? 'Step complete' : '$left required left',
                key: ValueKey(left),
                style: Typo.manrope(12, Typo.extrabold, left == 0 ? Palette.acceptedText : Palette.todoText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                ColoredBox(color: Palette.white(0.1), child: const SizedBox.expand()),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: const Duration(milliseconds: 500),
                  curve: Motion.upbar,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Palette.yellow, child: SizedBox.expand()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A drop-down that opens its options inline (no overlay), animating the list in under the field.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.error,
    required this.open,
    required this.onToggle,
    required this.onPick,
  });

  final String label, value, placeholder;
  final List<String> options;
  final bool error, open;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        Tap(
          onTap: onToggle,
          semanticLabel: '$label, ${value.isEmpty ? 'not selected' : value}',
          child: FieldChrome(
            focused: open,
            border: error ? Palette.orange : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? placeholder : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.manrope(16, Typo.regular, value.isEmpty ? Palette.placeholder : Palette.text),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Motion.easeInOut,
                    child: const TIconView(TIcon.chevronDown, size: 18, color: Palette.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Motion.easeInOut,
          alignment: Alignment.topCenter,
          child: !open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FadeIn(
                    duration: 0.25,
                    child: Glass(
                      radius: 16,
                      fill: Palette.panel,
                      child: Column(
                        children: [
                          for (final (i, o) in options.indexed) ...[
                            if (i > 0) const RowDivider(opacity: 0.06),
                            Tap(
                              onTap: () => onPick(o),
                              semanticLabel: o,
                              selected: o == value,
                              child: SizedBox(
                                height: 48,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          o,
                                          style: Typo.manrope(
                                            15,
                                            o == value ? Typo.extrabold : Typo.medium,
                                            Palette.text,
                                          ),
                                        ),
                                      ),
                                      if (o == value) const TIconView(TIcon.check, size: 18, color: Palette.yellow),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
