import 'package:flutter/material.dart';

/// 1:1 port of `constants/theme.ts` `SHADOWS`.
///
/// RN shadow props (`shadowOffset`, `shadowOpacity`, `shadowRadius`) map to
/// Flutter [BoxShadow] (`offset`, color opacity, `blurRadius`). `elevation` is
/// RN/Android-only and is approximated by the blur values below.
abstract final class AppShadows {
  static const Color _base = Color(0xFF000000);

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  // Referenced to keep the source color explicit; RN uses '#000'.
  // ignore: unused_field
  static const Color shadowColor = _base;
}
