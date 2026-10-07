import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/scaffold.dart';
import 'discover_widgets.dart';
import 'media_art.dart';

// MARK: Media items

enum MediaKind { photo, video, art }

class MediaItem {
  const MediaItem.photo(this.category, this.caption, String this.image, {this.rendering = false})
    : kind = MediaKind.photo,
      video = null,
      art = null,
      plan = PlanKind.house,
      sample = true;

  const MediaItem.video(this.category, this.caption, String this.video, {required String poster})
    : kind = MediaKind.video,
      image = poster,
      art = null,
      rendering = false,
      plan = PlanKind.house,
      sample = true;

  /// Media uploaded in the CMS.
  MediaItem.remote(MediaRef m)
    : category = m.category,
      caption = m.caption.isEmpty ? m.category : m.caption,
      kind = m.type == 'video' ? MediaKind.video : MediaKind.photo,
      image = m.type == 'video' ? (m.poster ?? '') : m.url,
      video = m.type == 'video' ? m.url : null,
      art = null,
      rendering = false,
      plan = PlanKind.house,
      sample = false;

  const MediaItem.art(this.category, this.caption, ArtKind this.art, {this.plan = PlanKind.house})
    : kind = MediaKind.art,
      image = null,
      video = null,
      rendering = false,
      sample = true;

  final String category, caption;
  final MediaKind kind;

  /// Photo asset name, or a video's poster.
  final String? image;

  /// Bundled video asset path.
  final String? video;
  final ArtKind? art;
  final PlanKind plan;

  /// The brand's website artwork: labelled "Artist’s rendering" instead of "Sample".
  final bool rendering;

  /// Placeholder media (false for CMS uploads).
  final bool sample;

  String get tag => switch (kind) {
    _ when rendering => 'Artist’s rendering',
    _ when !sample => caption,
    MediaKind.photo => 'Sample photo',
    MediaKind.video => 'Sample video',
    MediaKind.art => 'Sample illustration',
  };
}

const _tour = 'assets/videos/sample-project-tour.mp4';
const _walkthrough = 'assets/videos/sample-unit-walkthrough.mp4';
const _neighborhood = 'assets/videos/sample-neighborhood.mp4';

// Gallery media per location and product come from the API (`media` on each location and product). Until a
// project has uploads, each category is filled with clearly labelled sample media so the gallery can be
// experienced end to end.

/// Location page: Project video, Project map, Facade, Amenities, Nearby destinations.
List<MediaItem> projectGallery(Brand b, Location? l) =>
    l != null && l.media.isNotEmpty ? l.media.map(MediaItem.remote).toList() : _sampleProject(b);

/// Product page: Product video, Facade, Floor plan, Interior shots.
List<MediaItem> productGallery(Brand b, Product p) =>
    p.media.isNotEmpty ? p.media.map(MediaItem.remote).toList() : _sampleProduct(b, p);

List<MediaItem> _sampleProject(Brand b) => [
  MediaItem.video('Project video', 'Project tour', _tour, poster: b.image),
  const MediaItem.art('Project map', 'Site development plan', ArtKind.siteMap),
  MediaItem.photo('Facade', 'Main facade', b.image, rendering: true),
  for (final s in b.shots) MediaItem.photo('Facade', 'Streetscape', s),
  const MediaItem.photo('Amenities', 'Parks and open space', 'photoRow'),
  const MediaItem.art('Amenities', 'Clubhouse, pool and playground', ArtKind.amenities),
  const MediaItem.video('Nearby destinations', 'The neighborhood', _neighborhood, poster: 'photoRow'),
  const MediaItem.art('Nearby destinations', 'Schools, markets and transport', ArtKind.nearby),
];

List<MediaItem> _sampleProduct(Brand b, Product p) {
  final condo = b.group == HomeGroup.condo;
  final plans = condo
      ? [MediaItem.art('Floor plan', 'Unit plan', ArtKind.floorPlan, plan: _unitPlan(p))]
      : p.floors >= 2 && p.name.contains('LOFT')
      ? const [
          MediaItem.art('Floor plan', 'Ground floor', ArtKind.floorPlan, plan: PlanKind.loftGround),
          MediaItem.art('Floor plan', 'Loft', ArtKind.floorPlan, plan: PlanKind.loftUpper),
        ]
      : const [MediaItem.art('Floor plan', 'Ground floor', ArtKind.floorPlan)];
  return [
    const MediaItem.video('Product video', 'Unit walkthrough', _walkthrough, poster: 'photoInterior'),
    MediaItem.photo('Facade', 'Facade', b.image, rendering: true),
    ...plans,
    const MediaItem.photo('Interior shots', 'Living and dining', 'photoInterior'),
  ];
}

