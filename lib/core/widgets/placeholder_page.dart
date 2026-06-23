import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/fade_slide_in.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Temporary themed placeholder for tabs/screens not yet implemented.
///
/// Replaced feature-by-feature (Auth → Announcements → ...). It exists so the
/// app shell is fully navigable from day one of the foundation. An optional
/// action button lets a placeholder link to an already-built screen.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final IconData icon;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    // Show an app bar (with an automatic back button) when this page was pushed
    // over another — e.g. the Notifications route opened from the Home bell.
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: surfaces.secondaryText),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.inter(
                    size: AppTypography.xl,
                    weight: AppTypography.bold,
                    color: surfaces.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Coming soon',
                  style: AppTypography.inter(
                    size: AppTypography.base,
                    color: surfaces.secondaryText,
                  ),
                ),
                if (actionLabel != null && actionRoute != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: actionLabel!,
                    onPressed: () => context.push(actionRoute!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
