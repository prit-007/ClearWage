import 'dart:async';
import 'package:flutter/material.dart';

/// Slides a child in from below with a fade, after a configurable [delay].
/// Uses a single [AnimationController] per widget for zero-jank 120fps.
class FluidSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;
  final double slideDistance;
  const FluidSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.slideDistance = 20,
  });

  @override
  State<FluidSlideIn> createState() => _FluidSlideInState();
}

class _FluidSlideInState extends State<FluidSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == 0) {
      _ctrl.forward();
      _started = true;
    } else {
      Timer(Duration(milliseconds: widget.delay), () {
        if (mounted && !_started) {
          _started = true;
          _ctrl.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
