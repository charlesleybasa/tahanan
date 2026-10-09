import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';
import 'unit_widgets.dart';

/// Opens [url] in the system app (Maps, YouTube, browser); a toast explains when nothing can open it.
Future<void> openExternal(BuildContext context, String url) async {
  final state = context.read<AppState>();
  unawaited(HapticFeedback.selectionClick());
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((Object _) => false);
  if (!ok) state.showToast('Couldn’t open that link', icon: TIcon.info, tint: Palette.orange);
}

/// "100 sold · 50 homes left" with a bar of the sold share.
class AvailabilityBar extends StatelessWidget {
  const AvailabilityBar({super.key, required this.sold, required this.remaining});

  final int sold, remaining;

  @override
  Widget build(BuildContext context) {
    final total = sold + remaining;
    final share = total == 0 ? 0.0 : sold / total;
    return Semantics(
      label: '$sold sold, $remaining homes left',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$sold', style: Typo.outfit(16, Typo.bold, Palette.text)),
              Text('  sold', style: Typo.manrope(12, Typo.bold, Palette.muted)),
              const Spacer(),
              Text('$remaining', style: Typo.outfit(16, Typo.bold, Palette.yellow)),
              Text('  homes left', style: Typo.manrope(12, Typo.bold, Palette.muted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  ColoredBox(color: Palette.yellow.o(0.18), child: const SizedBox.expand()),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: share),
                    duration: introDuration(context, 1000),
                    curve: Motion.upbar,
                    builder: (_, f, _) => FractionallySizedBox(
                      widthFactor: f,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Palette.blue, Palette.submittedText]),
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading used by the project page ("About the project", "How to get there").
class InfoHeading extends StatelessWidget {
  const InfoHeading(this.title, {super.key, this.meta});

  final String title;
  final String? meta;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 38, bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: Typo.sectionTitle(22))),
        if (meta != null) Text(meta!, style: Typo.manrope(13, Typo.regular, Palette.subtle)),
      ],
    ),
  );
}

/// Project description (3 lines, then "Read more") and highlight chips.
class AboutProject extends StatefulWidget {
  const AboutProject({super.key, required this.description, required this.highlights});

  final String? description;
  final List<String> highlights;

  @override
  State<AboutProject> createState() => _AboutProjectState();
}

