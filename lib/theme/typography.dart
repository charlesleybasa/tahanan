import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Outfit (headlines, numbers), Manrope (UI, body), JetBrains Mono (codes). See spec §2.
///
/// Line height is left to the font's own metrics (`height: null`), which is what SwiftUI uses,
/// so text boxes match the native layout.
abstract final class Typo {
  static const _outfit = 'Outfit';
  static const _manrope = 'Manrope';
  static const _mono = 'JetBrainsMono';

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extrabold = FontWeight.w800;

  static TextStyle outfit(double size, [FontWeight weight = semibold, Color? color]) => TextStyle(
    fontFamily: _outfit,
    fontSize: size,
    // Outfit ships up to 700; 800 renders as Bold, as on iOS.
    fontWeight: weight == extrabold ? bold : weight,
    color: color,
  );

  static TextStyle manrope(double size, [FontWeight weight = regular, Color? color]) =>
      TextStyle(fontFamily: _manrope, fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono(double size, [FontWeight weight = medium, Color? color]) =>
      TextStyle(fontFamily: _mono, fontSize: size, fontWeight: weight.value >= 600 ? semibold : medium, color: color);

  // Named styles from the prototype's CSS classes.

  /// `.h1`: Outfit 600, letter-spacing -0.035em.
  static TextStyle h1(double size) => outfit(size, semibold, Palette.text).copyWith(letterSpacing: -0.035 * size);

  /// `.eyebrow`: 12 / 800 / +0.16em, uppercase (apply `.toUpperCase()`), yellow.
  static final eyebrow = manrope(12, extrabold, Palette.yellow).copyWith(letterSpacing: 0.16 * 12);

  /// `.sec`: Outfit 20 / 600 / -0.015em.
  static TextStyle sectionTitle([double size = 20]) =>
      outfit(size, semibold, Palette.text).copyWith(letterSpacing: -0.015 * size);

  /// `.lbl`: 13 / 700 / #AAB9D3.
  static final fieldLabel = manrope(13, bold, Palette.label);

  /// `.muted` paragraph: 15, line spacing 0.3 × size on top of Manrope's natural 1.366 (as native `lineSpacing`).
  static TextStyle mutedBody([double size = 15]) =>
      manrope(size, regular, Palette.muted).copyWith(height: lineGap(0.3 * size, size));

  /// Line height that reproduces SwiftUI `lineSpacing(extra)` for Manrope at [size].
  static double lineGap(double extra, double size) => 1.366 + extra / size;

  /// Settings group overline: 12 / 800 / +0.1em, uppercase.
  static TextStyle overline({Color color = Palette.subtle, double em = 0.1}) =>
      manrope(12, extrabold, color).copyWith(letterSpacing: em * 12);
}

/// Root default text style. `inherit: false` so nothing from Material's typography leaks in.
const rootTextStyle = TextStyle(
  inherit: false,
  fontFamily: 'Manrope',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: Palette.text,
  decoration: TextDecoration.none,
  textBaseline: TextBaseline.alphabetic,
  leadingDistribution: TextLeadingDistribution.proportional,
);

/// Native caps Dynamic Type at xxxLarge (≈1.35×).
const maxTextScale = 1.35;