PlanKind _unitPlan(Product p) {
  final n = '${p.name} ${p.code ?? ''}'.toLowerCase();
  if (n.contains('2 bedroom') || n.contains('2br')) return PlanKind.twoBedroom;
  if (n.contains('1 bedroom') || n.contains('1br')) return PlanKind.oneBedroom;
  return PlanKind.studio;
}

/// Gallery categories in first-appearance order with their first index.
List<(String, int)> _categories(List<MediaItem> items) {
  final out = <(String, int)>[];
  for (final (i, m) in items.indexed) {
    if (!out.any((c) => c.$1 == m.category)) out.add((m.category, i));
  }
  return out;
}

// MARK: Carousel

/// Gallery on the location and product pages: category chips that jump to their first item, a snapping card
/// carousel that peeks the next card, and page dots. The active video plays muted on loop; tap opens the viewer.
class MediaCarousel extends StatefulWidget {
  const MediaCarousel({super.key, required this.items, required this.heroPrefix});

  final List<MediaItem> items;
  final String heroPrefix;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  static const _height = 232.0;
  static const _gap = 10.0;
  static const _peek = 26.0;

  final _scroll = ScrollController();
  int _index = 0;
  double _extent = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final i = (_scroll.offset / _extent).round().clamp(0, widget.items.length - 1);
    if (i != _index) {
      HapticFeedback.selectionClick();
      setState(() => _index = i);
    }
  }

  void _jump(int i) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      (i * _extent).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 520),
      curve: Motion.sheet,
    );
  }

  Future<void> _open(int i) async {
    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: null,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => MediaViewer(items: widget.items, initial: i, heroPrefix: widget.heroPrefix),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
    // Land the carousel on whatever the viewer was showing.
    if (result != null && result != _index) {
      setState(() => _index = result);
      if (_scroll.hasClients) _scroll.jumpTo((result * _extent).clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final cats = _categories(items);
    final current = items[_index].category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chips(cats, current),
        const SizedBox(height: 12),
        SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = math.max(1.0, box.maxWidth - _peek);
              _extent = width + _gap;
              return OverflowBox(
                minWidth: box.maxWidth + Spacing.gutter * 2,
                maxWidth: box.maxWidth + Spacing.gutter * 2,
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
                  physics: SnapPhysics(_extent),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) => SizedBox(
                    width: width,
                    child: _MediaTile(
                      item: items[i],
                      active: i == _index,
                      heroTag: '${widget.heroPrefix}-$i',
                      position: '${i + 1} / ${items.length}',
                      onTap: () => i == _index ? _open(i) : _jump(i),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < items.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Motion.easeInOut,
                width: i == _index ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: i == _index ? Palette.yellow : Palette.white(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const Spacer(),
            Text('Tap to view full screen', style: Typo.manrope(12, Typo.semibold, Palette.subtle)),
          ],
        ),
      ],
    );
  }

  Widget _chips(List<(String, int)> cats, String current) => _ChipRow(
    children: [
      for (final (name, first) in cats)
        _CategoryChip(
          title: name,
          icon: _categoryIcon(name),
          count: widget.items.where((m) => m.category == name).length,
          selected: name == current,
          onTap: () => _jump(first),
        ),
    ],
  );
}

/// What flies between the carousel and the viewer: the cover-cropped still, never a second video player.
Widget _still(MediaItem m) => switch (m.kind) {
  MediaKind.art => MediaArt(kind: m.art!, plan: m.plan),
  _ => Photo(m.image!),
};

HeroFlightShuttleBuilder _shuttle(MediaItem m) =>
    (_, _, _, _, _) => ClipRRect(borderRadius: BorderRadius.circular(22), child: _still(m));

TIcon _categoryIcon(String category) => switch (category) {
  'Project video' || 'Product video' => TIcon.video,
  'Project map' => TIcon.map,
  'Floor plan' => TIcon.plan,
  'Amenities' => TIcon.tree,
  'Nearby destinations' => TIcon.compass,
  'Interior shots' => TIcon.home,
  _ => TIcon.image,
};

