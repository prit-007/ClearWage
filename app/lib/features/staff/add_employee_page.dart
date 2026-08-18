import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import 'providers/staff_providers.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/shift_model.dart';
import '../../core/app_config.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/validated_field.dart';
import '../../core/helpers.dart';
import '../../core/responsive.dart';
import 'dart:async';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employee;
  const AddEmployeeScreen({super.key, this.employee});
  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  final _dojCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _pfCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _currentAddrCtrl = TextEditingController();
  final _permAddrCtrl = TextEditingController();
  late String _wageType;
  late String _role;
  bool _saving = false;
  String? _photoPath;
  List<Shift> _shifts = [];
  String? _shiftsError;
  String? _selectedShiftId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadShifts();
    final e = widget.employee;
    if (e != null) {
      _nameCtrl.text = e.name;
      _phoneCtrl.text = e.phone;
      _desigCtrl.text = e.designation ?? '';
      _wageCtrl.text = e.wageAmount == 0 ? '' : e.wageAmount.toStringAsFixed(0);
      _dojCtrl.text = e.dateOfJoining ?? '';
      _panCtrl.text = e.panNumber ?? '';
      _aadhaarCtrl.text = e.aadhaarNumber ?? '';
      _pfCtrl.text = e.pfNumber ?? '';
      _bankCtrl.text = e.bankAccountNumber ?? '';
      _ifscCtrl.text = e.bankIfsc ?? '';
      _upiCtrl.text = e.upiId ?? '';
      _emergencyNameCtrl.text = e.emergencyContactName ?? '';
      _emergencyPhoneCtrl.text = e.emergencyContactPhone ?? '';
      _healthCtrl.text = e.healthNotes ?? '';
      _currentAddrCtrl.text = e.currentAddress ?? '';
      _permAddrCtrl.text = e.permanentAddress ?? '';
      _wageType = e.wageType.isEmpty ? 'daily' : e.wageType;
      _role = e.role;
      _selectedShiftId = e.defaultShiftId;
    } else {
      _wageType = 'daily';
      _role = 'employee';
    }
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await ref.read(shiftServiceProvider).list();
      if (mounted) {
        setState(() {
          _shifts = shifts;
          _shiftsError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _shiftsError = '$e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _desigCtrl.dispose();
    _wageCtrl.dispose();
    _dojCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _pfCtrl.dispose();
    _bankCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _healthCtrl.dispose();
    _currentAddrCtrl.dispose();
    _permAddrCtrl.dispose();
    super.dispose();
  }

  String? _validateAll() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final wage = _wageCtrl.text.trim();
    if (name.isEmpty) return 'Employee name is required';
    if (phone.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10,15}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }
    if (wage.isEmpty) return 'Wage amount is required';
    final wageVal = double.tryParse(wage);
    if (wageVal == null || wageVal <= 0) return 'Wage must be a valid number';
    return null;
  }

  Future<void> _pickPhoto() async {
    unawaited(HapticFeedback.selectionClick());
    final source = await showAdaptiveSheet<String>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsDuotone.camera,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Capture with Camera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsDuotone.image,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked != null && mounted) setState(() => _photoPath = picked.path);
    } catch (_) {
      if (mounted) showError(context, 'Could not pick photo');
    }
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final error = _validateAll();
    if (!formValid || error != null) {
      unawaited(HapticFeedback.vibrate());
      if (mounted && error != null) showError(context, error);
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _saving = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'designation': _desigCtrl.text.trim().isEmpty
            ? null
            : _desigCtrl.text.trim(),
        'wage_type': _wageType,
        'wage_amount': _wageCtrl.text.trim(),
        'role': _role,
        'default_shift_id': _selectedShiftId,
        'date_of_joining': _dojCtrl.text.trim().isEmpty
            ? null
            : _dojCtrl.text.trim(),
        'pan_number': _panCtrl.text.trim().isEmpty
            ? null
            : _panCtrl.text.trim(),
        'aadhaar_number': _aadhaarCtrl.text.trim().isEmpty
            ? null
            : _aadhaarCtrl.text.trim(),
        'pf_number': _pfCtrl.text.trim().isEmpty ? null : _pfCtrl.text.trim(),
        'bank_account_number': _bankCtrl.text.trim().isEmpty
            ? null
            : _bankCtrl.text.trim(),
        'bank_ifsc': _ifscCtrl.text.trim().isEmpty
            ? null
            : _ifscCtrl.text.trim(),
        'upi_id': _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        'emergency_contact_name': _emergencyNameCtrl.text.trim().isEmpty
            ? null
            : _emergencyNameCtrl.text.trim(),
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim().isEmpty
            ? null
            : _emergencyPhoneCtrl.text.trim(),
        'health_notes': _healthCtrl.text.trim().isEmpty
            ? null
            : _healthCtrl.text.trim(),
        'current_address': _currentAddrCtrl.text.trim().isEmpty
            ? null
            : _currentAddrCtrl.text.trim(),
        'permanent_address': _permAddrCtrl.text.trim().isEmpty
            ? null
            : _permAddrCtrl.text.trim(),
      };
      final e = widget.employee;
      String? savedId;
      if (e != null) {
        await ref.read(staffServiceProvider).update(e.id, body);
        savedId = e.id;
      } else {
        final created = await ref.read(staffServiceProvider).create(body);
        savedId = created.id;
      }
      if (_photoPath != null) {
        try {
          await ref
              .read(staffServiceProvider)
              .uploadPhoto(savedId, _photoPath!);
        } catch (photoError) {
          if (mounted) {
            showError(
              context,
              'Employee saved but photo upload failed. ${friendlyError(photoError)}',
            );
          }
        }
      }
      ref.invalidate(employeeListProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateWage(String type) {
    HapticFeedback.selectionClick();
    setState(() => _wageType = type);
  }

  bool get _hasUnsavedChanges {
    bool differs(String? current, String? original) =>
        current != (original ?? '');
    final e = widget.employee;
    if (e == null) {
      return _nameCtrl.text.isNotEmpty ||
          _phoneCtrl.text.isNotEmpty ||
          _desigCtrl.text.isNotEmpty ||
          _wageCtrl.text.isNotEmpty ||
          _photoPath != null ||
          _selectedShiftId != null ||
          _dojCtrl.text.isNotEmpty ||
          _panCtrl.text.isNotEmpty ||
          _aadhaarCtrl.text.isNotEmpty ||
          _pfCtrl.text.isNotEmpty ||
          _bankCtrl.text.isNotEmpty ||
          _ifscCtrl.text.isNotEmpty ||
          _upiCtrl.text.isNotEmpty ||
          _emergencyNameCtrl.text.isNotEmpty ||
          _emergencyPhoneCtrl.text.isNotEmpty ||
          _healthCtrl.text.isNotEmpty ||
          _currentAddrCtrl.text.isNotEmpty ||
          _permAddrCtrl.text.isNotEmpty;
    }
    return differs(_nameCtrl.text, e.name) ||
        differs(_phoneCtrl.text, e.phone) ||
        differs(_desigCtrl.text, e.designation) ||
        differs(
          _wageCtrl.text,
          e.wageAmount == 0 ? '' : e.wageAmount.toStringAsFixed(0),
        ) ||
        _photoPath != null ||
        _selectedShiftId != e.defaultShiftId ||
        _wageType != e.wageType ||
        differs(_dojCtrl.text, e.dateOfJoining) ||
        differs(_panCtrl.text, e.panNumber) ||
        differs(_aadhaarCtrl.text, e.aadhaarNumber) ||
        differs(_pfCtrl.text, e.pfNumber) ||
        differs(_bankCtrl.text, e.bankAccountNumber) ||
        differs(_ifscCtrl.text, e.bankIfsc) ||
        differs(_upiCtrl.text, e.upiId) ||
        differs(_emergencyNameCtrl.text, e.emergencyContactName) ||
        differs(_emergencyPhoneCtrl.text, e.emergencyContactPhone) ||
        differs(_healthCtrl.text, e.healthNotes) ||
        differs(_currentAddrCtrl.text, e.currentAddress) ||
        differs(_permAddrCtrl.text, e.permanentAddress);
  }

  Future<void> _onBackPressed() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes. Leave anyway?',
      confirmLabel: 'Leave',
      icon: PhosphorIconsRegular.warningCircle,
      isDestructive: true,
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  Future<void> _pickDoj() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dojCtrl.text.isNotEmpty
          ? (DateTime.tryParse(_dojCtrl.text) ?? now)
          : now,
      firstDate: DateTime(1990),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(
        () => _dojCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: cs.surfaceContainerLowest,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
            onPressed: _onBackPressed,
          ),
          title: Text(
            widget.employee != null ? 'Edit Profile' : 'Onboard Staff',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                physics: AppScrollPhysics.physics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                children: [
                  FluidSlideIn(
                    delay: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.2),
                                  width: 4,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: cs.primaryContainer.withValues(
                                  alpha: 0.4,
                                ),
                                backgroundImage: _photoPath != null
                                    ? FileImage(File(_photoPath!))
                                    : ((widget.employee?.photoUrl?.isNotEmpty ??
                                              false)
                                          ? NetworkImage(
                                              resolveMediaUrl(
                                                widget.employee!.photoUrl!,
                                                ref.read(serverUrlProvider),
                                              ),
                                            )
                                          : null),
                                child:
                                    (_photoPath == null &&
                                        !(widget
                                                .employee
                                                ?.photoUrl
                                                ?.isNotEmpty ??
                                            false))
                                    ? PhosphorIcon(
                                        PhosphorIconsDuotone.userPlus,
                                        size: 48,
                                        color: cs.primary,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cs.surfaceContainerLowest,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIconsFill.camera,
                                  size: 18,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  FluidSlideIn(
                    delay: 100,
                    child: Text(
                      'CORE IDENTITY',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FluidSlideIn(
                    delay: 150,
                    child: ValidatedField(
                      controller: _nameCtrl,
                      label: 'Full Name *',
                      prefixIcon: PhosphorIconsDuotone.user,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter employee name'
                          : null,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 200,
                    child: ValidatedField(
                      controller: _phoneCtrl,
                      label: 'Phone Number *',
                      prefixIcon: PhosphorIconsDuotone.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final p = v?.trim() ?? '';
                        if (p.isEmpty) return 'Phone number is required';
                        if (!RegExp(r'^\d{10,15}$').hasMatch(p)) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  FluidSlideIn(
                    delay: 250,
                    child: ValidatedField(
                      controller: _desigCtrl,
                      label: 'Designation / Title (Optional)',
                      prefixIcon: PhosphorIconsDuotone.briefcase,
                    ),
                  ),

                  const SizedBox(height: 32),

                  FluidSlideIn(
                    delay: 300,
                    child: Text(
                      'COMPENSATION & ROLE',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FluidSlideIn(
                    delay: 350,
                    child: Row(
                      children: [
                        _TactileWageCard(
                          cs: cs,
                          label: 'Daily Wage',
                          icon: PhosphorIconsFill.sun,
                          isSelected: _wageType == 'daily',
                          onTap: () => _updateWage('daily'),
                        ),
                        const SizedBox(width: 16),
                        _TactileWageCard(
                          cs: cs,
                          label: 'Fixed Monthly',
                          icon: PhosphorIconsFill.calendarBlank,
                          isSelected: _wageType == 'monthly',
                          onTap: () => _updateWage('monthly'),
                        ),
                        const SizedBox(width: 16),
                        _TactileWageCard(
                          cs: cs,
                          label: 'Hourly',
                          icon: PhosphorIconsFill.clock,
                          isSelected: _wageType == 'hourly',
                          onTap: () => _updateWage('hourly'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FluidSlideIn(
                    delay: 400,
                    child: ValidatedField(
                      controller: _wageCtrl,
                      label: 'Wage Amount (₹) *',
                      prefixIcon: PhosphorIconsDuotone.coins,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Wage amount is required';
                        }
                        final amt = double.tryParse(v.trim());
                        if (amt == null || amt <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  FluidSlideIn(
                    delay: 450,
                    child: _ShiftSelector(
                      shifts: _shifts,
                      selectedId: _selectedShiftId,
                      error: _shiftsError,
                      onRetry: _loadShifts,
                      onChanged: (id) => setState(() => _selectedShiftId = id),
                    ),
                  ),
                  if ((ref.watch(userInfoProvider)?.isAdmin ?? false) &&
                      _role != 'owner') ...[
                    const SizedBox(height: 24),
                    FluidSlideIn(
                      delay: 500,
                      child: _RoleSelector(
                        role: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  FluidSlideIn(
                    delay: 550,
                    child: Text(
                      'KYC & FINANCIAL',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FluidSlideIn(
                    delay: 600,
                    child: ValidatedField(
                      controller: _dojCtrl,
                      label: 'Date of Joining (Optional)',
                      prefixIcon: PhosphorIconsDuotone.calendarPlus,
                      readOnly: true,
                      hint: 'Tap to select date',
                      onTap: _pickDoj,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 650,
                    child: ValidatedField(
                      controller: _panCtrl,
                      label: 'PAN Number (Optional)',
                      prefixIcon: PhosphorIconsDuotone.identificationCard,
                      validator: (v) {
                        final p = v?.trim() ?? '';
                        if (p.isEmpty) return null;
                        if (!RegExp(
                          r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                        ).hasMatch(p.toUpperCase())) {
                          return 'Enter a valid PAN (e.g. ABCDE1234F)';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        if (v.length == 10 &&
                            RegExp(
                              r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$',
                            ).hasMatch(v)) {
                          _panCtrl.text = v.toUpperCase();
                        }
                      },
                    ),
                  ),
                  FluidSlideIn(
                    delay: 700,
                    child: ValidatedField(
                      controller: _aadhaarCtrl,
                      label: 'Aadhaar Number (Optional)',
                      prefixIcon: PhosphorIconsDuotone.fingerprint,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final a = v?.trim() ?? '';
                        if (a.isEmpty) return null;
                        if (!RegExp(r'^\d{12}$').hasMatch(a)) {
                          return 'Aadhaar must be exactly 12 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  FluidSlideIn(
                    delay: 750,
                    child: ValidatedField(
                      controller: _pfCtrl,
                      label: 'PF / UAN Number (Optional)',
                      prefixIcon: PhosphorIconsDuotone.shieldCheck,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 800,
                    child: ValidatedField(
                      controller: _bankCtrl,
                      label: 'Bank Account Number (Optional)',
                      prefixIcon: PhosphorIconsDuotone.bank,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 850,
                    child: ValidatedField(
                      controller: _ifscCtrl,
                      label: 'Bank IFSC (Optional)',
                      prefixIcon: PhosphorIconsDuotone.buildings,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 900,
                    child: ValidatedField(
                      controller: _upiCtrl,
                      label: 'UPI ID (Optional)',
                      prefixIcon: PhosphorIconsDuotone.qrCode,
                    ),
                  ),

                  const SizedBox(height: 48),

                  FluidSlideIn(
                    delay: 950,
                    child: Text(
                      'EMERGENCY & ADDRESS',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FluidSlideIn(
                    delay: 1000,
                    child: ValidatedField(
                      controller: _emergencyNameCtrl,
                      label: 'Emergency Contact Name (Optional)',
                      prefixIcon: PhosphorIconsDuotone.userFocus,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 1050,
                    child: ValidatedField(
                      controller: _emergencyPhoneCtrl,
                      label: 'Emergency Contact Phone (Optional)',
                      prefixIcon: PhosphorIconsDuotone.phoneCall,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 1100,
                    child: ValidatedField(
                      controller: _currentAddrCtrl,
                      label: 'Current Address (Optional)',
                      prefixIcon: PhosphorIconsDuotone.house,
                      maxLines: 2,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 1150,
                    child: ValidatedField(
                      controller: _permAddrCtrl,
                      label: 'Permanent Address (Optional)',
                      prefixIcon: PhosphorIconsDuotone.mapPin,
                      maxLines: 2,
                    ),
                  ),
                  FluidSlideIn(
                    delay: 1200,
                    child: ValidatedField(
                      controller: _healthCtrl,
                      label: 'Health Notes (Optional)',
                      prefixIcon: PhosphorIconsDuotone.firstAid,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.8),
                      border: Border(
                        top: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
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
                          : Text(
                              widget.employee != null
                                  ? 'Update Profile'
                                  : 'Onboard Employee',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
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

class _TactileWageCard extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TactileWageCard({
    required this.cs,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primaryContainer.withValues(alpha: 0.5)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftSelector extends StatelessWidget {
  final List<Shift> shifts;
  final String? selectedId;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<String?> onChanged;

  const _ShiftSelector({
    required this.shifts,
    required this.selectedId,
    this.error,
    this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Shift (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.warningCircle,
                  size: 18,
                  color: cs.error,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Could not load shifts',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ] else
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedId,
                isExpanded: true,
                icon: Icon(
                  PhosphorIconsRegular.caretDown,
                  color: cs.onSurfaceVariant,
                ),
                hint: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsDuotone.clock,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Assign Shift',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsDuotone.xCircle,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'No shift assigned',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...shifts.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIconsDuotone.clock,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${formatTime(s.startTime)}-${formatTime(s.endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Access Level',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: role,
              isExpanded: true,
              icon: Icon(
                PhosphorIconsRegular.caretDown,
                color: cs.onSurfaceVariant,
              ),
              items: [
                DropdownMenuItem(
                  value: 'employee',
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.user,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Standard Employee',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'supervisor',
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.shieldStar,
                        size: 20,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Manager / Supervisor',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
