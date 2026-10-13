import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../l10n/app_localizations.dart';

Future<void> showRequestLeaveDialog(BuildContext context) async {
  await showAdaptiveSheet<void>(
    context: context,
    builder: (ctx) => const RequestLeaveSheet(),
  );
}

class RequestLeaveSheet extends ConsumerStatefulWidget {
  const RequestLeaveSheet({super.key});

  @override
  ConsumerState<RequestLeaveSheet> createState() => _RequestLeaveSheetState();
}

class _RequestLeaveSheetState extends ConsumerState<RequestLeaveSheet> {
  String _leaveType = 'paid';
  late DateTime _from = DateTime.now();
  late DateTime _to = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final first = await showDatePicker(
      context: context,
      initialDate: _from.isAfter(now) ? now : _from,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (first == null || !mounted) return;
    final second = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (second == null || !mounted) return;
    setState(() {
      _from = first;
      _to = second;
    });
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(leaveRequestServiceProvider)
          .create(
            leaveType: _leaveType,
            fromDate: _fmt(_from),
            toDate: _fmt(_to),
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).leaveRequestSubmitted),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).leaveRequestTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'paid',
                  label: Text(AppLocalizations.of(context).profPaidLeave),
                ),
                ButtonSegment(
                  value: 'unpaid',
                  label: Text(AppLocalizations.of(context).leaveUnpaid),
                ),
              ],
              selected: {_leaveType},
              onSelectionChanged: (s) => setState(() => _leaveType = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_fmt(_from)} → ${_fmt(_to)}',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(AppLocalizations.of(context).leavePickRange),
              leading: Icon(
                PhosphorIconsRegular.calendarBlank,
                color: cs.primary,
              ),
              trailing: const Icon(PhosphorIconsRegular.caretRight),
              onTap: _pickRange,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).leaveReasonOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(PhosphorIconsFill.calendarCheck),
              label: Text(
                _saving
                    ? AppLocalizations.of(context).commonSubmitting
                    : AppLocalizations.of(context).leaveSubmitRequest,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
