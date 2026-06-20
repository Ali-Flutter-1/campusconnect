import 'package:connect/core/theme/app_colors.dart';
import 'package:connect/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('design tokens (ported from theme.ts)', () {
    test('primary[500] matches the source palette (#2563EB)', () {
      expect(AppColors.primary.s500, const Color(0xFF2563EB));
    });

    test('secondary[900] matches the source palette (#0F172A)', () {
      expect(AppColors.secondary.s900, const Color(0xFF0F172A));
    });

    test('spacing scale matches the source values', () {
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
    });
  });
}
