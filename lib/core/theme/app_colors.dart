import 'package:flutter/material.dart';

/// A 50–900 color ramp, mirroring the nested objects in the RN `theme.ts`
/// (e.g. `COLORS.primary[500]` becomes `AppColors.primary.s500`).
@immutable
class ColorRamp {
  const ColorRamp({
    required this.s50,
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s900,
  });

  final Color s50, s100, s200, s300, s400, s500, s600, s700, s800, s900;

  /// The ramp as a Flutter [MaterialColor] (primary value = `s500`), useful for
  /// seeding [ColorScheme] / [ThemeData].
  MaterialColor toMaterialColor() => MaterialColor(s500.toARGB32(), {
        50: s50,
        100: s100,
        200: s200,
        300: s300,
        400: s400,
        500: s500,
        600: s600,
        700: s700,
        800: s800,
        900: s900,
      });
}

/// 1:1 port of `constants/theme.ts` `COLORS`.
abstract final class AppColors {
  static const primary = ColorRamp(
    s50: Color(0xFFEFF6FF),
    s100: Color(0xFFDBEAFE),
    s200: Color(0xFFBFDBFE),
    s300: Color(0xFF93C5FD),
    s400: Color(0xFF60A5FA),
    s500: Color(0xFF2563EB),
    s600: Color(0xFF1D4ED8),
    s700: Color(0xFF1E40AF),
    s800: Color(0xFF1E3A8A),
    s900: Color(0xFF172554),
  );

  static const secondary = ColorRamp(
    s50: Color(0xFFF8FAFC),
    s100: Color(0xFFF1F5F9),
    s200: Color(0xFFE2E8F0),
    s300: Color(0xFFCBD5E1),
    s400: Color(0xFF94A3B8),
    s500: Color(0xFF64748B),
    s600: Color(0xFF475569),
    s700: Color(0xFF334155),
    s800: Color(0xFF1E293B),
    s900: Color(0xFF0F172A),
  );

  static const accent = ColorRamp(
    s50: Color(0xFFECFEFF),
    s100: Color(0xFFCFFAFE),
    s200: Color(0xFFA5F3FC),
    s300: Color(0xFF67E8F9),
    s400: Color(0xFF22D3EE),
    s500: Color(0xFF06B6D4),
    s600: Color(0xFF0891B2),
    s700: Color(0xFF0E7490),
    s800: Color(0xFF155E75),
    s900: Color(0xFF164E63),
  );

  /// Burnt-orange accent from the "Academic Ethereal" mockups (base #BC4800).
  /// Used for tertiary badges, date chips and destructive-ish highlights.
  static const tertiary = ColorRamp(
    s50: Color(0xFFFEF4EC),
    s100: Color(0xFFFCE2CE),
    s200: Color(0xFFF9C49D),
    s300: Color(0xFFF5A06A),
    s400: Color(0xFFEE7B38),
    s500: Color(0xFFDC5A12),
    s600: Color(0xFFBC4800),
    s700: Color(0xFF983A06),
    s800: Color(0xFF7A300C),
    s900: Color(0xFF652A0E),
  );

  static const success = ColorRamp(
    s50: Color(0xFFF0FDF4),
    s100: Color(0xFFDCFCE7),
    s200: Color(0xFFBBF7D0),
    s300: Color(0xFF86EFAC),
    s400: Color(0xFF4ADE80),
    s500: Color(0xFF22C55E),
    s600: Color(0xFF16A34A),
    s700: Color(0xFF15803D),
    s800: Color(0xFF166534),
    s900: Color(0xFF14532D),
  );

  static const warning = ColorRamp(
    s50: Color(0xFFFFFBEB),
    s100: Color(0xFFFEF3C7),
    s200: Color(0xFFFDE68A),
    s300: Color(0xFFFCD34D),
    s400: Color(0xFFFBBF24),
    s500: Color(0xFFF59E0B),
    s600: Color(0xFFD97706),
    s700: Color(0xFFB45309),
    s800: Color(0xFF92400E),
    s900: Color(0xFF78350F),
  );

  static const error = ColorRamp(
    s50: Color(0xFFFEF2F2),
    s100: Color(0xFFFEE2E2),
    s200: Color(0xFFFECACA),
    s300: Color(0xFFFCA5A5),
    s400: Color(0xFFF87171),
    s500: Color(0xFFEF4444),
    s600: Color(0xFFDC2626),
    s700: Color(0xFFB91C1C),
    s800: Color(0xFF991B1B),
    s900: Color(0xFF7F1D1D),
  );

  static const neutral = ColorRamp(
    s50: Color(0xFFFAFAFA),
    s100: Color(0xFFF5F5F5),
    s200: Color(0xFFE5E5E5),
    s300: Color(0xFFD4D4D4),
    s400: Color(0xFFA3A3A3),
    s500: Color(0xFF737373),
    s600: Color(0xFF525252),
    s700: Color(0xFF404040),
    s800: Color(0xFF262626),
    s900: Color(0xFF171717),
  );

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);
}
