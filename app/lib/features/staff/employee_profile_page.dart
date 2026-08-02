import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';
import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets/bottom_blur_bar.dart';
import 'add_employee_page.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeProfileScreen({super.key, required this.employeeId});
  @override
  ConsumerState<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>>? _attendance;
  List<Map<String, dynamic>>? _ledger;
  double? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) HapticFeedback.selectionClick();
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final svc = ref.read(staffServiceProvider);

    final overview = await _fetch(() => svc.getOverview(widget.employeeId));
    if (overview == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final profile = (overview['profile'] as Map<String, dynamic>?)?.cast<String, dynamic>();
    final ledger = (overview['ledger'] as Map<String, dynamic>?)?.cast<String, dynamic>() ?? {};
    final attendanceData = (overview['attendance'] as Map<String, dynamic>?)?.cast<String, dynamic>() ?? {};
    final attList = ((attendanceData['recent'] as List<dynamic>?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final ledgerList = ((ledger['recent'] as List<dynamic>?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final bal = ((ledger['balance'] as num?)?.toDouble()) ?? 0.0;

    if (mounted) {
      setState(() {
        _profile = profile;
        _attendance = attList;
        _ledger = ledgerList;
        _balance = bal;
        _loading = false;
      });
    }
  }

  Future<T?> _fetch<T>(Future<T> Function() fn) async {
    try { return await fn(); } catch (_) { return null; }
  }

  Future<void> _pickAndUploadPhoto() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.camera, color: Theme.of(context).colorScheme.primary),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.image, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    String? path;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      path = picked?.path;
    } catch (_) {
      if (mounted) showError(context, 'Could not pick photo');
      return;
    }
    if (path == null || !mounted) return;

    try {
      final url = await ref.read(staffServiceProvider).uploadPhoto(widget.employeeId, path);
      if (mounted) {
        setState(() => _profile?['photo_url'] = url);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;

    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: cs.surfaceContainerLowest,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] as String? ?? 'Employee';
    final role = _profile?['role'] as String? ?? '';
    final designation = _profile?['designation'] as String? ?? role;
    final phone = _profile?['phone'] as String? ?? '';
    final initials = getInitials(name);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, _) => [
              SliverAppBar(
                backgroundColor: cs.surfaceContainerLowest,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isAdmin) ...[
                    IconButton(
                      icon: Icon(PhosphorIconsRegular.pencilSimple, color: cs.onSurfaceVariant),
                      onPressed: () async {
                        final emp = _profile;
                        if (emp == null || emp['id'] == null) return;
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEmployeeScreen(
                              employee: Employee.fromJson(emp),
                            ),
                          ),
                        );
                        if (result == true && mounted) _loadProfile();
                      },
                    ),
                    IconButton(
                      icon: Icon(PhosphorIconsRegular.trash, color: cs.error),
                      onPressed: () async {
                        final emp = _profile;
                        if (emp == null || emp['id'] == null) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Delete Employee', style: TextStyle(fontWeight: FontWeight.w800)),
                            content: Text('Permanently deactivate ${emp['name'] ?? 'this employee'}? They will no longer be able to log in.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: cs.error),
                                child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          try {
                            await ref.read(staffServiceProvider).delete(widget.employeeId);
                            ref.invalidate(employeeListProvider);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _EditorialProfileHeader(
                    cs: cs,
                    tt: tt,
                    name: name,
                    initials: initials,
                    designation: designation,
                    phone: phone,
                    photoUrl: resolveMediaUrl(_profile?['photo_url'] as String? ?? '', ref.read(serverUrlProvider)),
                    canEditPhoto: isAdmin,
                    onEditPhoto: _pickAndUploadPhoto,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PremiumTabBarDelegate(
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cs.surface,
                        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurfaceVariant,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Profile'),
                        Tab(text: 'Logs'),
                        Tab(text: 'Ledger'),
                      ],
                    ),
                  ),
                  cs.surfaceContainerLowest,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              physics: const BouncingScrollPhysics(),
              children: [
                _InfoTab(cs: cs, tt: tt, profile: _profile, employeeId: widget.employeeId, canEdit: isAdmin),
                _AttendanceTab(cs: cs, tt: tt, attendanceList: _attendance),
                _LedgerTab(cs: cs, tt: tt, ledgerList: _ledger, balance: _balance),
              ],
            ),
          ),

          if (isAdmin)
            BottomBlurBar(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Settle Account', style: TextStyle(fontWeight: FontWeight.w800)),
                            content: const Text('This will zero out the outstanding balance. This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Settle', style: TextStyle(fontWeight: FontWeight.w700))),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        HapticFeedback.lightImpact();
                        try {
                          await ref.read(ledgerServiceProvider).settleAccount(widget.employeeId);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account settled')));
                          if (mounted) _loadProfile();
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: const Text('F&F Settle', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        try {
                          final now = DateTime.now();
                          final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
                          final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                          final pdf = await ref.read(payrollServiceProvider).generatePayslip(employeeId: widget.employeeId, startDate: start, endDate: end);
                          final dir = await getTemporaryDirectory();
                          final file = File('${dir.path}/payslip_${widget.employeeId}_${start}_$end.pdf');
                          await file.writeAsBytes(pdf);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payslip saved to ${file.path}')));
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Generate Slip', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _EditorialProfileHeader extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String name, initials, designation, phone;
  final String photoUrl;
  final bool canEditPhoto;
  final VoidCallback onEditPhoto;
  const _EditorialProfileHeader({
    required this.cs,
    required this.tt,
    required this.name,
    required this.initials,
    required this.designation,
    required this.phone,
    required this.photoUrl,
    required this.canEditPhoto,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 3),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isNotEmpty
                    ? null
                    : Text(initials, style: tt.headlineMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
              ),
              if (canEditPhoto)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLowest, width: 3),
                      ),
                      child: Icon(PhosphorIconsFill.camera, size: 16, color: cs.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(designation.toUpperCase(), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PremiumTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final Color bgColor;
  _PremiumTabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, _, _) => Container(color: bgColor, child: tabBar);
  @override
  double get maxExtent => 64;
  @override
  double get minExtent => 64;
  @override
  bool shouldRebuild(_) => false;
}

class _InfoTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Map<String, dynamic>? profile;
  final String employeeId;
  final bool canEdit;
  const _InfoTab({required this.cs, required this.tt, this.profile, required this.employeeId, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final wageType = profile?['wage_type'] as String? ?? '';
    final wageAmount = profile?['wage_amount']?.toString() ?? '0';
    final designation = profile?['designation'] as String? ?? profile?['role'] as String? ?? '';
    final manager = profile?['manager_name'] as String? ?? 'Not assigned';
    final shiftName = profile?['shift_name'] as String? ?? 'Not assigned';

    final kyc = <String, String>{
      'PAN Number': profile?['pan_number'] as String? ?? '—',
      'Aadhaar Number': profile?['aadhaar_number'] as String? ?? '—',
      'PF / UAN': profile?['pf_number'] as String? ?? '—',
      'Bank Account': profile?['bank_account_number'] as String? ?? '—',
      'IFSC': profile?['bank_ifsc'] as String? ?? '—',
      'UPI ID': profile?['upi_id'] as String? ?? '—',
      'Emergency Contact': profile?['emergency_contact_name'] as String? ?? '—',
      'Emergency Phone': profile?['emergency_contact_phone'] as String? ?? '—',
      'Current Address': profile?['current_address'] as String? ?? '—',
      'Permanent Address': profile?['permanent_address'] as String? ?? '—',
      'Health Notes': profile?['health_notes'] as String? ?? '—',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Employment Details',
            data: {
              'Designation': designation,
              'Shift': shiftName,
              'Manager': manager,
            }),
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Financial Config',
            data: {
              'Wage Type': wageType == 'daily' ? 'Daily Wage' : wageType == 'monthly' ? 'Monthly' : wageType,
              'Base Rate': '₹$wageAmount${wageType == 'daily' ? ' / day' : ''}',
            }),
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'KYC & Identity',
            data: kyc),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('KYC DOCUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 16),
        _DocumentVault(employeeId: employeeId, canEdit: canEdit),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DocumentVault extends ConsumerStatefulWidget {
  final String employeeId;
  final bool canEdit;
  const _DocumentVault({required this.employeeId, required this.canEdit});

  @override
  ConsumerState<_DocumentVault> createState() => _DocumentVaultState();
}

class _DocumentVaultState extends ConsumerState<_DocumentVault> {
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  String? _error;
  String? _uploadingType;

  static const _types = [
    ('aadhaar', 'Aadhaar Card', PhosphorIconsDuotone.fingerprint),
    ('pan', 'PAN Card', PhosphorIconsDuotone.identificationCard),
    ('bank', 'Bank Passbook', PhosphorIconsDuotone.bank),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await ref.read(documentServiceProvider).listDocuments(widget.employeeId);
      if (mounted) {
        setState(() {
          _docs = docs.map((d) => d.toJson()).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  Map<String, dynamic>? _docFor(String type) {
    for (final d in _docs) {
      if (d['doc_type'] == type) return d;
    }
    return null;
  }

  Future<void> _upload(String type) async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.camera, color: Theme.of(context).colorScheme.primary),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.image, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.filePdf, color: Theme.of(context).colorScheme.primary),
                title: const Text('Upload PDF / File', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    String? path;
    try {
      if (source == 'camera' || source == 'gallery') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1600,
        );
        path = picked?.path;
      } else {
        final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        path = result?.files.single.path;
      }
    } catch (_) {
      if (mounted) showError(context, 'Could not pick file');
      return;
    }
    if (path == null || !mounted) return;

    setState(() => _uploadingType = type);
    try {
      await ref.read(documentServiceProvider).uploadDocument(
            employeeId: widget.employeeId,
            docType: type,
            filePath: path,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
        _load();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  Future<void> _view(Map<String, dynamic> doc) async {
    final url = resolveMediaUrl(doc['file_path'] as String? ?? '', ref.read(serverUrlProvider));
    if (url.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DocumentViewerPage(url: url, isPdf: (doc['original_name'] as String? ?? '').toLowerCase().endsWith('.pdf')),
      ),
    );
  }

  Future<void> _delete(String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Remove this document? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(documentServiceProvider).deleteDocument(employeeId: widget.employeeId, docType: type);
      if (mounted) _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.errorContainer.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(PhosphorIconsFill.warningCircle, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text('Could not load documents', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$_error', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _load,
              icon: const Icon(PhosphorIconsFill.arrowClockwise, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final (type, label, icon) in _types)
          _DocumentCard(
            cs: cs,
            tt: tt,
            type: type,
            label: label,
            icon: icon,
            doc: _docFor(type),
            uploading: _uploadingType == type,
            canEdit: widget.canEdit,
            baseUrl: ref.watch(serverUrlProvider),
            onUpload: () => _upload(type),
            onView: _docFor(type) == null ? null : () => _view(_docFor(type)!),
            onDelete: _docFor(type) == null ? null : () => _delete(type),
          ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String type;
  final String label;
  final Object icon;
  final Map<String, dynamic>? doc;
  final bool uploading;
  final bool canEdit;
  final String baseUrl;
  final VoidCallback onUpload;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const _DocumentCard({
    required this.cs,
    required this.tt,
    required this.type,
    required this.label,
    required this.icon,
    required this.doc,
    required this.uploading,
    required this.canEdit,
    required this.baseUrl,
    required this.onUpload,
    this.onView,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = (doc?['original_name'] as String? ?? '').toLowerCase().endsWith('.pdf');
    final filePath = doc?['file_path'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (doc != null && !isPdf)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolveMediaUrl(filePath, baseUrl),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => PhosphorIcon(icon, size: 28, color: cs.onSurfaceVariant),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(
                isPdf ? PhosphorIconsDuotone.filePdf : icon,
                size: 28,
                color: isPdf ? cs.error : cs.primary,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(
                  doc != null ? 'Uploaded & Verified' : 'Action Required',
                  style: tt.bodySmall?.copyWith(color: doc != null ? const Color(0xFF10B981) : cs.error, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (uploading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else if (doc != null) ...[
            IconButton(onPressed: onView, icon: Icon(PhosphorIconsRegular.eye, color: cs.onSurfaceVariant)),
            if (canEdit) IconButton(onPressed: onDelete, icon: Icon(PhosphorIconsRegular.trash, color: cs.error)),
          ] else if (canEdit)
            FilledButton.tonal(
              onPressed: onUpload,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Upload'),
            ),
        ],
      ),
    );
  }
}

class _DocumentViewerPage extends StatelessWidget {
  final String url;
  final bool isPdf;
  const _DocumentViewerPage({required this.url, required this.isPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isPdf ? 'Document' : 'Document Preview', style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Center(
        child: isPdf
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhosphorIcon(PhosphorIconsDuotone.filePdf, size: 96, color: Colors.white70),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      if (!ok && context.mounted) showError(context, 'Could not open document');
                    },
                    icon: const Icon(PhosphorIconsRegular.arrowSquareOut),
                    label: const Text('Open Document externally', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )
            : InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
      ),
    );
  }
}

class _EditorialInfoBlock extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String title;
  final Map<String, String> data;

  const _EditorialInfoBlock({required this.cs, required this.tt, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i < entries.length - 1 ? 16 : 0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(entries[i].key, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 3,
                            child: Text(entries[i].value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      ],
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

class _AttendanceTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final List<Map<String, dynamic>>? attendanceList;
  const _AttendanceTab({required this.cs, required this.tt, this.attendanceList});

  @override
  Widget build(BuildContext context) {
    final list = attendanceList ?? [];
    final present = list.where((a) => a['status'] == 'present').length;
    final absent = list.where((a) => a['status'] == 'absent').length;
    final halfDay = list.where((a) => a['status'] == 'half_day').length;
    final total = list.isNotEmpty ? list.length : 1;
    final pct = total > 0 ? present / total : 0.0;
    final recent = list.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AttMacroStat(tt: tt, label: 'Present', value: '$present', color: const Color(0xFF10B981)),
            _AttMacroStat(tt: tt, label: 'Absent', value: '$absent', color: const Color(0xFFEF4444)),
            _AttMacroStat(tt: tt, label: 'Half', value: '$halfDay', color: const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 32),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, val, _) => LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
            backgroundColor: cs.surfaceContainerHighest,
            color: const Color(0xFF10B981),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 48),
        Text('RECENT LOGS', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 24),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('No attendance records for this month', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
          )
        else
          ...recent.map((a) => _TimelineRow(cs: cs, status: a['status'] as String? ?? 'present', date: a['date'] as String? ?? '')),
      ],
    );
  }
}

class _AttMacroStat extends StatelessWidget {
  final TextTheme tt;
  final String label, value;
  final Color color;
  const _AttMacroStat({required this.tt, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: tt.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: color, letterSpacing: -2.0, height: 1.0)),
        const SizedBox(height: 8),
        Text(label.toUpperCase(), style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.8), letterSpacing: 0.5)),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ColorScheme cs;
  final String status;
  final String date;

  const _TimelineRow({required this.cs, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'present' => ('Present', const Color(0xFF10B981), PhosphorIconsBold.check),
      'half_day' => ('Half Day', const Color(0xFFF59E0B), PhosphorIconsBold.minus),
      'paid_leave' => ('Paid Leave', const Color(0xFF3B82F6), PhosphorIconsBold.calendar),
      'week_off' => ('Week Off', cs.onSurfaceVariant, PhosphorIconsBold.moon),
      _ => ('Absent', const Color(0xFFEF4444), PhosphorIconsBold.x),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 16),
          Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LedgerTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final List<Map<String, dynamic>>? ledgerList;
  final double? balance;
  const _LedgerTab({required this.cs, required this.tt, this.ledgerList, this.balance});

  @override
  Widget build(BuildContext context) {
    final list = ledgerList ?? [];
    final bal = balance ?? 0;
    final isNegative = bal < 0;
    final balColor = isNegative ? const Color(0xFFEF4444) : cs.primary;
    final recent = list.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text('NET OUTSTANDING', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text('₹${bal.abs().toStringAsFixed(0)}', style: tt.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: balColor, letterSpacing: -2.0)),
        if (isNegative)
          Text('Payable by Employee', style: tt.labelSmall?.copyWith(color: balColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 48),
        Text('RECENT ENTRIES', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 24),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('No ledger entries this month', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
          )
        else
          ...recent.map((e) => _LedgerEntryRow(
                cs: cs,
                isJama: e['type'] == 'jama',
                amount: (e['amount'] as num?)?.toInt() ?? 0,
                date: e['date'] as String? ?? '',
              )),
      ],
    );
  }
}

class _LedgerEntryRow extends StatelessWidget {
  final ColorScheme cs;
  final bool isJama;
  final int amount;
  final String date;

  const _LedgerEntryRow({required this.cs, required this.isJama, required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    final color = isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Icon(isJama ? PhosphorIconsBold.arrowUpRight : PhosphorIconsBold.arrowDownLeft, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isJama ? 'Wage Added' : 'Advance Taken', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text('${isJama ? '+' : '-'}₹$amount', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
