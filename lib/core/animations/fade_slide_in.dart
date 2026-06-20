import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable entrance animation: fade + slight upward slide, with an optional
/// stagger delay based on list [index]. Used to animate list items / sections
/// into view, giving the "animated UI" feel the brief asked for.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 400),
    this.staggerStep = const Duration(milliseconds: 60),
    this.beginOffset = 0.08,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerStep;
  final double beginOffset;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: staggerStep * index)
        .fadeIn(duration: duration)
        .moveY(begin: beginOffset * 100, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }
}
