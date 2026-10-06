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

/// My application — maps 1:1 to native `ApplicationView.swift`.
class ApplicationScreen extends StatefulWidget {
  const ApplicationScreen({super.key});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  String? _open = 'personal';

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
        if (state.applicationTab == ApplicationTab.info) ..._info(state) else const RequirementsTab(),
      ],
    );
  }

  List<Widget> _info(AppState state) => [
    Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.navyLight, Palette.navy],
          ),
          shape: squircle(26, side: hairline(Palette.white(0.1))),
        ),
        child: Row(
          children: [
            ProgressRing(
              fraction: 245 / 360,
              color: Palette.yellow,
              track: Palette.white(0.12),
              size: 70,
              inner: 56,
              innerFill: Palette.navy,
              child: Text('68%', style: Typo.outfit(17, Typo.bold, Palette.text)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Almost pre-qualified', style: Typo.outfit(18, Typo.semibold, Palette.text)),
                  const SizedBox(height: 4),
                  IText(
                    'Finish spouse details so Homeful can review your loan faster.',
                    style: Typo.manrope(13, Typo.regular, Palette.muted).copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).rise(3),
    Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          for (final (i, s) in state.sections.indexed) ...[if (i > 0) const SizedBox(height: 10), _section(s)],
        ],
      ),
    ).rise(4),
  ];

  Color _ringColor(int pct) => pct == 100 ? Palette.green : (pct > 0 ? Palette.yellow : Palette.ringIdle);

  Widget _section(ApplicationSection s) {
    final open = _open == s.id;
    final c = _ringColor(s.percent);
    return GlassCard(
      children: [
        Tap(
          onTap: () => setState(() => _open = open ? null : s.id),
          semanticLabel: '${s.title}, ${open ? 'expanded' : 'collapsed'}',
          child: RowLayout(
            children: [
              ProgressRing(
                fraction: s.percent / 100,
                color: c,
                size: 44,
                inner: 34,
                child: s.percent == 100
                    ? TIconView(TIcon.check, size: 18, color: c)
                    : Text('${s.percent}%', style: Typo.manrope(10, Typo.extrabold, c)),
              ),
              RowText(title: s.title, subtitle: s.subtitle, subtitleSize: 12, subtitleColor: Palette.subtle),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Motion.easeInOut,
                child: const TIconView(TIcon.chevronDown, color: Palette.muted),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Motion.easeInOut,
          alignment: Alignment.topCenter,
          child: !open
              ? const SizedBox(width: double.infinity)
              : FadeIn(
                  duration: 0.3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        if (s.fields.isNotEmpty)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Palette.white(0.08))),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                children: [
                                  for (final f in s.fields)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(f.key, style: Typo.manrope(14, Typo.regular, Palette.subtle)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              f.value,
                                              textAlign: TextAlign.right,
                                              style: Typo.manrope(14, Typo.bold, Palette.text),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (s.id == 'spouse')
                          PrimaryButton(
                            s.cta,
                            height: 52,
                            chipSize: 40,
                            onTap: () => context.go(const Screen(ScreenKind.spouse)),
                          )
                        else
                          // TODO: API — personal details, co-borrower and AIF forms are not in the design yet.
                          GhostButton(s.cta, height: 48, onTap: () {}),
                      ],
                    ),
                  ),
                ),
        ),
      ],
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
                Wrap(
                  spacing: 14,
                  children: [
                    LegendDot(color: Palette.green, label: 'Accepted', style: legend),
                    LegendDot(color: Palette.yellow, label: 'Reviewed', style: legend),
                    LegendDot(color: Palette.blue, label: 'Submitted', style: legend),
                    LegendDot(color: Palette.orange, label: 'To upload', style: legend),
                  ],
                ),
              ],
            ),
          ),
        ).rise(3),
        for (final owner in const ['Principal buyer', 'Spouse'])
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
              Text(r.name, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
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
