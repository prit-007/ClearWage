import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../models/report_models.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/employee_avatar.dart';

final defaultersProvider = FutureProvider.autoDispose<List<DefaulterItem>>((ref) {
  return ref.watch(reportServiceProvider).defaulters();
});

class DefaultersScreen extends ConsumerWidget {
  const DefaultersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final asyncValue = ref.watch(defaultersProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Financial Risks', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
            asyncValue.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
                        const SizedBox(height: 16),
                        Text('Failed to load defaulters', style: tt.titleMedium),
                        const SizedBox(height: 8),
                        Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(PhosphorIconsFill.arrowClockwise),
                          label: const Text('Retry'),
                          onPressed: () => ref.invalidate(defaultersProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (defaulters) => defaulters.isEmpty
                  ? SliverFillRemaining(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: PhosphorIcon(PhosphorIconsDuotone.shieldCheck, size: 64, color: const Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 24),
                          Text('Zero Defaulters', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Text('All employee advances are within safe limits.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: FluidSlideIn(
                                  child: Text('${defaulters.length} AT RISK', style: tt.labelSmall?.copyWith(color: const Color(0xFFEF4444), fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                                ),
                              );
                            }
                            final d = defaulters[index - 1];
                            return FluidSlideIn(
                              delay: (index * 80).clamp(0, 500),
                              child: _DefaulterCard(cs: cs, tt: tt, data: d),
                            );
                          },
                          childCount: defaulters.length + 1,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaulterCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DefaulterItem data;

  const _DefaulterCard({required this.cs, required this.tt, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data.name;
    final outstanding = data.outstandingBalance;
    final wage = data.monthlyWage;
    final photoUrl = data.photoUrl;
    const dangerColor = Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dangerColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: dangerColor.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                EmployeeAvatar(
                  name: name,
                  photoUrl: photoUrl,
                  radius: 24,
                  backgroundColor: dangerColor.withValues(alpha: 0.1),
                  textColor: dangerColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Fixed Wage: ₹${wage.toStringAsFixed(0)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PhosphorIcon(PhosphorIconsDuotone.warningCircle, color: dangerColor, size: 28),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: dangerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PENDING RECOVERY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dangerColor, letterSpacing: 0.5)),
                  Text('₹${outstanding.toStringAsFixed(0)}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: dangerColor, letterSpacing: -1.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
