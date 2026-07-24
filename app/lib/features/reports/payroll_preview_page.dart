import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class PayrollPreviewScreen extends StatefulWidget {
  const PayrollPreviewScreen({super.key});
  @override
  State<PayrollPreviewScreen> createState() => _PayrollPreviewScreenState();
}

class _PayrollPreviewScreenState extends State<PayrollPreviewScreen> {
  final List<Map<String, String>> employees = [
    {'name': 'Rahul Sharma', 'gross': '₹12,600', 'net': '11700'},
    {'name': 'Sunita Devi', 'gross': '₹9,800', 'net': '9200'},
    {'name': 'Vijay Kumar', 'gross': '₹14,200', 'net': '13500'},
    {'name': 'Amit Singh', 'gross': '₹8,400', 'net': '7800'},
    {'name': 'Priya Patel', 'gross': '₹11,200', 'net': '10900'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lock Payroll', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: _PayrollSummaryGlassCard(cs: cs, tt: tt),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Final Adjustments', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                        child: Text('Oct 2026', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final emp = employees[index];
                      return _EditablePayrollRow(
                        cs: cs, tt: tt,
                        name: emp['name']!,
                        gross: emp['gross']!,
                        initialNet: emp['net']!,
                      );
                    },
                    childCount: employees.length,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                  ),
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      minimumSize: const Size.fromHeight(60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(PhosphorIconsBold.lockKey, color: Colors.white),
                    label: const Text('Lock & Generate Slips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSummaryGlassCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;

  const _PayrollSummaryGlassCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(child: _PayStat(cs: cs, label: 'Gross Pay', value: '₹2,85,400', color: cs.onSurface)),
                Container(width: 1, height: 40, color: cs.outlineVariant),
                Expanded(child: _PayStat(cs: cs, label: 'Udhaar Deducted', value: '-₹42,600', color: const Color(0xFFEF4444))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NET PAYABLE', style: tt.labelMedium?.copyWith(color: const Color(0xFF10B981), fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                Text('₹2,42,800', style: tt.headlineMedium?.copyWith(color: const Color(0xFF10B981), fontWeight: FontWeight.w900, letterSpacing: -1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayStat extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  final Color color;

  const _PayStat({required this.cs, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _EditablePayrollRow extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String name, gross, initialNet;

  const _EditablePayrollRow({required this.cs, required this.tt, required this.name, required this.gross, required this.initialNet});

  @override
  State<_EditablePayrollRow> createState() => _EditablePayrollRowState();
}

class _EditablePayrollRowState extends State<_EditablePayrollRow> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNet);
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_isFocused) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name.split(' ').map((e) => e[0]).take(2).join();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isFocused ? widget.cs.primary.withValues(alpha: 0.05) : widget.cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isFocused ? widget.cs.primary : widget.cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: widget.cs.surfaceContainerHighest,
              child: Text(initials, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.cs.onSurface)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Gross: ${widget.gross}', style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _isFocused ? widget.cs.surface : widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isFocused ? widget.cs.primary.withValues(alpha: 0.5) : Colors.transparent),
              ),
              child: Row(
                children: [
                  Text('₹', style: TextStyle(color: _isFocused ? widget.cs.primary : widget.cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: widget.cs.primary),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                      onChanged: (_) => HapticFeedback.selectionClick(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
