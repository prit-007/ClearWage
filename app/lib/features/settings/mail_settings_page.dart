import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';

class MailSettingsPage extends ConsumerStatefulWidget {
  const MailSettingsPage({super.key});

  @override
  ConsumerState<MailSettingsPage> createState() => _MailSettingsPageState();
}

class _MailSettingsPageState extends ConsumerState<MailSettingsPage> {
  final _keyCtrl = TextEditingController();
  final _senderEmailCtrl = TextEditingController();
  final _senderNameCtrl = TextEditingController();
  final _quotaCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hasTenantKey = false;
  int? _sentToday;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _senderEmailCtrl.dispose();
    _senderNameCtrl.dispose();
    _quotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(settingsServiceProvider).getMailSettings();
      final key = data['brevo_api_key'] as String?;
      _hasTenantKey = key != null && key.isNotEmpty;
      _senderEmailCtrl.text = data['mail_sender_email'] as String? ?? '';
      _senderNameCtrl.text = data['mail_sender_name'] as String? ?? '';
      _quotaCtrl.text = (data['mail_quota_per_day'] as num?)?.toString() ?? '';
      _sentToday = (data['mail_sent_today'] as num?)?.toInt();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, e);
      }
    }
  }

  Future<void> _save() async {
    final quota = int.tryParse(_quotaCtrl.text.trim());
    if (quota == null || quota < 1 || quota > 3000) {
      showError(context, 'Daily quota must be between 1 and 3000');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'brevo_api_key': _keyCtrl.text.trim().isEmpty
            ? null
            : _keyCtrl.text.trim(),
        'mail_sender_email': _senderEmailCtrl.text.trim().isEmpty
            ? null
            : _senderEmailCtrl.text.trim(),
        'mail_sender_name': _senderNameCtrl.text.trim().isEmpty
            ? null
            : _senderNameCtrl.text.trim(),
        'mail_quota_per_day': quota,
      };
      await ref.read(settingsServiceProvider).updateMailSettings(body);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mail settings saved')));
        context.pop();
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

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Email Settings',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: AppScrollPhysics.physics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      PhosphorIconsRegular.envelopeSimple,
                      size: 44,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Transactional email is sent through Brevo. Add your own API key to use your account, or leave blank to use the platform key.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_sentToday != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Sent today: $_sentToday',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _EditorField(
                      controller: _keyCtrl,
                      label: _hasTenantKey
                          ? 'Brevo API Key (replace to update)'
                          : 'Brevo API Key (blank = use platform key)',
                      icon: PhosphorIconsRegular.key,
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                    _EditorField(
                      controller: _senderEmailCtrl,
                      label: 'Sender Email',
                      icon: PhosphorIconsRegular.envelopeSimpleOpen,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _EditorField(
                      controller: _senderNameCtrl,
                      label: 'Sender Name',
                      icon: PhosphorIconsRegular.userCircle,
                    ),
                    const SizedBox(height: 16),
                    _EditorField(
                      controller: _quotaCtrl,
                      label: 'Daily Email Quota',
                      icon: PhosphorIconsRegular.gauge,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(PhosphorIconsFill.envelope),
                      label: Text(
                        _saving ? 'Saving…' : 'Save Settings',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _EditorField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
