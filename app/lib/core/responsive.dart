import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 900;
  static const double wide = 1100;
  static const double contentMaxWidth = 1200;
  static const double sheetMaxWidth = 540;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > maxWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

class AppScrollPhysics {
  AppScrollPhysics._();

  static ScrollPhysics physics({ScrollPhysics? parent}) {
    ScrollPhysics base;
    if (kIsWeb) {
      base = const ClampingScrollPhysics();
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          base = const BouncingScrollPhysics();
        default:
          base = const ClampingScrollPhysics();
      }
    }
    return parent != null ? base.applyTo(parent) : base;
  }
}

Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.desktop) {
    return showDialog<T>(
      context: context,
      builder: (ctx) {
        final child = builder(ctx);
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.sheetMaxWidth,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: child,
            ),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class ResponsiveStatRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double wideMinWidth;

  const ResponsiveStatRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.wideMinWidth = 250,
  });

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children
            .map((child) => SizedBox(width: wideMinWidth, child: child))
            .toList(),
      );
    }
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
