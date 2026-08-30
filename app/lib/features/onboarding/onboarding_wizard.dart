import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/validated_field.dart';
import '../../core/providers/services.dart';

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});
  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _pageCtrl = PageController();
  int _otTrigger = 8;
  bool _weekOffPaid = true;

  TimeOfDay _generalStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _generalEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _nightStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _nightEnd = const TimeOfDay(hour: 6, minute: 0);

  String _formatTimeForApi(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  bool _creatingShifts = false;

  Future<void> _setupFactory() async {
    if (_creatingShifts) return;
    setState(() => _creatingShifts = true);
    try {
      final svc = ref.read(onboardingServiceProvider);
      final address = _addressCtrl.text.trim();
      await svc.setup({
        'factory_name': _companyNameCtrl.text.trim(),
        'factory_phone': _contactCtrl.text.trim(),
        'factory_address': address.isEmpty ? null : address,
        'shifts': [
          {
            'name': 'General Shift',
            'start_time': _formatTimeForApi(_generalStart),
            'end_time': _formatTimeForApi(_generalEnd),
            'grace_period_minutes': 15,
            'is_default': true,
          },
          {
            'name': 'Night Shift',
            'start_time': _formatTimeForApi(_nightStart),
            'end_time': _formatTimeForApi(_nightEnd),
            'crosses_midnight': true,
            'grace_period_minutes': 15,
            'is_default': false,
          },
        ],
        'ot_settings': {
          'ot_trigger': _otTrigger == 0
              ? 'after_shift_end'
              : 'after_daily_hours',
          'ot_threshold_hours': _otTrigger.toDouble(),
          'ot_multiplier_default': 1.5,
          'ot_rounding': 30,
          'wage_basis': 'calendar',
          'week_off_paid': _weekOffPaid,
          'weekly_offs': '0,6',
        },
        'leave_policy': {
          'paid_leave_days_per_year': 12,
          'unpaid_leave_days_per_year': 0,
        },
        'holidays': <Map<String, dynamic>>[],
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save setup: $e')));
      }
    } finally {
      if (mounted) setState(() => _creatingShifts = false);
    }
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
        curve: Curves.fastOutSlowIn,
      );
      setState(() => _currentStep++);
    } else {
      HapticFeedback.heavyImpact();
      _setupFactory()
          .then((_) {
            if (mounted) context.go('/home');
          })
          .catchError((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Setup failed. Please try again.'),
                ),
              );
            }
          });
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
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
        title: Text(
          'Setup Factory',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/home');
            },
            style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
                    cs: cs,
                    tt: tt,
                    companyCtrl: _companyNameCtrl,
                    addressCtrl: _addressCtrl,
                    contactCtrl: _contactCtrl,
                  ),
                ),
                _AnimatedStepWrapper(
                  step: 1,
                  currentStep: _currentStep,
                  child: _StepShifts(
                    cs: cs,
                    tt: tt,
                    generalStart: _generalStart,
                    generalEnd: _generalEnd,
                    nightStart: _nightStart,
                    nightEnd: _nightEnd,
                    onGeneralStartChanged: (t) =>
                        setState(() => _generalStart = t),
                    onGeneralEndChanged: (t) => setState(() => _generalEnd = t),
                    onNightStartChanged: (t) => setState(() => _nightStart = t),
                    onNightEndChanged: (t) => setState(() => _nightEnd = t),
                  ),
                ),
                _AnimatedStepWrapper(
                  step: 2,
                  currentStep: _currentStep,
                  child: _StepPolicies(
                    cs: cs,
                    tt: tt,
                    otTrigger: _otTrigger,
                    weekOffPaid: _weekOffPaid,
                    onChanged: (sel) {
                      setState(() {
                        _otTrigger = sel.$1;
                        _weekOffPaid = sel.$2;
                      });
                    },
                  ),
                ),
                _AnimatedStepWrapper(
                  step: 3,
                  currentStep: _currentStep,
                  child: _StepReview(
                    cs: cs,
                    tt: tt,
                    companyName: _companyNameCtrl,
                    addressCtrl: _addressCtrl,
                    contactCtrl: _contactCtrl,
                    otTrigger: _otTrigger,
                    weekOffPaid: _weekOffPaid,
                  ),
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
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.caretLeft,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: FilledButton.icon(
                    icon: _creatingShifts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(PhosphorIconsFill.checkCircle),
                    onPressed: _creatingShifts ? null : _nextStep,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    label: Text(
                      _currentStep < _totalSteps - 1
                          ? 'Continue'
                          : _creatingShifts
                          ? 'Setting up...'
                          : 'Complete Setup',
                      style: const TextStyle(
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
        ],
      ),
    );
  }
}

