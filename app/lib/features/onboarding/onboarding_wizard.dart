import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/widgets/validated_field.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});
  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _companyNameCtrl.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      setState(() {});
      return;
    }
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn);
      setState(() => _currentStep++);
    } else {
      HapticFeedback.heavyImpact();
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn);
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Setup Factory',
            style:
                tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            style: TextButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant),
            child: const Text('Skip',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: _AnimatedStepProgress(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              cs: cs,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AnimatedStepWrapper(
                    step: 0,
                    currentStep: _currentStep,
                    child: _StepProfile(
                        cs: cs, tt: tt,
                        companyCtrl: _companyNameCtrl,
                        addressCtrl: _addressCtrl,
                        contactCtrl: _contactCtrl)),
                _AnimatedStepWrapper(
                    step: 1,
                    currentStep: _currentStep,
                    child: _StepShifts(cs: cs, tt: tt)),
                _AnimatedStepWrapper(
                    step: 2,
                    currentStep: _currentStep,
                    child: _StepPolicies(cs: cs, tt: tt)),
                _AnimatedStepWrapper(
                    step: 3,
                    currentStep: _currentStep,
                    child: _StepReview(
                        cs: cs,
                        tt: tt,
                        companyName: _companyNameCtrl,
                        addressCtrl: _addressCtrl,
                        contactCtrl: _contactCtrl)),
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
                    offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Icon(PhosphorIconsRegular.caretLeft,
                        color: cs.onSurface),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _nextStep,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < _totalSteps - 1
                          ? 'Continue'
                          : 'Complete Setup',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ColorScheme cs;

  const _AnimatedStepProgress(
      {required this.currentStep,
      required this.totalSteps,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i <= currentStep;
        final isPassed = i < currentStep;
        final isLast = i == totalSteps - 1;

        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary
                      : cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: Center(
                  child: isPassed
                      ? Icon(PhosphorIconsBold.check,
                          size: 14, color: cs.onPrimary)
                      : Text('${i + 1}',
                          style: TextStyle(
                            color: isActive
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          )),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? cs.primary
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _AnimatedStepWrapper extends StatelessWidget {
  final int step;
  final int currentStep;
  final Widget child;

  const _AnimatedStepWrapper(
      {required this.step,
      required this.currentStep,
      required this.child});

  @override
  Widget build(BuildContext context) {
    if (step != currentStep) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      key: ValueKey(step),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _StepProfile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final TextEditingController companyCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController contactCtrl;
  const _StepProfile(
      {required this.cs, required this.tt, required this.companyCtrl, required this.addressCtrl, required this.contactCtrl});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Factory Profile',
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Give your workspace an identity.',
            style: tt.bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 40),
        ValidatedField(
          controller: companyCtrl,
          label: 'Company Name',
          prefixIcon: PhosphorIconsRegular.buildings,
          validator: (v) => v == null || v.trim().isEmpty ? 'Enter your company name' : null,
        ),
        const SizedBox(height: 16),
        ValidatedField(
          controller: addressCtrl,
          label: 'Factory Address',
          prefixIcon: PhosphorIconsRegular.mapPin,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        ValidatedField(
          controller: contactCtrl,
          label: 'Contact Number',
          prefixIcon: PhosphorIconsRegular.phone,
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
        Text('Shift Timings',
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Define when your factory floor operates.',
            style: tt.bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        _ShiftInputCard(
            cs: cs,
            label: 'General Shift',
            start: '08:00 AM',
            end: '05:00 PM',
            icon: PhosphorIconsDuotone.sun),
        const SizedBox(height: 16),
        _ShiftInputCard(
            cs: cs,
            label: 'Night Shift',
            start: '10:00 PM',
            end: '06:00 AM',
            icon: PhosphorIconsDuotone.moonStars),
      ],
    );
  }
}

class _ShiftInputCard extends StatelessWidget {
  final ColorScheme cs;
  final String label, start, end;
  final dynamic icon;

  const _ShiftInputCard(
      {required this.cs,
      required this.label,
      required this.start,
      required this.end,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _PremiumTimePicker(
                      cs: cs, label: 'Start Time', time: start)),
              const SizedBox(width: 16),
              Expanded(
                  child: _PremiumTimePicker(
                      cs: cs, label: 'End Time', time: end)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumTimePicker extends StatelessWidget {
  final ColorScheme cs;
  final String label, time;
  const _PremiumTimePicker(
      {required this.cs, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                PhosphorIcon(PhosphorIconsRegular.clock,
                    size: 16, color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPolicies extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _StepPolicies({required this.cs, required this.tt});
  @override
  State<_StepPolicies> createState() => _StepPoliciesState();
}

class _StepPoliciesState extends State<_StepPolicies> {
  int _otTrigger = 9;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Payroll Rules',
            style: widget.tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Set up overtime and calculation rules.',
            style: widget.tt.bodyLarge
                ?.copyWith(color: widget.cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        Text('When does Overtime start?',
            style: widget.tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _PremiumRadioCard(
            cs: widget.cs,
            title: 'After 8 Hours',
            subtitle: 'Standard global industrial rule',
            value: 8,
            groupValue: _otTrigger,
            onChanged: (v) => _updateOT(v)),
        const SizedBox(height: 12),
        _PremiumRadioCard(
            cs: widget.cs,
            title: 'After 9 Hours',
            subtitle: 'Includes 1 hour unpaid break',
            value: 9,
            groupValue: _otTrigger,
            onChanged: (v) => _updateOT(v)),
        const SizedBox(height: 12),
        _PremiumRadioCard(
            cs: widget.cs,
            title: 'No Overtime',
            subtitle: 'Fixed wages only, regardless of hours',
            value: 0,
            groupValue: _otTrigger,
            onChanged: (v) => _updateOT(v)),
        const SizedBox(height: 32),
        Text('Additional Configurations',
            style: widget.tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _PremiumSwitch(
            cs: widget.cs,
            title: 'Enable Week-Off Pay',
            subtitle:
                'Pay workers for Sunday if they work Mon-Sat',
            initial: true),
        _PremiumSwitch(
            cs: widget.cs,
            title: 'Allow Advance (Jama)',
            subtitle:
                'Workers can request mid-month advances',
            initial: true),
      ],
    );
  }

  void _updateOT(int? v) {
    if (v != null) {
      HapticFeedback.selectionClick();
      setState(() => _otTrigger = v);
    }
  }
}

class _PremiumRadioCard extends StatelessWidget {
  final ColorScheme cs;
  final String title, subtitle;
  final int value, groupValue;
  final ValueChanged<int?> onChanged;

  const _PremiumRadioCard(
      {required this.cs,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.groupValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            PhosphorIcon(
                isSelected
                    ? PhosphorIconsFill.radioButton
                    : PhosphorIconsRegular.circle,
                color: isSelected
                    ? cs.primary
                    : cs.onSurfaceVariant,
                size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSwitch extends StatefulWidget {
  final ColorScheme cs;
  final String title, subtitle;
  final bool initial;
  const _PremiumSwitch(
      {required this.cs,
      required this.title,
      required this.subtitle,
      required this.initial});
  @override
  State<_PremiumSwitch> createState() => _PremiumSwitchState();
}

class _PremiumSwitchState extends State<_PremiumSwitch> {
  late bool _val;
  @override
  void initState() {
    super.initState();
    _val = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: widget.cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _val,
            activeThumbColor: widget.cs.primary,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              setState(() => _val = v);
            },
          ),
        ],
      ),
    );
  }
}

class _StepReview extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final TextEditingController companyName;
  final TextEditingController addressCtrl;
  final TextEditingController contactCtrl;
  const _StepReview(
      {required this.cs,
      required this.tt,
      required this.companyName,
      required this.addressCtrl,
      required this.contactCtrl});

  @override
  Widget build(BuildContext context) {
    final cName = companyName.text.trim().isEmpty
        ? "Your Factory"
        : companyName.text.trim();
    final address = addressCtrl.text.trim();
    final contact = contactCtrl.text.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Ready to Launch',
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Review your setup before entering the dashboard.',
            style: tt.bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        _ReviewSummaryCard(
            cs: cs,
            icon: PhosphorIconsDuotone.buildings,
            title: 'Profile',
            items: [
              'Name: $cName',
              if (address.isNotEmpty) 'Address: $address',
              if (contact.isNotEmpty) 'Contact: $contact',
              'Shifts: 2 Active (General, Night)'
            ]),
        const SizedBox(height: 16),
        _ReviewSummaryCard(
            cs: cs,
            icon: PhosphorIconsDuotone.calculator,
            title: 'Payroll Policies',
            items: [
              'Overtime starts after 9 Hours',
              'Advance Requests Allowed',
              'Week-Off Pay Enabled'
            ]),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsDuotone.info,
                  color: cs.tertiary),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(
                      'All configurations can be changed later in the Settings menu.',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final ColorScheme cs;
  final dynamic icon;
  final String title;
  final List<String> items;

  const _ReviewSummaryCard(
      {required this.cs,
      required this.icon,
      required this.title,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.checkCircle,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e,
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
