import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/validated_field.dart';
import '../../providers/providers.dart';

class NewLedgerEntryScreen extends ConsumerStatefulWidget {
  const NewLedgerEntryScreen({super.key});
  @override
  ConsumerState<NewLedgerEntryScreen> createState() => _NewLedgerEntryScreenState();
}

class _NewLedgerEntryScreenState extends ConsumerState<NewLedgerEntryScreen> {
  bool _isJama = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _employeeCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _employeeCtrl.dispose();
    super.dispose();
  }

  void _toggleType(bool isJama) {
    if (_isJama == isJama) return;
    HapticFeedback.lightImpact();
    setState(() => _isJama = isJama);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_employeeCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() {});
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await ref.read(ledgerServiceProvider).create({
        'employee_id': _employeeCtrl.text.trim(),
        'date': dateStr,
        'type': _isJama ? 'jama' : 'udhaar',
        'amount': double.tryParse(_amountController.text) ?? 0,
        'note': _noteController.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeColor = _isJama
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final surfaceColor = activeColor.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.x, color: cs.onSurface),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: Text('New Entry',
            style: tt.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        color: surfaceColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PremiumToggle(
                              title: 'Give Advance',
                              subtitle: 'Jama',
                              isActive: _isJama,
                              activeColor:
                                  const Color(0xFF10B981),
                              icon:
                                  PhosphorIconsFill.arrowUpRight,
                              onTap: () => _toggleType(true),
                            ),
                          ),
                          Expanded(
                            child: _PremiumToggle(
                              title: 'Deduct',
                              subtitle: 'Udhaar',
                              isActive: !_isJama,
                              activeColor:
                                  const Color(0xFFEF4444),
                              icon:
                                  PhosphorIconsFill.arrowDownLeft,
                              onTap: () => _toggleType(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: Text('Amount',
                          style: tt.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Text('₹',
                            style: tt.displayLarge?.copyWith(
                                color: activeColor
                                    .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400)),
                        const SizedBox(width: 8),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: tt.displayLarge?.copyWith(
                              color: activeColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2.0,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              filled: false,
                              hintText: '0',
                              hintStyle:
                                  TextStyle(color: Colors.black12),
                            ),
                            onChanged: (_) =>
                                HapticFeedback.selectionClick(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _PremiumDatePicker(
                      cs: cs,
                      date: _selectedDate,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme:
                                  cs.copyWith(primary: activeColor),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    ValidatedField(
                      controller: _employeeCtrl,
                      label: 'Employee ID',
                      prefixIcon: PhosphorIconsRegular.identificationBadge,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter employee ID' : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      style: tt.titleMedium,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: Icon(
                            PhosphorIconsRegular.textAa,
                            color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24,
                    MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ],
                ),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: activeColor,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Entry',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  final String title, subtitle;
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumToggle(
      {required this.title,
      required this.subtitle,
      required this.isActive,
      required this.activeColor,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isActive ? activeColor : Colors.grey,
                size: 24),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    color: isActive ? activeColor : Colors.grey,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 14,
                    color: isActive
                        ? Colors.black
                        : Colors.grey,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PremiumDatePicker extends StatelessWidget {
  final ColorScheme cs;
  final DateTime date;
  final VoidCallback onTap;

  const _PremiumDatePicker(
      {required this.cs,
      required this.date,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.calendarBlank,
                color: cs.onSurfaceVariant),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction Date',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                    isToday
                        ? 'Today, ${DateFormat('MMM d').format(date)}'
                        : DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 16)),
              ],
            ),
            const Spacer(),
            Icon(PhosphorIconsRegular.caretDown,
                color: cs.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}
