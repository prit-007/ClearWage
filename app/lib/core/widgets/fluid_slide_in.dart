import 'package:flutter/material.dart';

class FluidSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const FluidSlideIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child),
        );
      },
      child: child,
    );
  }
}
