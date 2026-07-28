import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../core/helpers.dart';

class NewLedgerEntryScreen extends ConsumerStatefulWidget {
  const NewLedgerEntryScreen({super.key});
  @override
  ConsumerState<NewLedgerEntryScreen> createState() => _NewLedgerEntryScreenState();
}

class _NewLedgerEntryScreenState extends ConsumerState<NewLedgerEntryScreen> {
  bool _isJama = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _toggleType(bool isJama) {
    if (_isJama == isJama) return;
    HapticFeedback.lightImpact();
    setState(() => _isJama = isJama);
  }

  Future<void> _save() async {
    if (_selectedEmployeeId == null) {
      showError(context, 'Please select an employee');
      HapticFeedback.vibrate();
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      showError(context, 'Please enter an amount');
      HapticFeedback.vibrate();
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showError(context, 'Please enter a valid amount');
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await ref.read(ledgerServiceProvider).create({
        'employee_id': _selectedEmployeeId!,
        'date': dateStr,
        'type': _isJama ? 'jama' : 'udhaar',
        'amount': _amountController.text.trim(),
        'note': _noteController.text.trim(),
      });
      ref.read(ledgerRefreshProvider.notifier).state++;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showEmployeePicker(BuildContext context, ColorScheme cs) async {
    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final asyncData = ref.watch(employeeListProvider);
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: asyncData.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (employees) {
                          final query = searchCtrl.text.toLowerCase().trim();
                          final filtered = query.isEmpty
                              ? employees
                              : employees.where((e) =>
                                  e.name.toLowerCase().contains(query)).toList();
                          if (filtered.isEmpty) {
                            return Center(
                              child: Text('No employees found',
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                            );
                          }
                          return ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final emp = filtered[i];
                              final isSelected = emp.id == _selectedEmployeeId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
                                  ),
                                ),
                                title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: emp.designation != null ? Text(emp.designation!) : null,
                                trailing: isSelected
                                    ? Icon(PhosphorIconsFill.checkCircle, color: cs.primary)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedEmployeeId = emp.id;
                                    _selectedEmployeeName = emp.name;
                                  });
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
    searchCtrl.dispose();
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
                    InkWell(
                      onTap: () => _showEmployeePicker(context, cs),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.identificationBadge, color: cs.onSurfaceVariant),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Employee',
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedEmployeeName ?? 'Select Employee',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _selectedEmployeeName != null ? cs.onSurface : cs.onSurfaceVariant,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Icon(PhosphorIconsRegular.caretDown, color: cs.onSurfaceVariant, size: 16),
                          ],
                        ),
                      ),
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