class _AboutProjectState extends State<AboutProject> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = Typo.manrope(15, Typo.regular, Palette.soft).copyWith(height: 1.6);
    final d = widget.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Motion.easeInOut,
            alignment: Alignment.topCenter,
            child: Text(d, style: style, maxLines: _open ? null : 3, overflow: _open ? null : TextOverflow.ellipsis),
          ),
        if (d != null && d.length > 140)
          LinkButton(
            _open ? 'Show less' : 'Read more',
            size: 13,
            weight: Typo.extrabold,
            onTap: () => setState(() => _open = !_open),
          ),
        if (widget.highlights.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in widget.highlights)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: ShapeDecoration(color: Palette.white(0.07), shape: const StadiumBorder()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TIconView(TIcon.check, size: 14, color: Palette.acceptedText),
                      const SizedBox(width: 6),
                      Text(h, style: Typo.manrope(12, Typo.bold, Palette.soft)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "How to get there": an arch-shaped map card with the pin, the address, travel times and two actions.
class Directions extends StatelessWidget {
  const Directions({super.key, required this.title, required this.info});

  final String title;
  final ProjectInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Map of $title',
          child: Container(
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: Palette.panelDeep,
              shape: ArchBorder(bottomRadius: 24, side: BorderSide(color: Palette.white(0.12))),
            ),
            // TODO: API — swap for a static map image from the project's map embed once the CMS provides one.
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _MapPainter()),
                Align(
                  alignment: const Alignment(0, 0.15),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.yellow,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                        ),
                        boxShadow: [
                          BoxShadow(color: Palette.yellow.o(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ).pop(0.2),
                Positioned(
                  top: 22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const ShapeDecoration(color: Palette.softer, shape: StadiumBorder()),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Palette.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('Live location', style: Typo.manrope(11, Typo.extrabold, Palette.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: Typo.outfit(18, Typo.semibold, Palette.text)),
        if (info.address != null) ...[
          const SizedBox(height: 3),
          Text(info.address!, style: Typo.manrope(13, Typo.regular, Palette.muted)),
        ],
        if (info.travel.isNotEmpty) ...[const SizedBox(height: 14), FactsStrip(info.travel, size: 22)],
        const SizedBox(height: 14),
        Row(
          children: [
            if (info.mapUrl != null)
              Expanded(
                child: GhostButton(
                  'Open in Maps',
                  icon: TIcon.send,
                  height: 48,
                  onTap: () => openExternal(context, info.mapUrl!),
                ),
              ),
            if (info.mapUrl != null && info.guideUrl != null) const SizedBox(width: 10),
            if (info.guideUrl != null)
              Expanded(
                child: GhostButton(
                  'Route video',
                  icon: TIcon.play,
                  height: 48,
                  onTap: () => openExternal(context, info.guideUrl!),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final land = Path()
      ..moveTo(0, s.height * 0.72)
      ..cubicTo(s.width * 0.23, s.height * 0.57, s.width * 0.34, s.height * 0.81, s.width * 0.57, s.height * 0.57)
      ..cubicTo(s.width * 0.8, s.height * 0.33, s.width * 0.92, s.height * 0.36, s.width, s.height * 0.4)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(land, Paint()..color = Palette.navyLight.o(0.6));
    Paint road(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-10, s.height * 0.33)
        ..cubicTo(s.width * 0.2, s.height * 0.43, s.width * 0.4, s.height * 0.19, s.width * 0.63, s.height * 0.38)
        ..cubicTo(s.width * 0.8, s.height * 0.52, s.width * 0.9, s.height * 0.62, s.width + 10, s.height * 0.57),
      road(Palette.white(0.18), 6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.17, -10)
        ..cubicTo(s.width * 0.26, s.height * 0.29, s.width * 0.34, s.height * 0.57, s.width * 0.31, s.height + 10),
      road(Palette.white(0.12), 4),
    );
    final dash = road(Palette.yellow.o(0.55), 4);
    for (var t = 0.0; t < 1; t += 0.06) {
      final x = s.width * (0.69 + 0.17 * t);
      final y = s.height * t;
      canvas.drawCircle(Offset(x, y), 2, dash..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

/// Swipeable homeowner testimonials with page dots.
class HomeownerStories extends StatefulWidget {
  const HomeownerStories({super.key, required this.stories});

  final List<HomeownerStory> stories;

  @override
  State<HomeownerStories> createState() => _HomeownerStoriesState();
}

class _HomeownerStoriesState extends State<HomeownerStories> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;
    return Column(
      children: [
        SizedBox(
          height: 268,
          child: PageView.builder(
            controller: _pages,
            itemCount: stories.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: i < stories.length - 1 ? 10 : 0),
              child: _StoryCard(story: stories[i]),
            ),
          ),
        ),
        if (stories.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < stories.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? Palette.yellow : Palette.white(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final HomeownerStory story;

  @override
  Widget build(BuildContext context) {
    final initials = story.name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    return Glass(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -4, top: -26, child: Text('”', style: Typo.outfit(96, Typo.bold, Palette.yellow.o(0.22)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '${story.rating} out of 5 stars',
                excludeSemantics: true,
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Text(
                          '★',
                          style: TextStyle(fontSize: 16, color: i < story.rating ? Palette.yellow : Palette.white(0.2)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  '“${story.quote}”',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.outfit(17, Typo.medium, Palette.text).copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  InitialsAvatar(initials, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.name, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                        if (story.since != null)
                          Text(
                            'Verified homeowner since ${story.since}',
                            style: Typo.manrope(12, Typo.semibold, Palette.acceptedText),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
