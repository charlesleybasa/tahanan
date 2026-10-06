/// Layout constants from the prototype (390 × 844 frame, 54 pt status bar). Spec §3.
abstract final class Spacing {
  static const gutter = 20.0;
  static const authGutter = 24.0;

  /// Content top inset inside the safe area.
  static const belowStatusBar = 2.0;

  /// Scroll bottom padding that clears the floating tab bar (plus the bottom safe area).
  static const tabBarClearance = 96.0;
  static const touch = 44.0;
}

abstract final class Radii {
  static const input = 16.0;
  static const card = 22.0;
  static const cardLarge = 26.0;
  static const hero = 28.0;
  static const sheet = 32.0;
}
