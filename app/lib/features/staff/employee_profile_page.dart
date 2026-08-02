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

String _resolveMediaUrl(String url, String baseUrl) {
  if (url.isEmpty) return url;
  final u = Uri.tryParse(url);
  if (u != null && u.hasScheme) return url;
  return '$baseUrl$url';
}

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeProfileScreen(
      {super.key, required this.employeeId});
  @override
  ConsumerState<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState
    extends ConsumerState<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
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
    final now = DateTime.now();
    final start = '${now.year}-01-01';
    final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final svc = ref.read(staffServiceProvider);
    final attSvc = ref.read(attendanceServiceProvider);
    final ledgerSvc = ref.read(ledgerServiceProvider);

    final dataF = _fetch(() => svc.getProfile(widget.employeeId));
    final empF = _fetch(() => svc.get(widget.employeeId).then((e) => e.toJson()));
    final attF = _fetch(() => attSvc.listByEmployee(widget.employeeId, startDate: start, endDate: end).then((l) => l.map((a) => a.toJson()).toList()));
    final ledF = _fetch(() => ledgerSvc.listByEmployee(widget.employeeId, startDate: start, endDate: end).then((l) => l.map((e) => e.toJson()).toList()));
    final balF = _fetch(() => ledgerSvc.getBalance(widget.employeeId));

    final data = await dataF;
    final empJson = await empF;
    if (empJson == null && data == null) { if (mounted) setState(() => _loading = false); return; }
    final attList = await attF ?? [];
    final ledgerList = await ledF ?? [];
    final bal = await balF ?? 0.0;

    var profile = data ?? empJson;
    if (data != null && empJson != null) profile = {...data, ...empJson};

    if (profile?['shift_name'] == null && profile?['default_shift_id'] != null) {
      try {
        final shift = await ref.read(shiftServiceProvider).get(profile!['default_shift_id'].toString());
        profile['shift_name'] = shift.name;
      } catch (_) {}
    }

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

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  icon: Icon(PhosphorIconsRegular.arrowLeft,
                      color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (ref.watch(userInfoProvider)?.isAdmin ?? false) ...[
                    IconButton(
                      icon: Icon(PhosphorIconsRegular.pencilSimple,
                          color: cs.onSurfaceVariant),
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
                      icon: Icon(PhosphorIconsRegular.trash,
                          color: cs.error),
                      onPressed: () async {
                        final emp = _profile;
                        if (emp == null || emp['id'] == null) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Employee'),
                            content: Text('Permanently deactivate ${emp['name'] ?? 'this employee'}? They will no longer be able to log in.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: cs.error),
                                child: const Text('Delete'),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  child: _EditorialProfileHeader(cs: cs, tt: tt, name: name, initials: initials, designation: designation, phone: phone),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PremiumTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: cs.primaryContainer,
                    ),
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(24),
                    tabs: const [
                      Tab(text: 'Info & KYC'),
                      Tab(text: 'Attendance'),
                      Tab(text: 'Ledger'),
                    ],
                  ),
                  cs.surfaceContainerLowest,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              physics: const BouncingScrollPhysics(),
              children: [
                _InfoTab(cs: cs, tt: tt, profile: _profile, employeeId: widget.employeeId, canEdit: ref.watch(userInfoProvider)?.isAdmin ?? false),
                _AttendanceTab(cs: cs, tt: tt, attendanceList: _attendance),
                _LedgerTab(cs: cs, tt: tt, ledgerList: _ledger, balance: _balance),
              ],
            ),
          ),
          BottomBlurBar(
            child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Settle Account'),
                                content: const Text('This will zero out the outstanding balance. This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Settle')),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            side: BorderSide(
                                color: cs.outlineVariant),
                          ),
                          child: const Text('F&F Settle',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          child: const Text('Generate Slip',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
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
  const _EditorialProfileHeader({
    required this.cs, required this.tt,
    required this.name, required this.initials,
    required this.designation, required this.phone,
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
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 2)),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: cs.primaryContainer,
            child: Text(initials,
                style: tt.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Text(name,
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(designation,
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PremiumTabBarDelegate
    extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _PremiumTabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, _, _) => Container(
        color: bgColor,
        padding: const EdgeInsets.only(bottom: 8),
        child: tabBar,
      );
  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
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
          child: Text('KYC DOCUMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
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
  String? _uploadingType;

  static const _types = [
    ('aadhaar', 'Aadhaar Card', 'fingerprint'),
    ('pan', 'PAN Card', 'identificationCard'),
    ('bank', 'Bank Passbook', 'bank'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await ref.read(documentServiceProvider).listDocuments(widget.employeeId);
      if (mounted) {
        setState(() {
          _docs = docs.map((d) => d.toJson()).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Capture with Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Upload PDF / File'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
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
    final url = _resolveMediaUrl(doc['file_path'] as String? ?? '', ref.read(serverUrlProvider));
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
        title: const Text('Delete document'),
        content: const Text('Remove this document? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
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
  final String icon;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (doc != null && !isPdf)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _resolveMediaUrl(filePath, baseUrl),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(_iconFor(icon), size: 28, color: cs.onSurfaceVariant),
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
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : _iconFor(icon),
                size: 28,
                color: isPdf ? cs.error : cs.primary,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  doc != null ? 'Uploaded' : 'Not uploaded yet',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (uploading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else if (doc != null) ...[
            IconButton(onPressed: onView, icon: Icon(Icons.visibility_outlined, color: cs.onSurfaceVariant)),
            if (canEdit) IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline_rounded, color: cs.error)),
          ] else if (canEdit)
            FilledButton.tonal(onPressed: onUpload, child: const Text('Upload')),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'fingerprint':
        return Icons.fingerprint_rounded;
      case 'identificationCard':
        return Icons.badge_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }
}

class _DocumentViewerPage extends StatelessWidget {
  final String url;
  final bool isPdf;
  const _DocumentViewerPage({required this.url, required this.isPdf});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isPdf ? 'Document' : 'Document Preview'),
      ),
      body: Center(
        child: isPdf
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 96, color: Colors.white70),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      if (!ok && context.mounted) showError(context, 'Could not open document');
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open document'),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(url,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
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

  const _EditorialInfoBlock(
      {required this.cs,
      required this.tt,
      required this.title,
      required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? 16 : 0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(entries[i].key,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                        Expanded(
                            flex: 3,
                            child: Text(entries[i].value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14))),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AttMacroStat(
                tt: tt,
                label: 'Present',
                value: '$present',
                color: const Color(0xFF10B981)),
            _AttMacroStat(
                tt: tt,
                label: 'Absent',
                value: '$absent',
                color: const Color(0xFFEF4444)),
            _AttMacroStat(
                tt: tt,
                label: 'Half',
                value: '$halfDay',
                color: const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, val, _) => LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
            backgroundColor: cs.surfaceContainerHighest,
            color: const Color(0xFF10B981),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 32),
        Text('RECENT LOGS',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Text('No attendance records', style: TextStyle(color: cs.onSurfaceVariant))
        else
          ...recent.map((a) => _TimelineRow(
              cs: cs,
              isPresent: a['status'] == 'present',
              date: a['date'] as String? ?? '')),
      ],
    );
  }
}

class _AttMacroStat extends StatelessWidget {
  final TextTheme tt;
  final String label, value;
  final Color color;
  const _AttMacroStat(
      {required this.tt,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: tt.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1.0,
                height: 1.0)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ColorScheme cs;
  final bool isPresent;
  final String date;

  const _TimelineRow(
      {required this.cs,
      required this.isPresent,
      required this.date});

  @override
  Widget build(BuildContext context) {
    final color = isPresent
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(
                isPresent
                    ? PhosphorIconsBold.check
                    : PhosphorIconsBold.x,
                size: 14,
                color: color),
          ),
          const SizedBox(width: 16),
          Text(date,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700)),
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
    final recent = list.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text('NET OUTSTANDING',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text('₹${bal.toStringAsFixed(0)}',
            style: tt.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.primary,
                letterSpacing: -1.5)),
        const SizedBox(height: 32),
        Text('RECENT ENTRIES',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Text('No ledger entries', style: TextStyle(color: cs.onSurfaceVariant))
        else
          ...recent.map((e) => _LedgerEntryRow(
              cs: cs,
              isJama: e['type'] == 'jama',
              amount: (e['amount'] as num?)?.toInt() ?? 0,
              date: e['date'] as String? ?? '')),
      ],
    );
  }
}

class _LedgerEntryRow extends StatelessWidget {
  final ColorScheme cs;
  final bool isJama;
  final int amount;
  final String date;

  const _LedgerEntryRow(
      {required this.cs,
      required this.isJama,
      required this.amount,
      required this.date});

  @override
  Widget build(BuildContext context) {
    final color = isJama
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                isJama
                    ? PhosphorIconsFill.arrowUpRight
                    : PhosphorIconsFill.arrowDownLeft,
                size: 16,
                color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  isJama
                      ? 'Wage Added'
                      : 'Advance Taken',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(date,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text('${isJama ? '+' : '-'}₹$amount',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