class _AnimatedStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ColorScheme cs;

  const _AnimatedStepProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.cs,
  });

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
                  color: isActive ? cs.primary : cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isPassed
                      ? Icon(
                          PhosphorIconsBold.check,
                          size: 14,
                          color: cs.onPrimary,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isPassed ? cs.primary : cs.surfaceContainerHigh,
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

  const _AnimatedStepWrapper({
    required this.step,
    required this.currentStep,
    required this.child,
  });

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
  const _StepProfile({
    required this.cs,
    required this.tt,
    required this.companyCtrl,
    required this.addressCtrl,
    required this.contactCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Factory Profile',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Give your workspace an identity.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        ValidatedField(
          controller: companyCtrl,
          label: 'Company Name',
          prefixIcon: PhosphorIconsRegular.buildings,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter your company name' : null,
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

class _StepShifts extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final TimeOfDay generalStart;
  final TimeOfDay generalEnd;
  final TimeOfDay nightStart;
  final TimeOfDay nightEnd;
  final ValueChanged<TimeOfDay> onGeneralStartChanged;
  final ValueChanged<TimeOfDay> onGeneralEndChanged;
  final ValueChanged<TimeOfDay> onNightStartChanged;
  final ValueChanged<TimeOfDay> onNightEndChanged;
  const _StepShifts({
    required this.cs,
    required this.tt,
    required this.generalStart,
    required this.generalEnd,
    required this.nightStart,
    required this.nightEnd,
    required this.onGeneralStartChanged,
    required this.onGeneralEndChanged,
    required this.onNightStartChanged,
    required this.onNightEndChanged,
  });

  @override
  State<_StepShifts> createState() => _StepShiftsState();
}

class _StepShiftsState extends State<_StepShifts> {
  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Shift Timings',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Define when your factory floor operates.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        _ShiftInputCard(
          cs: cs,
          label: 'General Shift',
          start: _formatTime(widget.generalStart),
          end: _formatTime(widget.generalEnd),
          icon: PhosphorIconsDuotone.sun,
          onStartTap: () => _pickTime(
            initial: widget.generalStart,
            onPicked: widget.onGeneralStartChanged,
          ),
          onEndTap: () => _pickTime(
            initial: widget.generalEnd,
            onPicked: widget.onGeneralEndChanged,
          ),
        ),
        const SizedBox(height: 16),
        _ShiftInputCard(
          cs: cs,
          label: 'Night Shift',
          start: _formatTime(widget.nightStart),
          end: _formatTime(widget.nightEnd),
          icon: PhosphorIconsDuotone.moonStars,
          onStartTap: () => _pickTime(
            initial: widget.nightStart,
            onPicked: widget.onNightStartChanged,
          ),
          onEndTap: () => _pickTime(
            initial: widget.nightEnd,
            onPicked: widget.onNightEndChanged,
          ),
        ),
      ],
    );
  }
}

class _ShiftInputCard extends StatelessWidget {
  final ColorScheme cs;
  final String label, start, end;
  final dynamic icon;
  final VoidCallback? onStartTap;
  final VoidCallback? onEndTap;

