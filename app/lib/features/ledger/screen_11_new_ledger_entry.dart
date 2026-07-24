import 'package:flutter/material.dart';

class NewLedgerEntryScreen extends StatefulWidget {
  const NewLedgerEntryScreen({super.key});
  @override
  State<NewLedgerEntryScreen> createState() => _NewLedgerEntryScreenState();
}

class _NewLedgerEntryScreenState extends State<NewLedgerEntryScreen> {
  bool _isJama = true;
  final _amountController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Entry'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Jama')),
              ButtonSegment(value: false, label: Text('Udhaar')),
            ],
            selected: {_isJama},
            onSelectionChanged: (v) => setState(() => _isJama = v.first),
          ),
          const SizedBox(height: 32),
          Text('Amount', style: tt.labelMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          )),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹', style: tt.displayLarge?.copyWith(
                color: cs.onSurface,
              )),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: tt.displayLarge?.copyWith(
                    color: _isJama ? cs.primary : cs.error,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Date', style: tt.labelMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2027),
              );
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('24 Oct 2026'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add a description...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }
}
