import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/itext.dart';
import 'application_form.dart';

/// My application: the Customer Information Form as four collapsible review cards (the first one that still needs
/// answers opens by itself), an Edit application button, and the document requirements tab.
class ApplicationScreen extends StatelessWidget {
  const ApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final unit = state.profile?.unit;
    return ScreenScroll(
      bottom: Spacing.tabBarClearance,
      children: [
        Text('Aking aplikasyon'.toUpperCase(), style: Typo.eyebrow).rise(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IText('My application', style: Typo.h1(36)),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${unit?.brandName ?? ''} · ', style: Typo.manrope(13, Typo.regular, Palette.muted)),
                TextSpan(text: unit?.code ?? '', style: Typo.mono(13, Typo.medium, Palette.muted)),
              ],
            ),
          ),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SegmentedPill(
            options: const ['Personal info', 'Requirements'],
            selection: state.applicationTab.index,
            onChanged: (i) => state.update(() => state.applicationTab = ApplicationTab.values[i]),
            badge: (i) => i == 1 && state.todoCount > 0 ? state.todoCount : null,
          ),
        ).rise(2),
        if (state.applicationTab == ApplicationTab.info) const _InfoTab() else const RequirementsTab(),
      ],
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final form = state.form;
    final first = form.firstIncomplete;
    final open = state.openSteps ?? {if (first >= 0) formSteps[first].id};
    final allOpen = open.length == formSteps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: PrimaryButton(
            'Edit application',
            icon: TIcon.edit,
            iconSize: 18,
            onTap: () => context.go(Screen.applicationEdit(first < 0 ? 0 : first)),
          ),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  first < 0 ? 'All sections complete' : '${form.overallPercent}% complete',
                  style: Typo.manrope(13, Typo.bold, Palette.muted),
                ),
              ),
              LinkButton(
                allOpen ? 'Collapse all' : 'Expand all',
                size: 13,
                weight: Typo.extrabold,
                onTap: () =>
                    state.update(() => state.openSteps = allOpen ? <String>{} : {for (final s in formSteps) s.id}),
              ),
            ],
          ),
        ).rise(3),
        for (final (i, step) in formSteps.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          _StepCard(
            index: i,
            step: step,
            open: open.contains(step.id),
            startHere: i == first,
            onToggle: () => state.update(() {
              final next = {...open};
              next.contains(step.id) ? next.remove(step.id) : next.add(step.id);
              state.openSteps = next;
            }),
          ),
        ],
        const SizedBox(height: 10),
        GlassCard(
          children: [
            Tap(
              onTap: () => state.update(() => state.applicationTab = ApplicationTab.requirements),
              semanticLabel: 'Document requirements',
              child: RowLayout(
                children: [
                  IconTile(icon: TIcon.document, tint: Palette.todoText, background: Palette.orange.o(0.16)),
                  RowText(
                    title: '5 · Document requirements',
                    subtitle:
                        '${state.requirements.where((r) => r.status != RequirementStatus.todo).length} of '
                        '${state.requirements.length} uploaded · ${state.todoCount} to upload',
                    subtitleSize: 12,
                    subtitleColor: Palette.subtle,
                  ),
                  const Chevron(),
                ],
              ),
            ),
          ],
        ).rise(4),
      ],
    );
  }
}

/// One collapsible review card for a form step.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.step,
    required this.open,
    required this.startHere,
    required this.onToggle,
  });

  final int index;
  final FormStep step;
  final bool open, startHere;
  final VoidCallback onToggle;

  Color _ring(int pct) => pct == 100 ? Palette.green : (pct > 0 ? Palette.yellow : Palette.ringIdle);

  @override
  Widget build(BuildContext context) {
    final form = context.watch<AppState>().form;
    final pct = form.percent(step);
    final left = form.missing(step);
    final c = _ring(pct);
    return GlassCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Tap(
                  onTap: onToggle,
                  semanticLabel: '${step.title}, ${open ? 'expanded' : 'collapsed'}',
                  child: Row(
                    children: [
                      ProgressRing(
                        fraction: pct / 100,
                        color: c,
                        size: 44,
                        inner: 34,
                        child: pct == 100
                            ? TIconView(TIcon.check, size: 18, color: c)
                            : Text('$pct%', style: Typo.manrope(10, Typo.extrabold, c)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1} · ${step.title}', style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (startHere) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                                    child: Text('START HERE', style: Typo.manrope(9, Typo.extrabold, Palette.ink)),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    left == 0 ? 'Complete' : '$left to complete',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Typo.manrope(
                                      12,
                                      Typo.bold,
                                      left == 0 ? Palette.acceptedText : Palette.todoText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Motion.easeInOut,
                        child: const TIconView(TIcon.chevronDown, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => context.go(Screen.applicationEdit(index)),
                semanticLabel: 'Edit ${step.title}',
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(shape: StadiumBorder(side: hairline(Palette.white(0.16)))),
                  child: Text('Edit', style: Typo.manrope(13, Typo.extrabold, Palette.text)),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Motion.easeInOut,
          alignment: Alignment.topCenter,
          child: !open ? const SizedBox(width: double.infinity) : FadeIn(duration: 0.3, child: _body(context, form)),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, ApplicationForm form) {
    final rows = <Widget>[];
    for (final g in step.groups) {
      if (step.id == 'coborrower' && g.title == 'Co-borrower 2' && !form.secondCoBorrower) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Tap(
              onTap: () {
                form.setSecondCoBorrower(true);
                context.go(Screen.applicationEdit(index));
              },
              semanticLabel: 'Add co-borrower 2',
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Palette.submittedText.o(0.5), width: 1.5),
                      ),
                      child: const TIconView(TIcon.plus, size: 16, color: Palette.submittedText),
                    ),
                    const SizedBox(width: 12),
                    Text('Add co-borrower 2', style: Typo.manrope(14, Typo.extrabold, Palette.submittedText)),
                  ],
                ),
              ),
            ),
          ),
        );
        continue;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(g.title.toUpperCase(), style: Typo.overline()),
        ),
      );
      for (final f in g.fields) {
        final v = form.display(f);
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(flex: 5, child: Text(f.label, style: Typo.manrope(14, Typo.regular, Palette.subtle))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: v.isEmpty && f.required
                      ? Tap(
                          onTap: () => context.go(Screen.applicationEdit(index)),
                          semanticLabel: 'Add ${f.label}',
                          child: Text(
                            'Add',
                            textAlign: TextAlign.right,
                            style: Typo.manrope(13, Typo.extrabold, Palette.todoText),
                          ),
                        )
                      : Text(
                          v.isEmpty ? '—' : v,
                          textAlign: TextAlign.right,
                          style: (f.kind == FieldKind.mono
                              ? Typo.mono(14, Typo.semibold, Palette.text)
                              : Typo.manrope(14, Typo.bold, Palette.text)),
                        ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Palette.white(0.08))),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
      ),
    );
  }
}

