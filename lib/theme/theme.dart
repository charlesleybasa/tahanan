import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

export 'colors.dart';
export 'gradients.dart';
export 'icons.dart';
export 'motion.dart';
export 'shapes.dart';
export 'spacing.dart';
export 'typography.dart';

/// The app's only theme. The design is dark-only (spec §1.1), so there is no light [ThemeData];
/// `MaterialApp` runs with `themeMode: ThemeMode.dark`.
///
/// Screens draw with the tokens directly; this theme exists so framework widgets (text selection,
/// scrollbars, overscroll, focus) match the design instead of falling back to Material defaults.
abstract final class TahananTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: Palette.night,
    canvasColor: Palette.night,
    colorScheme: const ColorScheme.dark(
      primary: Palette.yellow,
      onPrimary: Palette.ink,
      secondary: Palette.blue,
      onSecondary: Palette.text,
      tertiary: Palette.green,
      error: Palette.orange,
      onError: Palette.text,
      surface: Palette.night,
      onSurface: Palette.text,
      onSurfaceVariant: Palette.muted,
      outline: Color(0x24FFFFFF),
      outlineVariant: Color(0x17FFFFFF),
      surfaceContainerHighest: Palette.panel,
    ),
    textTheme: TextTheme(
      displayLarge: Typo.h1(44),
      displayMedium: Typo.h1(42),
      displaySmall: Typo.h1(34),
      headlineMedium: Typo.h1(32),
      titleLarge: Typo.sectionTitle(),
      titleMedium: Typo.manrope(15, Typo.extrabold, Palette.text),
      bodyLarge: Typo.manrope(16, Typo.regular, Palette.text),
      // Inherited by every Text under the root Material; must not carry a line height (paragraphs set 1.55 explicitly).
      bodyMedium: Typo.manrope(15, Typo.regular, Palette.muted),
      bodySmall: Typo.manrope(13, Typo.regular, Palette.muted),
      labelLarge: Typo.manrope(16, Typo.extrabold, Palette.ink),
      labelMedium: Typo.fieldLabel,
      labelSmall: Typo.overline(),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.yellow,
      selectionColor: Palette.yellow.o(0.3),
      selectionHandleColor: Palette.yellow,
    ),
    // No ink ripples or highlights: every pressable uses the design's scale-to-.97 feedback.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    iconTheme: const IconThemeData(color: Palette.text, size: 20),
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: Palette.yellow,
      scaffoldBackgroundColor: Palette.night,
    ),
  );
}
