import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});
  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int _currentStep = 0;
  final _companyNameCtrl = TextEditingController();
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totalSteps = 4;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Factory'),
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final isActive = i <= _currentStep;
                final isLast = i == totalSteps - 1;
                return Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isActive ? cs.primary : cs.surfaceContainerHigh,
                        child: isActive && i < _currentStep
                            ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                            : Text('${i + 1}', style: TextStyle(
                                color: isActive ? cs.onPrimary : cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              )),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isActive ? cs.primary : cs.surfaceContainerHigh,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          Text('Step ${_currentStep + 1} of $totalSteps',
              style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _StepProfile(cs: cs, tt: tt, ctrl: _companyNameCtrl),
                _StepShifts(cs: cs, tt: tt),
                _StepPolicies(cs: cs, tt: tt),
                _StepReview(cs: cs, tt: tt, companyName: _companyNameCtrl),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () => _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Back'),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_currentStep < totalSteps - 1) {
                          _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: Text(_currentStep < totalSteps - 1 ? 'Next' : 'Complete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProfile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final TextEditingController ctrl;
  const _StepProfile({
    required this.cs, required this.tt, required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Factory Profile', style: tt.titleLarge),
        const SizedBox(height: 8),
        Text('Tell us about your factory',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: IconButton(
                icon: Icon(Icons.add_photo_alternate_outlined,
                    size: 36, color: cs.onSurface.withValues(alpha: 0.4)),
                onPressed: () {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Upload Logo', textAlign: TextAlign.center,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 32),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Company Name',
            hintText: 'e.g. ABC Fabrics Pvt. Ltd.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Factory Address',
            hintText: 'e.g. Industrial Area, Phase 2',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            hintText: 'e.g. +91 98765 43210',
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

class _StepShifts extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _StepShifts({required this.cs, required this.tt});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Shift Configuration', style: tt.titleLarge),
        const SizedBox(height: 8),
        Text('Define your factory shifts',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 32),
        _ShiftInput(cs: cs, label: 'General Shift', start: '08:00 AM', end: '05:00 PM'),
        const SizedBox(height: 16),
        _ShiftInput(cs: cs, label: 'Shift A', start: '06:00 AM', end: '02:00 PM'),
        const SizedBox(height: 16),
        _ShiftInput(cs: cs, label: 'Night Shift', start: '10:00 PM', end: '06:00 AM'),
      ],
    );
  }
}

class _ShiftInput extends StatelessWidget {
  final ColorScheme cs;
  final String label, start, end;
  const _ShiftInput({
    required this.cs, required this.label,
    required this.start, required this.end,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeInput(cs: cs, label: 'Start', time: start),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeInput(cs: cs, label: 'End', time: end),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final ColorScheme cs;
  final String label, time;
  const _TimeInput({required this.cs, required this.label, required this.time});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(Icons.access_time, size: 18, color: cs.primary),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5),
          )),
          Text(time, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _StepPolicies extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _StepPolicies({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Payroll Policies', style: tt.titleLarge),
        const SizedBox(height: 8),
        Text('Configure wage & attendance rules',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 32),
        Text('Overtime Trigger', style: tt.titleSmall),
        const SizedBox(height: 12),
        RadioListTile<int>(
          title: const Text('After 8 hours'),
          value: 8, groupValue: 9, onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<int>(
          title: const Text('After 9 hours'),
          value: 9, groupValue: 9, onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<int>(
          title: const Text('No overtime'),
          value: 0, groupValue: 9, onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _SwitchTile(cs: cs, title: 'Enable Week-Off Pay', value: true),
        _SwitchTile(cs: cs, title: 'Auto-calculate OT', value: true),
        _SwitchTile(cs: cs, title: 'Round up half-day to full', value: false),
        _SwitchTile(cs: cs, title: 'Allow advance requests', value: true),
      ],
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final ColorScheme cs;
  final String title;
  final bool value;
  const _SwitchTile({required this.cs, required this.title, required this.value});
  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool _value;
  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _StepReview extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final TextEditingController companyName;
  const _StepReview({
    required this.cs, required this.tt, required this.companyName,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Review & Confirm', style: tt.titleLarge),
        const SizedBox(height: 8),
        Text('Verify your factory setup before finishing',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 32),
        _ReviewCard(cs: cs, title: 'Factory',
          items: [
            'Name: ${companyName.text.isEmpty ? "ABC Fabrics" : companyName.text}',
            'Shifts: 3 (General, Shift A, Night)',
            'OT Trigger: After 9 hours',
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(cs: cs, title: 'Policies',
          items: [
            'Week-Off Pay: Enabled',
            'Auto-calculate OT: Yes',
            'Advance Requests: Allowed',
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(cs: cs, title: 'Staff',
          items: [
            'Employees to add: 0 (add later)',
            'Default shift: General',
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: cs.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.onTertiaryContainer, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can modify all settings later from the Settings page.',
                    style: TextStyle(color: cs.onTertiaryContainer, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ColorScheme cs;
  final String title;
  final List<String> items;
  const _ReviewCard({
    required this.cs,
    required this.title, required this.items,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ...items.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: cs.primary)),
                  Expanded(child: Text(e, style: TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
