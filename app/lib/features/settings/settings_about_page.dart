import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/app_info.dart';

/// Full editorial "About" screen for Factory Workforce.
///
/// Employs glassmorphism, macro-typography, and high-contrast
/// spacing to deliver a premium, editorial reading experience.
class SettingsAboutPage extends ConsumerWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final version = ref
        .watch(appInfoProvider)
        .maybeWhen(data: (info) => info.version, orElse: () => '\u2014');

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'About',
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
        children: [
          // ── Brand Hero ──────────────────────────────────────────────
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: PhosphorIcon(
                PhosphorIconsFill.factory,
                color: scheme.onSurface,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Factory Workforce',
            textAlign: TextAlign.center,
            style: text.displayLarge?.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w400,
              letterSpacing: -2.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VERSION $version',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Smart workforce management for modern factories.',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),

          // ── About the App ──────────────────────────────────────────
          const SizedBox(height: 64),
          _SectionHeader(scheme: scheme, text: text, title: 'About the App'),
          const SizedBox(height: 16),
          _GlassCard(
            scheme: scheme,
            child: Text(
              'Factory Workforce is a comprehensive attendance, payroll, and '
              'workforce management platform built for modern factories. From '
              'real-time attendance tracking with OT computation to ledger '
              'management and payroll processing — everything you need to '
              'manage your workforce, in one place.',
              style: text.bodyLarge?.copyWith(
                color: scheme.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // ── Developer Provenance ──────────────────────────────────
          const SizedBox(height: 40),
          _SectionHeader(scheme: scheme, text: text, title: 'Developer'),
          const SizedBox(height: 16),
          _GlassCard(
            scheme: scheme,
            child: Text(
              'Engineered with precision in Rajkot, Gujarat by '
              'Prit Vasani. Crafted by Developer\'s Paradise on a foundation '
              'of open-source technologies, driven by a relentless pursuit '
              'of reliability, performance, and thoughtful design.',
              style: text.bodyLarge?.copyWith(
                color: scheme.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // ── Tech Stack ──────────────────────────────────────
          const SizedBox(height: 56),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _Badge(scheme: scheme, label: 'Flutter'),
              _Badge(scheme: scheme, label: 'Go'),
              _Badge(scheme: scheme, label: 'PostgreSQL'),
              _Badge(scheme: scheme, label: 'Firebase'),
              _Badge(scheme: scheme, label: 'sqlc'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Internal Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.scheme,
    required this.text,
    required this.title,
  });
  final ColorScheme scheme;
  final TextTheme text;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: text.titleSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.scheme, required this.child});
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.scheme, required this.label});
  final ColorScheme scheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
