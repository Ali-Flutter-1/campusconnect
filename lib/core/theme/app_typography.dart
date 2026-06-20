import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens, porting `TYPOGRAPHY` from `constants/theme.ts`.
///
/// The RN app uses the Inter font family in four weights. Here Inter is loaded
/// at runtime via `google_fonts` (no bundled font files needed), and the RN
/// `fontFamily.regular/medium/semiBold/bold` map to [FontWeight]s.
abstract final class AppTypography {
  // Font sizes (TYPOGRAPHY.sizes).
  static const double xs = 10;
  static const double sm = 12;
  static const double base = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24; // '2xl'
  static const double xxxl = 30; // '3xl'
  static const double xxxxl = 36; // '4xl'

  // Font weights (TYPOGRAPHY.fontFamily.*).
  static const FontWeight regular = FontWeight.w400; // Inter-Regular
  static const FontWeight medium = FontWeight.w500; // Inter-Medium
  static const FontWeight semiBold = FontWeight.w600; // Inter-SemiBold
  static const FontWeight bold = FontWeight.w700; // Inter-Bold

  // Line height multipliers (TYPOGRAPHY.lineHeight).
  static const double lineTight = 1.2;
  static const double lineNormal = 1.5;
  static const double lineRelaxed = 1.625;

  /// Inter [TextStyle] helper used by [AppTheme] and widgets.
  static TextStyle inter({
    required double size,
    FontWeight weight = regular,
    Color? color,
    double height = lineNormal,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
