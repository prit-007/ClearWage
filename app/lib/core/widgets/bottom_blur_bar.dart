import 'dart:ui';
import 'package:flutter/material.dart';

class BottomBlurBar extends StatelessWidget {
  final Widget child;
  const BottomBlurBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