/// Horizontally scrolling chip row that bleeds to the screen edges.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: LayoutBuilder(
      builder: (context, box) => OverflowBox(
        minWidth: box.maxWidth + Spacing.gutter * 2,
        maxWidth: box.maxWidth + Spacing.gutter * 2,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final TIcon icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Palette.ink : Palette.softer;
    return Tap(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$title, $count',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Motion.easeInOut,
        height: 36,
        padding: const EdgeInsets.only(left: 12, right: 14),
        decoration: ShapeDecoration(
          color: selected ? Palette.yellow : Palette.white(0.05),
          shape: StadiumBorder(side: hairline(selected ? Palette.yellow : Palette.white(0.14))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TIconView(icon, size: 15, color: fg),
            const SizedBox(width: 7),
            Text(title, style: Typo.manrope(13, Typo.bold, fg)),
            if (count > 1) ...[
              const SizedBox(width: 6),
              Text('$count', style: Typo.manrope(12, Typo.extrabold, fg.o(0.6))),
            ],
          ],
        ),
      ),
    );
  }
}

// MARK: Tile

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.active,
    required this.heroTag,
    required this.position,
    required this.onTap,
  });

  final MediaItem item;
  final bool active;
  final String heroTag, position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = squircle(22, side: hairline(Palette.white(0.1)));
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      semanticLabel: '${item.category}: ${item.caption}. ${item.tag}.',
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Palette.panel),
            Hero(
              tag: heroTag,
              flightShuttleBuilder: _shuttle(item),
              child: switch (item.kind) {
                MediaKind.photo => Photo(item.image!, kenBurns: active),
                MediaKind.video => active ? LoopingVideo(asset: item.video!, poster: item.image!) : Photo(item.image!),
                MediaKind.art => MediaArt(kind: item.art!, plan: item.plan),
              },
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Palette.deep.o(0.35), Palette.deep.o(0), Palette.deep.o(0), Palette.deep.o(0.85)],
                    stops: const [0, 0.28, 0.5, 1],
                  ),
                ),
              ),
            ),
            Positioned(left: 12, top: 12, child: MediaLabel(item.tag, dot: item.rendering ? null : Palette.yellow)),
            Positioned(right: 12, top: 12, child: MediaLabel(position)),
            if (item.kind == MediaKind.video && !active)
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Palette.white(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.white(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: TIconView(TIcon.play, size: 22, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 64,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: Typo.manrope(10, Typo.extrabold, Palette.yellow).copyWith(letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.outfit(18, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Palette.deep.o(0.5),
                    alignment: Alignment.center,
                    child: TIconView(
                      item.kind == MediaKind.video && active ? TIcon.play : TIcon.expand,
                      size: 16,
                      color: Palette.text,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(decoration: ShapeDecoration(shape: shape)),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: Video

/// Bundled asset path or network URL → controller. Muted playback never interrupts the buyer's own audio.
VideoPlayerController _controller(String src) {
  final options = VideoPlayerOptions(mixWithOthers: true);
  return src.startsWith('http')
      ? VideoPlayerController.networkUrl(Uri.parse(src), videoPlayerOptions: options)
      : VideoPlayerController.asset(src, videoPlayerOptions: options);
}

/// A muted, looping asset video that covers its frame; shows [poster] until the first frame is ready.
class LoopingVideo extends StatefulWidget {
  const LoopingVideo({super.key, required this.asset, required this.poster, this.fit = BoxFit.cover});

  final String asset, poster;
  final BoxFit fit;

  @override
  State<LoopingVideo> createState() => _LoopingVideoState();
}

class _LoopingVideoState extends State<LoopingVideo> {
  late final _c = _controller(widget.asset);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _c.setVolume(0);
          await _c.setLooping(true);
          await _c.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Photo(widget.poster),
        AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: _ready ? _VideoFrame(controller: _c, fit: widget.fit) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.controller, required this.fit});

  final VideoPlayerController controller;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final s = controller.value.size;
    return ClipRect(
      child: FittedBox(
        fit: fit,
        child: SizedBox(width: s.width, height: s.height, child: VideoPlayer(controller)),
      ),
    );
  }
}

// MARK: Full-screen viewer

/// Full-screen gallery: swipe between items, pinch or double-tap to zoom photos and plans, tap a video to
/// pause, scrub its progress bar, jump with the thumbnail strip, and drag down to dismiss.
/// Pops with the index on show so the carousel can follow.
class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.items, required this.initial, required this.heroPrefix});

  final List<MediaItem> items;
  final int initial;
  final String heroPrefix;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> with SingleTickerProviderStateMixin {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  bool _chrome = true;
  bool _zoomed = false;
  double _drag = 0;
  late final _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  double _settleFrom = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() => setState(() => _drag = _settleFrom * (1 - Motion.sheet.transform(_settle.value))));
  }

  @override
  void dispose() {
    _pages.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  void _go(int i) => _pages.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Motion.sheet);

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final item = items[_index];
    final insets = MediaQuery.paddingOf(context);
    final progress = (_drag.abs() / 400).clamp(0.0, 1.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Palette.deep.o(1 - progress * 0.85)),
          GestureDetector(
            onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _drag += d.delta.dy),
            onVerticalDragEnd: _zoomed
                ? null
                : (d) {
                    if (_drag.abs() > 110 || d.velocity.pixelsPerSecond.dy.abs() > 800) {
                      _close();
                    } else {
                      _settleFrom = _drag;
                      _settle.forward(from: 0);
                    }
                  },
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: Transform.scale(
                scale: 1 - progress * 0.18,
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _index = i;
                      _zoomed = false;
                    });
                  },
                  itemBuilder: (_, i) => _ViewerPage(
                    item: items[i],
                    active: i == _index,
                    heroTag: '${widget.heroPrefix}-$i',
                    chrome: _chrome,
                    onToggleChrome: () => setState(() => _chrome = !_chrome),
                    onZoom: (z) {
                      if (z != _zoomed) setState(() => _zoomed = z);
                    },
                  ),
                ),
              ),
            ),
          ),
          // Top bar
          AnimatedOpacity(
            opacity: _chrome && progress < 0.05 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_chrome,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, insets.top + 6, 16, 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Palette.deep.o(0.8), Palette.deep.o(0)],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconCircleButton(
                        TIcon.close,
                        label: 'Close',
                        background: Palette.deep.o(0.5),
                        blur: true,
                        onTap: _close,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.category, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
                            Text(
                              '${_index + 1} of ${items.length}',
                              style: Typo.manrope(12, Typo.semibold, Palette.muted),
                            ),
                          ],
                        ),
                      ),
                      MediaLabel(item.tag, dot: item.rendering ? null : Palette.yellow),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Caption and thumbnails
          AnimatedOpacity(
            opacity: _chrome && progress < 0.05 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_chrome,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.fromLTRB(0, 40, 0, insets.bottom + 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Palette.deep.o(0), Palette.deep.o(0.9)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(item.caption, style: Typo.outfit(22, Typo.semibold, Palette.text)),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          item.rendering
                              ? 'Artist’s rendering. Actual project may vary.'
                              : 'Placeholder until the project’s own media is uploaded.',
                          style: Typo.manrope(13, Typo.regular, Palette.muted),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 58,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => _Thumb(item: items[i], selected: i == _index, onTap: () => _go(i)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.selected, required this.onTap});

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      selected: selected,
      semanticLabel: item.caption,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Palette.yellow : Palette.white(0.12),
            width: selected ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0.55,
            duration: const Duration(milliseconds: 220),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.kind == MediaKind.art) MediaArt(kind: item.art!, plan: item.plan) else Photo(item.image!),
                if (item.kind == MediaKind.video)
                  const Center(child: TIconView(TIcon.play, size: 16, color: Color(0xFFFFFFFF))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerPage extends StatefulWidget {
  const _ViewerPage({
    required this.item,
    required this.active,
    required this.heroTag,
    required this.chrome,
    required this.onToggleChrome,
    required this.onZoom,
  });

  final MediaItem item;
  final bool active, chrome;
  final String heroTag;
  final VoidCallback onToggleChrome;
  final ValueChanged<bool> onZoom;

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage> with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  Animation<Matrix4>? _tween;
  Offset _tapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() => _zoom.value = _tween!.value);
  }

  @override
  void didUpdateWidget(_ViewerPage old) {
    super.didUpdateWidget(old);
    if (!widget.active && old.active) _zoom.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _zoom.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _doubleTap() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    final end = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(-_tapAt.dx * 1.5, -_tapAt.dy * 1.5, 0, 1)
            ..scaleByDouble(2.5, 2.5, 1, 1));
    _tween = Matrix4Tween(begin: _zoom.value, end: end).animate(CurvedAnimation(parent: _anim, curve: Motion.sheet));
    _anim.forward(from: 0);
    widget.onZoom(!zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.kind == MediaKind.video) {
      return _ViewerVideo(item: item, active: widget.active, chrome: widget.chrome, heroTag: widget.heroTag);
    }
    final media = Center(
      child: item.kind == MediaKind.art
          ? AspectRatio(
              aspectRatio: 3 / 2,
              child: Hero(
                tag: widget.heroTag,
                flightShuttleBuilder: _shuttle(item),
                child: MediaArt(kind: item.art!, plan: item.plan),
              ),
            )
          : _AspectImage(
              name: item.image!,
              builder: (image) => Hero(tag: widget.heroTag, flightShuttleBuilder: _shuttle(item), child: image),
            ),
    );
    return GestureDetector(
      onTap: widget.onToggleChrome,
      onDoubleTapDown: (d) => _tapAt = d.localPosition,
      onDoubleTap: _doubleTap,
      child: InteractiveViewer(
        transformationController: _zoom,
        minScale: 1,
        maxScale: 4,
        onInteractionEnd: (_) => widget.onZoom(_zoom.value.getMaxScaleOnAxis() > 1.01),
        child: media,
      ),
    );
  }
}

