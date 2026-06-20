import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] from the ported design tokens.
///
/// The RN app derived colors at render time from `useColorScheme()`. Here that
/// becomes two themes selected by [ThemeMode], with shared Inter typography and
/// the [AppSurfaces] extension carrying the translucent card/border/text colors.
abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        surfaces: AppSurfaces.light,
        scaffold: AppColors.neutral.s50,
        onSurface: AppColors.neutral.s900,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        surfaces: AppSurfaces.dark,
        scaffold: AppColors.secondary.s900,
        onSurface: AppColors.white,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppSurfaces surfaces,
    required Color scaffold,
    required Color onSurface,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary.s500,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary.s500,
      secondary: AppColors.accent.s500,
      error: AppColors.error.s500,
      surface: scaffold,
      onSurface: onSurface,
    );

    final baseTextTheme =
        GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme)
            .apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: baseTextTheme,
      extensions: [surfaces],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.inter(
          size: AppTypography.xl,
          weight: AppTypography.bold,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
