import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final int itemCount;
  final double height;
  final EdgeInsetsGeometry? padding;

  const ShimmerLoading({
    super.key,
    this.itemCount = 5,
    this.height = 80,
    this.padding,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(24, 16, 24, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: widget.height,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: [
                        (_animation.value - 0.3).clamp(0.0, 1.0),
                        _animation.value.clamp(0.0, 1.0),
                        (_animation.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          ),
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}