  const _ShiftInputCard({
    required this.cs,
    required this.label,
    required this.start,
    required this.end,
    required this.icon,
    this.onStartTap,
    this.onEndTap,
  });

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
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PremiumTimePicker(
                  cs: cs,
                  label: 'Start Time',
                  time: start,
                  onTap: onStartTap,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PremiumTimePicker(
                  cs: cs,
                  label: 'End Time',
                  time: end,
                  onTap: onEndTap,
                ),
              ),
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
  final VoidCallback? onTap;
  const _PremiumTimePicker({
    required this.cs,
    required this.label,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.clock,
                  size: 16,
                  color: cs.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPolicies extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final int otTrigger;
  final bool weekOffPaid;
  final ValueChanged<(int, bool)> onChanged;

  const _StepPolicies({
    required this.cs,
    required this.tt,
    required this.otTrigger,
    required this.weekOffPaid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Payroll Rules',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up overtime and calculation rules.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Text(
          'When does Overtime start?',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _PremiumRadioCard(
          cs: cs,
          title: 'After 8 Hours',
          subtitle: 'Standard global industrial rule',
          value: 8,
          groupValue: otTrigger,
          onChanged: (v) => onChanged((v ?? 8, weekOffPaid)),
        ),
        const SizedBox(height: 12),
        _PremiumRadioCard(
          cs: cs,
          title: 'After 9 Hours',
          subtitle: 'Includes 1 hour unpaid break',
          value: 9,
          groupValue: otTrigger,
          onChanged: (v) => onChanged((v ?? 9, weekOffPaid)),
        ),
        const SizedBox(height: 12),
        _PremiumRadioCard(
          cs: cs,
          title: 'No Overtime',
          subtitle: 'Fixed wages only, regardless of hours',
          value: 0,
          groupValue: otTrigger,
          onChanged: (v) => onChanged((v ?? 0, weekOffPaid)),
        ),
        const SizedBox(height: 32),
        Text(
          'Additional Configurations',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _PremiumSwitch(
          cs: cs,
          title: 'Enable Week-Off Pay',
          subtitle: 'Pay workers for Sunday if they work Mon-Sat',
          value: weekOffPaid,
          onChanged: (v) => onChanged((otTrigger, v)),
        ),
      ],
    );
  }
}

class _PremiumSwitch extends StatelessWidget {
  final ColorScheme cs;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PremiumSwitch({
    required this.cs,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: cs.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PremiumRadioCard extends StatelessWidget {
  final ColorScheme cs;
  final String title, subtitle;
  final int value, groupValue;
  final ValueChanged<int?> onChanged;

  const _PremiumRadioCard({
    required this.cs,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              isSelected
                  ? PhosphorIconsFill.radioButton
                  : PhosphorIconsRegular.circle,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final int otTrigger;
  final bool weekOffPaid;
  const _StepReview({
    required this.cs,
    required this.tt,
    required this.companyName,
    required this.addressCtrl,
    required this.contactCtrl,
    required this.otTrigger,
    required this.weekOffPaid,
  });

  @override
  Widget build(BuildContext context) {
    final cName = companyName.text.trim().isEmpty
        ? 'Your Factory'
        : companyName.text.trim();
    final address = addressCtrl.text.trim();
    final contact = contactCtrl.text.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Ready to Launch',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your setup before entering the dashboard.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        _ReviewSummaryCard(
          cs: cs,
          icon: PhosphorIconsDuotone.buildings,
          title: 'Profile',
          items: [
            'Name: $cName',
            if (address.isNotEmpty) 'Address: $address',
            if (contact.isNotEmpty) 'Contact: $contact',
            'Shifts: 2 Active (General, Night)',
          ],
        ),
        const SizedBox(height: 16),
        _ReviewSummaryCard(
          cs: cs,
          icon: PhosphorIconsDuotone.calculator,
          title: 'Payroll Policies',
          items: [
            otTrigger == 0
                ? 'Overtime: Disabled'
                : 'Overtime starts after $otTrigger Hours',
            weekOffPaid ? 'Week-Off Pay Enabled' : 'Week-Off Pay Disabled',
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsDuotone.info, color: cs.tertiary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'All configurations can be changed later in the Settings menu.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
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

  const _ReviewSummaryCard({
    required this.cs,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.checkCircle,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
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