/// A photo laid out at its own aspect ratio, so the hero lands exactly on the visible image.
class _AspectImage extends StatefulWidget {
  const _AspectImage({required this.name, required this.builder});

  final String name;
  final Widget Function(Widget image) builder;

  @override
  State<_AspectImage> createState() => _AspectImageState();
}

class _AspectImageState extends State<_AspectImage> {
  late final _provider = photoProvider(widget.name);
  ImageStream? _stream;
  late final _listener = ImageStreamListener((info, _) {
    final a = info.image.width / info.image.height;
    if (mounted && a != _aspect) setState(() => _aspect = a);
  });
  double _aspect = 3 / 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream?.removeListener(_listener);
    _stream = _provider.resolve(createLocalImageConfiguration(context))..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: _aspect,
    child: widget.builder(
      Image(image: _provider, fit: BoxFit.cover, filterQuality: FilterQuality.high, excludeFromSemantics: true),
    ),
  );
}

/// Viewer video: plays when its page is active, tap toggles pause, the bar scrubs.
class _ViewerVideo extends StatefulWidget {
  const _ViewerVideo({required this.item, required this.active, required this.chrome, required this.heroTag});

  final MediaItem item;
  final bool active, chrome;
  final String heroTag;

  @override
  State<_ViewerVideo> createState() => _ViewerVideoState();
}

