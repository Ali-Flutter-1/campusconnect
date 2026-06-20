import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/poll.dart';

/// A poll with progress bars. Before voting, options are tappable; after voting
/// (or when [votedIndex] is set) it shows results with the chosen option
/// highlighted. Reused on the Polls screen and the Home dashboard.
class PollCard extends StatelessWidget {
  const PollCard({
    super.key,
    required this.poll,
    required this.votedIndex,
    required this.onVote,
  });

  final Poll poll;
  final int? votedIndex;
  final void Function(int optionIndex) onVote;

  bool get _hasVoted => votedIndex != null;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16, color: AppColors.primary.s400),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  poll.question,
                  style: AppTypography.inter(
                    size: AppTypography.md,
                    weight: AppTypography.semiBold,
                    color: surfaces.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${poll.totalVotes} votes',
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: surfaces.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < poll.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionBar(
                option: poll.options[i],
                percent: poll.percentFor(poll.options[i]),
                isMine: votedIndex == i,
                showResults: _hasVoted,
                onTap: _hasVoted ? null : () => onVote(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionBar extends StatelessWidget {
  const _OptionBar({
    required this.option,
    required this.percent,
    required this.isMine,
    required this.showResults,
    required this.onTap,
  });

  final PollOption option;
  final double percent;
  final bool isMine;
  final bool showResults;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final fill = isMine ? AppColors.primary.s500 : AppColors.primary.s700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        children: [
          // Track.
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: surfaces.cardBorder,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          // Fill (animated to the result percentage).
          if (showResults)
            FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: 40,
                decoration: BoxDecoration(
                  color: fill.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          // Label row.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  if (isMine) ...[
                    Icon(LucideIcons.checkCircle2,
                        size: 14, color: AppColors.primary.s300),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      option.text,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        size: AppTypography.base,
                        weight: isMine ? AppTypography.semiBold : AppTypography.medium,
                        color: surfaces.primaryText,
                      ),
                    ),
                  ),
                  if (showResults)
                    Text(
                      '${percent.round()}%',
                      style: AppTypography.inter(
                        size: AppTypography.sm,
                        weight: AppTypography.semiBold,
                        color: surfaces.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
