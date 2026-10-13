import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../staff/providers/staff_providers.dart';

Future<void> showBroadcastSheet(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    builder: (ctx) => const BroadcastSheet(),
  );
}

class BroadcastSheet extends ConsumerStatefulWidget {
  const BroadcastSheet({super.key});

  @override
  ConsumerState<BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends ConsumerState<BroadcastSheet> {
  final _msgCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.text = 'નમસ્તે!';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final employees = ref.read(employeeListProvider).valueOrNull ?? [];
    final targets = employees
        .where((e) => _selected.contains(e.id) && e.phone.isNotEmpty)
        .toList();
    if (targets.isEmpty) return;
    final svc = ref.read(whatsappServiceProvider);
    setState(() => _sending = true);
    var opened = 0;
    for (final e in targets) {
      final text = _msgCtrl.text.trim().isNotEmpty
          ? _msgCtrl.text.trim()
          : svc.greeting(name: e.name.split(' ').first);
      try {
        if (await svc.launch(phone: e.phone, text: text)) opened++;
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _sending = false);
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened == 0
                ? l.broadcastNoWhatsapp
                : l.broadcastOpening(opened, targets.length),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final employees =
        ref
            .watch(employeeListProvider)
            .valueOrNull
            ?.where((e) => e.isActive)
            .toList() ??
        const [];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.broadcastTitle,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.broadcastSubtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: l.broadcastHint,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            Expanded(
              child: employees.isEmpty
                  ? Center(child: Text(l.broadcastNoStaff))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (final e in employees)
                          CheckboxListTile(
                            value: _selected.contains(e.id),
                            activeColor: cs.primary,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (v == true) {
                                  _selected.add(e.id);
                                } else {
                                  _selected.remove(e.id);
                                }
                              });
                            },
                            title: Text(
                              e.name,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                getInitials(e.name),
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              e.phone.isEmpty ? l.broadcastNoPhone : e.phone,
                              style: tt.labelSmall?.copyWith(
                                color: e.phone.isEmpty
                                    ? cs.error
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty || _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          PhosphorIconsFill.whatsappLogo,
                          color: cs.onPrimary,
                        ),
                  label: Text(
                    _selected.isEmpty
                        ? l.broadcastSelectStaff
                        : l.broadcastSendTo(_selected.length),
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
