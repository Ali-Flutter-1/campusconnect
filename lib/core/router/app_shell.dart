import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// One tab in the bottom navigation, bound to a shell [branchIndex].
class _NavItem {
  const _NavItem(this.icon, this.label, this.branchIndex);
  final IconData icon;
  final String label;
  final int branchIndex;
}

// Branch indices match the order of branches in [appRouter]'s shell route:
// 0 Home · 1 Chat · 2 Events · 3 Notices · 4 Profile · 5 Admin Dashboard.
const _studentItems = <_NavItem>[
  _NavItem(LucideIcons.home, 'Home', 0),
  _NavItem(LucideIcons.messageSquare, 'Chat', 1),
  _NavItem(LucideIcons.calendar, 'Events', 2),
  _NavItem(LucideIcons.fileText, 'Notices', 3),
  _NavItem(LucideIcons.user, 'Profile', 4),
];

// Admins get a Dashboard tab in place of the student Home feed.
const _adminItems = <_NavItem>[
  _NavItem(LucideIcons.layoutDashboard, 'Dashboard', 5),
  _NavItem(LucideIcons.calendar, 'Events', 2),
  _NavItem(LucideIcons.messageSquare, 'Chat', 1),
  _NavItem(LucideIcons.fileText, 'Notices', 3),
  _NavItem(LucideIcons.user, 'Profile', 4),
];

/// The persistent scaffold hosting the tab branches and the custom bottom
/// navigation. The visible tabs depend on the signed-in user's role, so admins
/// and students see meaningfully different shells.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);
    final items = isAdmin ? _adminItems : _studentItems;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark
        ? const Color(0xF20F172A) // rgba(15,23,42,0.95)
        : const Color(0xF2FFFFFF); // rgba(255,255,255,0.95)
    final inactive = isDark ? AppColors.secondary.s400 : AppColors.secondary.s500;

    return Scaffold(
      // Keep the body above the bottom bar so each tab page's content and its
      // FAB (e.g. the admin "+" on Events/Notices) clear the nav, instead of
      // rendering behind it.
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, -4),
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: _NavButton(
                      item: item,
                      selected: navigationShell.currentIndex == item.branchIndex,
                      activeColor: AppColors.primary.s500,
                      inactiveColor: inactive,
                      onTap: () => _goBranch(item.branchIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBranch(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      // Tapping the active tab returns it to its root.
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(item.icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppTypography.inter(
              size: 11,
              weight: AppTypography.medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
