import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/complaint.dart';

ColorRamp _statusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.success;
    case 'in_progress':
      return AppColors.primary;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'in_progress':
      return 'IN PROGRESS';
    case 'resolved':
      return 'RESOLVED';
    case 'rejected':
      return 'REJECTED';
    default:
      return 'PENDING';
  }
}

/// A request as the admin sees it: submitter details plus inline triage actions
/// (approve / resolve / reject / reopen). [onAction] receives the target status.
class AdminComplaintCard extends StatelessWidget {
  const AdminComplaintCard({
    super.key,
    required this.complaint,
    required this.onAction,
  });

  final Complaint complaint;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = _statusColor(complaint.status);
    final author = complaint.authorName?.trim();
    final who = (author != null && author.isNotEmpty)
        ? author
        : (complaint.authorEmail ?? 'Unknown student');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: AppTypography.inter(
                    size: AppTypography.md,
                    weight: AppTypography.semiBold,
                    color: surfaces.primaryText,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.s500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _statusLabel(complaint.status),
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.bold,
                    color: color.s400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.user,
                  size: 13, color: surfaces.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.medium,
                    color: surfaces.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'CC-${complaint.id.substring(0, 4).toUpperCase()} · '
            '${complaint.category} · '
            '${DateFormat('MMM d').format(complaint.createdAt)}',
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: surfaces.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            complaint.description,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Actions(status: complaint.status, onAction: onAction),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.status, required this.onAction});

  final String status;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    switch (status) {
      case 'open':
        buttons.add(_ActionButton(
          icon: LucideIcons.check,
          label: 'Approve',
          color: AppColors.primary,
          onTap: () => onAction('in_progress'),
        ));
        buttons.add(_ActionButton(
          icon: LucideIcons.x,
          label: 'Reject',
          color: AppColors.error,
          onTap: () => onAction('rejected'),
        ));
      case 'in_progress':
        buttons.add(_ActionButton(
          icon: LucideIcons.checkCheck,
          label: 'Resolve',
          color: AppColors.success,
          onTap: () => onAction('resolved'),
        ));
        buttons.add(_ActionButton(
          icon: LucideIcons.x,
          label: 'Reject',
          color: AppColors.error,
          onTap: () => onAction('rejected'),
        ));
      case 'resolved':
        // Terminal state — a resolved request can't be reopened.
        return const _ClosedNote(
          icon: LucideIcons.checkCheck,
          label: 'Resolved',
          color: AppColors.success,
        );
      default: // rejected
        buttons.add(_ActionButton(
          icon: LucideIcons.rotateCcw,
          label: 'Reopen',
          color: AppColors.warning,
          onTap: () => onAction('open'),
        ));
    }

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

/// Non-interactive footer shown for terminal states (e.g. resolved), so there's
/// no reopen action.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final ColorRamp color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color.s400),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.inter(
            size: AppTypography.sm,
            weight: AppTypography.semiBold,
            color: color.s400,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorRamp color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.s500.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color.s400),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.inter(
                  size: AppTypography.sm,
                  weight: AppTypography.semiBold,
                  color: color.s400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
