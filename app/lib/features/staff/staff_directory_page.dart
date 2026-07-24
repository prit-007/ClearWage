import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/employee_model.dart';
import '../../providers/providers.dart';
import 'employee_profile_page.dart';
import 'add_employee_page.dart';

final staffListProvider = FutureProvider.autoDispose<List<Employee>>((ref) {
  return ref.watch(staffServiceProvider).list();
});

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final asyncData = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              expandedHeight: 130,
              collapsedHeight: 70,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text('Staff Directory',
                    style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                background: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                    child: _PremiumSearchBar(cs: cs),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.slidersHorizontal,
                      color: cs.onSurface),
                  onPressed: () => HapticFeedback.selectionClick(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            asyncData.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(
                      child: Text('Error: $e',
                          style: TextStyle(color: cs.error)))),
              data: (employees) {
                final grouped = _groupByLetter(employees);

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final letter = grouped.keys.elementAt(index);
                      final staffList = grouped[letter]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Text(letter,
                                style: tt.titleMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18)),
                          ),
                          ...List.generate(staffList.length, (i) {
                            final isJama = i.isEven;
                            final amount = (i + 1) * 1500;

                            return _FluidSlideIn(
                              delay: (index * 20 + i * 50).clamp(0, 400),
                              child: _StaffDirectoryTile(
                                cs: cs,
                                tt: tt,
                                employee: staffList[i],
                                isJama: isJama,
                                amount: amount,
                              ),
                            );
                          }),
                        ],
                      );
                    },
                    childCount: grouped.keys.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
        },
        backgroundColor: cs.primary,
        elevation: 4,
        child: Icon(PhosphorIconsBold.userPlus, color: cs.onPrimary),
      ),
    );
  }

  Map<String, List<Employee>> _groupByLetter(List<Employee> employees) {
    final map = <String, List<Employee>>{};
    for (final e in employees) {
      final letter = e.name.isNotEmpty ? e.name[0].toUpperCase() : '#';
      map.putIfAbsent(letter, () => []).add(e);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) e.key: e.value};
  }
}

class _PremiumSearchBar extends StatelessWidget {
  final ColorScheme cs;
  const _PremiumSearchBar({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          hintStyle:
              TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass,
              color: cs.onSurfaceVariant, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _StaffDirectoryTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;
  final bool isJama;
  final int amount;

  const _StaffDirectoryTile(
      {required this.cs,
      required this.tt,
      required this.employee,
      required this.isJama,
      required this.amount});

  @override
  Widget build(BuildContext context) {
    final amtColor =
        isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final initials = employee.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  EmployeeProfileScreen(employeeId: employee.id)),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  cs.primaryContainer.withValues(alpha: 0.5),
              child: Text(initials,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      fontSize: 14)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name,
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(employee.designation ?? employee.role,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹$amount',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: amtColor)),
                Text(isJama ? 'Adv. Taken' : 'Payable',
                    style: tt.labelSmall?.copyWith(
                        color: amtColor.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FluidSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const _FluidSlideIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: child,
    );
  }
}
