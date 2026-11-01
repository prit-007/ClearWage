import 'package:flutter/material.dart';

/// Smooth shimmer loading skeleton with a single AnimationController
/// shared across all items for zero-jank rendering at 120fps.
class ShimmerLoading extends StatefulWidget {
  final int itemCount;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool useSliver;

  const ShimmerLoading({
    super.key,
    this.itemCount = 5,
    this.height = 80,
    this.padding,
    this.useSliver = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = List.generate(widget.itemCount, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index < widget.itemCount - 1 ? 12 : 0),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return _ShimmerItem(
              height: widget.height,
              color: cs.surfaceContainerHighest,
              shimmerValue: _animation.value,
            );
          },
        ),
      );
    });

    final content = Padding(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(children: items),
    );

    if (!widget.useSliver) return content;

    return SliverPadding(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(24, 16, 24, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.itemCount - 1 ? 12 : 0,
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return _ShimmerItem(
                  height: widget.height,
                  color: cs.surfaceContainerHighest,
                  shimmerValue: _animation.value,
                );
              },
            ),
          ),
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  final double height;
  final Color color;
  final double shimmerValue;

  const _ShimmerItem({
    required this.height,
    required this.color,
    required this.shimmerValue,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.transparent,
                  Colors.white24,
                  Colors.transparent,
                ],
                stops: [
                  (shimmerValue - 0.4).clamp(0.0, 1.0),
                  shimmerValue.clamp(0.0, 1.0),
                  (shimmerValue + 0.4).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
