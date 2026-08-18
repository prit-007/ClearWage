import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/responsive.dart';

void main() {
  group('AppBreakpoints', () {
    testWidgets('isMobile returns true for width < 700', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(AppBreakpoints.isMobile(context), true);
                expect(AppBreakpoints.isTablet(context), false);
                expect(AppBreakpoints.isDesktop(context), false);
                expect(AppBreakpoints.isWide(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for width >= 700', (tester) async {
      tester.view.physicalSize = const Size(750, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(AppBreakpoints.isTablet(context), true);
                expect(AppBreakpoints.isDesktop(context), false);
                expect(AppBreakpoints.isWide(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for width >= 900', (tester) async {
      tester.view.physicalSize = const Size(950, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(AppBreakpoints.isDesktop(context), true);
                expect(AppBreakpoints.isWide(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isWide returns true for width >= 1100', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(AppBreakpoints.isWide(context), true);
                expect(AppBreakpoints.isDesktop(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    test('constants are correct', () {
      expect(AppBreakpoints.tablet, 700);
      expect(AppBreakpoints.desktop, 900);
      expect(AppBreakpoints.wide, 1100);
      expect(AppBreakpoints.contentMaxWidth, 1200);
      expect(AppBreakpoints.sheetMaxWidth, 540);
    });
  });

  group('ResponsiveContent', () {
    testWidgets('constrains child on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContent(child: Container(color: Colors.red)),
          ),
        ),
      );

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final match = constrainedBoxes.cast<ConstrainedBox?>().firstWhere(
        (b) => b!.constraints.maxWidth == AppBreakpoints.contentMaxWidth,
        orElse: () => null,
      );
      expect(match, isNotNull);
      expect(match!.constraints.maxWidth, AppBreakpoints.contentMaxWidth);
    });

    testWidgets('does not constrain on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContent(child: Container(color: Colors.blue)),
          ),
        ),
      );

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final match = constrainedBoxes.cast<ConstrainedBox?>().firstWhere(
        (b) => b!.constraints.maxWidth == AppBreakpoints.contentMaxWidth,
        orElse: () => null,
      );
      expect(match, isNull);
    });

    testWidgets('respects custom maxWidth', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContent(maxWidth: 800, child: SizedBox()),
          ),
        ),
      );

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final match = constrainedBoxes.cast<ConstrainedBox?>().firstWhere(
        (b) => b!.constraints.maxWidth == 800,
        orElse: () => null,
      );
      expect(match, isNotNull);
    });
  });

  group('AppScrollPhysics', () {
    test('returns non-null physics', () {
      expect(AppScrollPhysics.physics, isNotNull);
    });
  });
}
