import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/widgets/validated_field.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet for employees to request a new advance (POST /advance-request).
Future<void> showRequestAdvanceSheet(BuildContext context) async {
  await showAdaptiveSheet<void>(
    context: context,
    builder: (ctx) => const RequestAdvanceSheet(),
  );
}

class RequestAdvanceSheet extends ConsumerStatefulWidget {
  const RequestAdvanceSheet({super.key});

  @override
  ConsumerState<RequestAdvanceSheet> createState() =>
      _RequestAdvanceSheetState();
}

class _RequestAdvanceSheetState extends ConsumerState<RequestAdvanceSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final amount = _amountCtrl.text.trim();
    if (amount.isEmpty) {
      return AppLocalizations.of(context).advanceAmountRequired;
    }
    final amt = double.tryParse(amount);
    if (amt == null || amt <= 0) {
      return AppLocalizations.of(context).advanceAmountInvalid;
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      if (mounted) showError(context, error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(advanceRequestServiceProvider)
          .requestAdvance(
            amount: double.tryParse(_amountCtrl.text.trim())!,
            note: _noteCtrl.text.trim().isEmpty ? '' : _noteCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).advanceSubmitted),
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
              AppLocalizations.of(context).advanceRequestTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ValidatedField(
              controller: _amountCtrl,
              label: AppLocalizations.of(context).advanceAmountLabel,
              prefixIcon: PhosphorIconsDuotone.coins,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(context).advanceAmountRequired;
                }
                final amt = double.tryParse(v.trim());
                if (amt == null || amt <= 0) {
                  return AppLocalizations.of(context).advanceAmountInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ValidatedField(
              controller: _noteCtrl,
              label: AppLocalizations.of(context).advanceNoteLabel,
              hint: AppLocalizations.of(context).advanceNoteHint,
              prefixIcon: PhosphorIconsDuotone.quotes,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(PhosphorIconsFill.handCoins),
              label: Text(
                _saving
                    ? AppLocalizations.of(context).commonSubmitting
                    : AppLocalizations.of(context).advanceSubmitRequest,
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