class _ViewerVideoState extends State<_ViewerVideo> {
  late final _c = _controller(widget.item.video!);
  bool _ready = false;
  bool _flash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _c
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _c.setLooping(true);
          if (widget.active) await _c.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {});
  }

  @override
  void didUpdateWidget(_ViewerVideo old) {
    super.didUpdateWidget(old);
    if (!_ready || widget.active == old.active) return;
    widget.active ? _c.play() : _c.pause();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    HapticFeedback.lightImpact();
    _c.value.isPlaying ? _c.pause() : _c.play();
    _flashTimer?.cancel();
    setState(() => _flash = true);
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.heroTag,
                    flightShuttleBuilder: _shuttle(widget.item),
                    child: Photo(widget.item.image!),
                  ),
                  if (_ready) _VideoFrame(controller: _c, fit: BoxFit.cover),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _c,
            builder: (context, v, _) {
              final paused = _ready && !v.isPlaying;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AnimatedOpacity(
                      opacity: _flash || paused ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: Palette.deep.o(0.55), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: TIconView(
                          v.isPlaying ? TIcon.pause : TIcon.play,
                          size: 28,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  if (_ready)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: bottom + 150,
                      child: AnimatedOpacity(
                        opacity: widget.chrome ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: _Scrubber(controller: _c, value: v),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller, required this.value});

  final VideoPlayerController controller;
  final VideoPlayerValue value;

  static String _t(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = value.duration.inMilliseconds;
    final f = total == 0 ? 0.0 : (value.position.inMilliseconds / total).clamp(0.0, 1.0);
    final style = Typo.mono(11, Typo.semibold, Palette.soft);
    return Row(
      children: [
        Text(_t(value.position), style: style),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              void seek(double x) => controller.seekTo(value.duration * (x / box.maxWidth).clamp(0.0, 1.0));
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => seek(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => seek(d.localPosition.dx),
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(color: Palette.white(0.2), borderRadius: BorderRadius.circular(2)),
                      ),
                      Container(
                        width: box.maxWidth * f,
                        height: 4,
                        decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(2)),
                      ),
                      Positioned(
                        left: (box.maxWidth * f - 7).clamp(0, box.maxWidth - 14),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(color: Color(0xFFFFFFFF), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Text(_t(value.duration), style: style),
      ],
    );
  }
}
