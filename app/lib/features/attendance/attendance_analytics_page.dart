import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/widgets/fluid_slide_in.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FluidSlideIn(
                delay: 0,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary.withValues(alpha: 0.1), width: 2),
                  ),
                  child: PhosphorIcon(PhosphorIconsDuotone.chartBar, size: 64, color: cs.primary),
                ),
              ),
              const SizedBox(height: 32),
              FluidSlideIn(
                delay: 100,
                child: Text('Coming Soon', style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
              ),
              const SizedBox(height: 16),
              FluidSlideIn(
                delay: 200,
                child: Text(
                  'Detailed predictive analytics with charts, absence trends, and workforce efficiency tracking are on the way.',
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
