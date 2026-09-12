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
    required this.accentText,
    required this.dangerText,
    required this.successText,
    required this.warningText,
  });

  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;

  /// Accent and status colors for text and icons sitting *on the scaffold or a
  /// card*, as opposed to on a filled chip. The ramp step has to flip between
  /// themes: the light steps that read on navy are far too pale on near-white.
  final Color accentText;
  final Color dangerText;
  final Color successText;
  final Color warningText;

  static const light = AppSurfaces(
    scaffoldBackground: Color(0xFFFAFAFA), // neutral[50]
    // Opaque white over the near-white scaffold: the ported rgba(255,255,255,
    // 0.8) resolved to within ~1.5% of the background, so cards had no edge.
    // The border carries the rest of the separation.
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0x14000000), // rgba(0,0,0,0.08)
    primaryText: Color(0xFF171717), // neutral[900]
    secondaryText: Color(0xFF64748B), // secondary[500]
    divider: Color(0x0F000000),
    accentText: Color(0xFF1D4ED8), // primary[600]
    dangerText: Color(0xFFDC2626), // error[600]
    successText: Color(0xFF16A34A), // success[600]
    warningText: Color(0xFFD97706), // warning[600]
  );

  static const dark = AppSurfaces(
    scaffoldBackground: Color(0xFF0F172A), // secondary[900]
    cardBackground: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    cardBorder: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    primaryText: AppColors.white,
    secondaryText: Color(0xFFCBD5E1), // secondary[300]
    divider: Color(0x0FFFFFFF),
    accentText: Color(0xFF60A5FA), // primary[400]
    dangerText: Color(0xFFF87171), // error[400]
    successText: Color(0xFF4ADE80), // success[400]
    warningText: Color(0xFFFBBF24), // warning[400]
  );

  @override
  AppSurfaces copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? divider,
    Color? accentText,
    Color? dangerText,
    Color? successText,
    Color? warningText,
  }) {
    return AppSurfaces(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
      accentText: accentText ?? this.accentText,
      dangerText: dangerText ?? this.dangerText,
      successText: successText ?? this.successText,
      warningText: warningText ?? this.warningText,
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
      accentText: Color.lerp(accentText, other.accentText, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
    );
  }
}

/// Convenience access: `context.surfaces` and `context.isDark`.
extension AppSurfacesContext on BuildContext {
  AppSurfaces get surfaces =>
      Theme.of(this).extension<AppSurfaces>() ?? AppSurfaces.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Picks the step of a per-item ramp (a category or status color) that reads as
/// text or an icon on the app's surfaces: the darker 600 on light backgrounds,
/// the lighter 400 on dark ones.
///
/// [AppSurfaces] carries the fixed accent and status colors; this covers the
/// cases where the ramp varies per row and no single token can know it.
extension ColorRampOnSurface on ColorRamp {
  Color onSurface(BuildContext context) => context.isDark ? s400 : s600;
}