/// Requirements tab: summary bar, items grouped by Principal buyer and Spouse with 3-step status dots.
class RequirementsTab extends StatelessWidget {
  const RequirementsTab({super.key});

  static Color color(RequirementStatus s) => switch (s) {
    RequirementStatus.accepted => Palette.green,
    RequirementStatus.reviewed => Palette.yellow,
    RequirementStatus.submitted => Palette.blue,
    RequirementStatus.todo => Palette.orange,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reqs = state.requirements;
    int count(RequirementStatus s) => reqs.where((r) => r.status == s).length;
    const order = [
      RequirementStatus.accepted,
      RequirementStatus.reviewed,
      RequirementStatus.submitted,
      RequirementStatus.todo,
    ];
    final bar = [for (final s in order) ...List.filled(count(s), s)];
    final legend = Typo.manrope(12, Typo.bold, Palette.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Glass(
            radius: 24,
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
                        '${count(RequirementStatus.accepted)} of ${reqs.length} accepted',
                        style: Typo.outfit(22, Typo.semibold, Palette.text),
                      ),
                    ),
                    Text(
                      '${count(RequirementStatus.todo)} to upload',
                      style: Typo.manrope(12, Typo.extrabold, Palette.todoText),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (final (i, s) in bar.indexed) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Motion.easeInOut,
                            decoration: ShapeDecoration(color: color(s), shape: const StadiumBorder()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Native HStack: one row, items squeezed (long labels break) rather than wrapping to a new row.
                Row(
                  children: [
                    for (final (k, (c, l)) in const [
                      (Palette.green, 'Accepted'),
                      (Palette.yellow, 'Reviewed'),
                      (Palette.blue, 'Submitted'),
                      (Palette.orange, 'To upload'),
                    ].indexed) ...[
                      if (k > 0) const SizedBox(width: 14),
                      Flexible(
                        child: LegendDot(color: c, label: l, style: legend),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ).rise(3),
        for (final owner in {for (final r in reqs) r.owner})
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 10),
                child: Text(owner, style: Typo.sectionTitle(16)),
              ),
              GlassCard(
                children: [
                  for (final r in reqs.where((r) => r.owner == owner)) ...[
                    _row(context, r),
                    SizedBox(
                      width: double.infinity,
                      height: 1,
                      child: ColoredBox(color: Palette.white(0.06)),
                    ),
                  ],
                ],
              ),
            ],
          ).rise(4),
      ],
    );
  }

  Widget _row(BuildContext context, Requirement r) {
    final n = r.status.step;
    final dim = Palette.white(0.14);
    Widget seg(bool on, Color c) => Container(
      width: 18,
      height: 4,
      decoration: ShapeDecoration(color: on ? c : dim, shape: const StadiumBorder()),
    );
    return RowLayout(
      children: [
        IconTile(icon: TIcon.document, tint: Palette.soft, background: Palette.white(0.07)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IText(
                r.name,
                style: Typo.manrope(14, Typo.extrabold, Palette.text).copyWith(height: Typo.lineGap(2, 14)),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: r.status.label,
                excludeSemantics: true,
                child: Row(
                  children: [
                    seg(n >= 1, Palette.blue),
                    const SizedBox(width: 4),
                    seg(n >= 2, Palette.yellow),
                    const SizedBox(width: 4),
                    seg(n >= 3, Palette.green),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        r.status == RequirementStatus.todo
                            ? 'Required'
                            : r.status.label + (r.date == null ? '' : ' · ${r.date}'),
                        style: Typo.manrope(11, Typo.bold, Palette.subtle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (r.status == RequirementStatus.todo)
          Pressable(
            onTap: () => context.read<AppState>().showSheet(SheetKind.upload, requirementId: r.id),
            semanticLabel: 'Upload ${r.name}',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TIconView(TIcon.upload, size: 16, color: Palette.ink),
                  const SizedBox(width: 6),
                  Text('Upload', style: Typo.manrope(13, Typo.extrabold, Palette.ink)),
                ],
              ),
            ),
          )
        else
          StatusPill(r.status.label, tone: r.status.tone),
      ],
    );
  }
}

extension RequirementTone on RequirementStatus {
  PillTone get tone => switch (this) {
    RequirementStatus.accepted => PillTone.accepted,
    RequirementStatus.reviewed => PillTone.reviewed,
    RequirementStatus.submitted => PillTone.submitted,
    RequirementStatus.todo => PillTone.todo,
  };
}
