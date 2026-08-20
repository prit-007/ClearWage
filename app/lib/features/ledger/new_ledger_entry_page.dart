import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/services.dart';
import 'providers/ledger_providers.dart';
import '../staff/providers/staff_providers.dart';
import '../../core/helpers.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import 'dart:async';

class NewLedgerEntryScreen extends ConsumerStatefulWidget {
  const NewLedgerEntryScreen({super.key});
  @override
  ConsumerState<NewLedgerEntryScreen> createState() =>
      _NewLedgerEntryScreenState();
}

class _NewLedgerEntryScreenState extends ConsumerState<NewLedgerEntryScreen> {
  bool _isJama = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  bool get _hasUnsavedChanges =>
      _selectedEmployeeId != null ||
      _amountController.text.trim().isNotEmpty ||
      _noteController.text.trim().isNotEmpty;

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
      unawaited(HapticFeedback.vibrate());
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      showError(context, 'Please enter an amount');
      unawaited(HapticFeedback.vibrate());
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showError(context, 'Please enter a valid amount');
      unawaited(HapticFeedback.vibrate());
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _saving = true);
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await ref.read(ledgerServiceProvider).create({
        'employee_id': _selectedEmployeeId!,
        'date': dateStr,
        'type': _isJama ? 'jama' : 'udhaar',
        'amount': amount.toStringAsFixed(2),
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

  Future<void> _showEmployeePicker(BuildContext context) async {
    await showAdaptiveSheet<void>(
      context: context,
      builder: (_) => _EmployeePickerSheet(
        selectedEmployeeId: _selectedEmployeeId,
        onSelected: (id, name) {
          setState(() {
            _selectedEmployeeId = id;
            _selectedEmployeeName = name;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeColor = _isJama ? AppColors.success : AppColors.danger;
    final surfaceColor = activeColor.withValues(alpha: 0.05);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showConfirmDialog(
          context,
          title: 'Discard Entry',
          message: 'You have unsaved changes. Discard them?',
          confirmLabel: 'Discard',
          icon: PhosphorIconsRegular.warningCircle,
          isDestructive: true,
        );
        if (confirmed == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.x, color: cs.onSurface),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
          ),
          title: Text(
            'New Entry',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _PremiumToggle(
                                title: 'Give Advance',
                                subtitle: 'Jama',
                                isActive: _isJama,
                                activeColor: AppColors.success,
                                icon: PhosphorIconsFill.arrowUpRight,
                                onTap: () => _toggleType(true),
                              ),
                            ),
                            Expanded(
                              child: _PremiumToggle(
                                title: 'Deduct',
                                subtitle: 'Udhaar',
                                isActive: !_isJama,
                                activeColor: AppColors.danger,
                                icon: PhosphorIconsFill.arrowDownLeft,
                                onTap: () => _toggleType(false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: Text(
                          'Amount',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹',
                            style: tt.displayLarge?.copyWith(
                              color: activeColor.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}$'),
                                ),
                              ],
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
                                hintStyle: TextStyle(color: Colors.black12),
                              ),
                              onChanged: (_) => HapticFeedback.selectionClick(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      _PremiumDatePicker(
                        cs: cs,
                        date: _selectedDate,
                        onTap: () async {
                          unawaited(HapticFeedback.selectionClick());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: cs.copyWith(primary: activeColor),
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
                        onTap: () => _showEmployeePicker(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.identificationBadge,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Employee',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedEmployeeName ??
                                          'Select Employee',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _selectedEmployeeName != null
                                            ? cs.onSurface
                                            : cs.onSurfaceVariant,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                PhosphorIconsRegular.caretDown,
                                color: cs.onSurfaceVariant,
                                size: 16,
                              ),
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
                            color: cs.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: activeColor,
                      minimumSize: const Size.fromHeight(60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Entry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
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

  const _PremiumToggle({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w800,
              ),
            ),
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

  const _PremiumDatePicker({
    required this.cs,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.calendarBlank,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Date',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? 'Today, ${formatDate(date)}' : formatDate(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              PhosphorIconsRegular.caretDown,
              color: cs.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeePickerSheet extends ConsumerStatefulWidget {
  final String? selectedEmployeeId;
  final void Function(String id, String name) onSelected;

  const _EmployeePickerSheet({
    required this.selectedEmployeeId,
    required this.onSelected,
  });

  @override
  ConsumerState<_EmployeePickerSheet> createState() =>
      _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends ConsumerState<_EmployeePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asyncData = ref.watch(employeeListProvider);
    final query = _query.toLowerCase().trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: cs.onSurfaceVariant,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (employees) {
                final filtered = query.isEmpty
                    ? employees
                    : employees
                          .where((e) => e.name.toLowerCase().contains(query))
                          .toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: PhosphorIconsRegular.users,
                      title: 'No employees found',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final emp = filtered[i];
                    final isSelected = emp.id == widget.selectedEmployeeId;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: cs.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: EmployeeAvatar(
                        name: emp.name,
                        photoUrl: emp.photoUrl,
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        textColor: cs.primary,
                      ),
                      title: Text(
                        emp.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: emp.designation != null
                          ? Text(emp.designation!)
                          : null,
                      trailing: isSelected
                          ? Icon(
                              PhosphorIconsFill.checkCircle,
                              color: cs.primary,
                            )
                          : null,
                      onTap: () {
                        widget.onSelected(emp.id, emp.name);
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
