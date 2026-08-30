import 'package:flutter/material.dart';

import '../../data/services/dispute_service.dart';

Future<void> showRaiseDisputeDialog(
  BuildContext context, {
  required DisputeService disputeService,
  required String ledgerId,
  required String employeeId,
}) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Raise Dispute'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Describe the issue with this ledger entry:'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Reason for dispute',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Please enter a reason')),
              );
              return;
            }
            Navigator.pop(ctx, true);
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (confirmed == true && context.mounted) {
    try {
      await disputeService.create(
        ledgerId: ledgerId,
        employeeId: employeeId,
        reason: controller.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
