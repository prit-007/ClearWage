import 'package:flutter/material.dart';

class PayrollPreviewScreen extends StatefulWidget {
  const PayrollPreviewScreen({super.key});
  @override
  State<PayrollPreviewScreen> createState() => _PayrollPreviewScreenState();
}

class _PayrollPreviewScreenState extends State<PayrollPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _PayStat(
                    cs: cs, label: 'Gross Pay',
                    value: '₹2,85,400',
                    color: cs.onPrimaryContainer,
                  )),
                  Container(width: 1, height: 36,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _PayStat(
                    cs: cs, label: 'Deductions',
                    value: '₹42,600',
                    color: cs.error,
                  )),
                  Container(width: 1, height: 36,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _PayStat(
                    cs: cs, label: 'Net Payable',
                    value: '₹2,42,800',
                    color: cs.onPrimaryContainer,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Employee Adjustments', style: tt.titleMedium),
              const Spacer(),
              Text('Oct 2026', style: tt.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              )),
            ],
          ),
          const SizedBox(height: 12),
          _buildRow(cs: cs, tt: tt, name: 'Rahul Sharma', gross: '₹12,600', net: '₹11,700'),
          _buildRow(cs: cs, tt: tt, name: 'Sunita Devi', gross: '₹9,800', net: '₹9,200'),
          _buildRow(cs: cs, tt: tt, name: 'Vijay Kumar', gross: '₹14,200', net: '₹13,500'),
          _buildRow(cs: cs, tt: tt, name: 'Amit Singh', gross: '₹8,400', net: '₹7,800'),
          _buildRow(cs: cs, tt: tt, name: 'Priya Patel', gross: '₹11,200', net: '₹10,900'),
          _buildRow(cs: cs, tt: tt, name: 'Ravi Verma', gross: '₹9,600', net: '₹5,200'),
          _buildRow(cs: cs, tt: tt, name: 'Anita Gupta', gross: '₹10,100', net: '₹9,800'),
          _buildRow(cs: cs, tt: tt, name: 'Suresh Rao', gross: '₹7,900', net: '₹7,400'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Lock Payroll & Generate Payslips'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required ColorScheme cs, required TextTheme tt,
    required String name, required String gross, required String net,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceContainerHigh,
                child: Text(
                  name.split(' ').map((e) => e[0]).take(2).join(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(name, style: tt.bodyMedium),
              ),
              Expanded(
                child: Text(gross, style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ), textAlign: TextAlign.right),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: TextEditingController(text: net),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.primary,
                  ),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayStat extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  final Color color;
  const _PayStat({
    required this.cs,
    required this.label, required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold, color: color, fontSize: 15,
        )),
        Text(label, style: TextStyle(
          fontSize: 11, color: color.withValues(alpha: 0.7),
        )),
      ],
    );
  }
}
