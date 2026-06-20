import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-specific surface colors that the RN screens computed inline from
/// `isDark ? ... : ...` (card fill, card border, secondary text, scaffold bg).
///
/// Centralizing them in a [ThemeExtension] means widgets read
/// `context.surfaces.cardBackground` instead of repeating the dark/light
/// branching everywhere.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.divider,
  });

  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;

  static const light = AppSurfaces(
    scaffoldBackground: Color(0xFFFAFAFA), // neutral[50]
    cardBackground: Color(0xCCFFFFFF), // rgba(255,255,255,0.8)
    cardBorder: Color(0x0A000000), // rgba(0,0,0,0.04)
    primaryText: Color(0xFF171717), // neutral[900]
    secondaryText: Color(0xFF64748B), // secondary[500]
    divider: Color(0x0F000000),
  );

  static const dark = AppSurfaces(
    scaffoldBackground: Color(0xFF0F172A), // secondary[900]
    cardBackground: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    cardBorder: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    primaryText: AppColors.white,
    secondaryText: Color(0xFFCBD5E1), // secondary[300]
    divider: Color(0x0FFFFFFF),
  );

  @override
  AppSurfaces copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? divider,
  }) {
    return AppSurfaces(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Convenience access: `context.surfaces` and `context.isDark`.
extension AppSurfacesContext on BuildContext {
  AppSurfaces get surfaces =>
      Theme.of(this).extension<AppSurfaces>() ?? AppSurfaces.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
