import 'package:flutter/widgets.dart';

/// Brand and UI colors from specs/exact_ui_design_tokens.md §1 (dark only; no light values are designed).
abstract final class Palette {
  // Brand
  static const night = Color(0xFF08142A);
  static const navy = Color(0xFF16305B);
  static const blue = Color(0xFF2E6BE6);
  static const yellow = Color(0xFFFFC42E);
  static const orange = Color(0xFFF2622E);
  static const green = Color(0xFF2FA96B);

  // Text
  static const text = Color(0xFFF3F6FC);
  static const muted = Color(0xFFA2B2CE);
  static const subtle = Color(0xFF8C9DBC);
  static const label = Color(0xFFAAB9D3);
  static const placeholder = Color(0xFF7F91B2);
  static const soft = Color(0xFFC9D4E8);
  static const softer = Color(0xFFE2E8F3);
  static const dim = Color(0xFF6F82A6);
  static const tabIdle = Color(0xFF8C9BB8);
  static const ringIdle = Color(0xFF5C6F93);

  // Grounds
  static const ink = Color(0xFF0B1A33);
  static const deep = Color(0xFF050D1C);
  static const splash = Color(0xFF071226);
  static const panel = Color(0xFF0F2142);
  static const panelDeep = Color(0xFF10223F);
  static const scanGround = Color(0xFF02060E);
  static const navyLight = Color(0xFF1D3B6E);
  static const tabGlass = Color(0xCC0D1C38);
  static const checkboxIdleBorder = Color(0xFF767676);

  // Status pill text
  static const acceptedText = Color(0xFF62D69C);
  static const reviewedText = Color(0xFFFFC94A);
  static const submittedText = Color(0xFF93B4FF);
  static const todoText = Color(0xFFFF9468);

  /// `rgba(255,255,255,a)`.
  static Color white(double a) => const Color(0xFFFFFFFF).withValues(alpha: a);

  /// linear-gradient(160deg, #4A85F5 0%, #2E6BE6 45%, #2459C9 100%).
  static const roofGradient = LinearGradient(
    begin: Alignment(-0.342, -0.94),
    end: Alignment(0.342, 0.94),
    colors: [Color(0xFF4A85F5), Color(0xFF2E6BE6), Color(0xFF2459C9)],
    stops: [0, 0.45, 1],
  );

  /// linear-gradient(135deg, #3D7BF0, #1D3B6E).
  static const avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D7BF0), Color(0xFF1D3B6E)],
  );
}

extension Alpha on Color {
  /// CSS-style `color @ alpha` shorthand.
  Color o(double a) => withValues(alpha: a);
}
