import 'package:flutter/widgets.dart';

/// [Text] with Apple's standard line-break strategy (`NSLineBreakStrategy.pushOut`): when a paragraph would end
/// with a single word on its last line, earlier words are pushed down to join it — as SwiftUI `Text` does on iOS.
/// Use it for anything that can wrap (headlines, paragraphs) so line breaks match the native app.
class IText extends StatelessWidget {
  const IText(this.data, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final text = box.maxWidth.isFinite && box.maxWidth > 0 ? _pushOut(context, box.maxWidth) : data;
        return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
      },
    );
  }

  String _pushOut(BuildContext context, double width) {
    final def = DefaultTextStyle.of(context);
    final painter = TextPainter(
      text: TextSpan(text: data, style: def.style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: def.textHeightBehavior,
      maxLines: maxLines,
    );
    try {
      final lines = _layout(painter, width);
      if (lines.length < 2 || _words(lines.last) >= 2) return data;
      // Narrow the measure until the last line holds at least two words without adding a line.
      var lo = width * 0.5, hi = width;
      List<String>? best;
      for (var i = 0; i < 14; i++) {
        final mid = (lo + hi) / 2;
        final l = _layout(painter, mid);
        if (l.length == lines.length && _words(l.last) >= 2) {
          best = l;
          lo = mid;
        } else if (l.length > lines.length) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      // Re-check from the widest passing width downwards.
      if (best == null) return data;
      return best.map((l) => l.trimRight()).join('\n');
    } finally {
      painter.dispose();
    }
  }

  List<String> _layout(TextPainter p, double width) {
    p.layout(maxWidth: width);
    final out = <String>[];
    var offset = 0;
    while (offset < data.length) {
      final range = p.getLineBoundary(TextPosition(offset: offset));
      if (range.end <= offset) break;
      out.add(data.substring(offset, range.end));
      offset = range.end;
      while (offset < data.length && data[offset] == ' ') {
        offset++;
      }
    }
    return out;
  }

  static int _words(String line) => line.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}
