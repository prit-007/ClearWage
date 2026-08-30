import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// Checks for app updates once after login and shows the update dialog.
/// Place this widget in the MainShell to trigger on every authenticated session.
class UpdateChecker extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked && kReleaseMode) {
      _checked = true;
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final updateInfo = await ref.read(updateCheckProvider.future);
      if (updateInfo != null && mounted) {
        // ignore: unawaited_futures
        UpdateDialog.show(
          context,
          current: ref.read(appInfoProvider).valueOrNull?.version ?? '0.0.0',
          newVer: updateInfo.latestVersion,
          downloadUrl: updateInfo.downloadUrl,
          changelog: updateInfo.changelog,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
