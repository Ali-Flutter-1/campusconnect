import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable entrance animation: a quick fade + slight upward slide, with an
/// optional staggered delay based on list [index].
///
/// The stagger is small and **capped** ([maxStaggerSteps]) so long / paginated
/// lists don't have later cards waiting hundreds of ms to appear — every item
/// animates in within a snappy window regardless of how far down it is.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 280),
    this.staggerStep = const Duration(milliseconds: 35),
    this.maxStaggerSteps = 6,
    this.beginOffset = 0.06,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerStep;

  /// Upper bound on how many steps of stagger delay are applied.
  final int maxStaggerSteps;
  final double beginOffset;

  @override
  Widget build(BuildContext context) {
    final steps = math.min(index, maxStaggerSteps);
    return child
        .animate(delay: staggerStep * steps)
        .fadeIn(duration: duration)
        .moveY(
          begin: beginOffset * 100,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
