import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app_info.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String body;
  final List<String> changelog;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.body,
    required this.changelog,
  });
}

class UpdateService {
  static const _githubOwner = 'prit-007';
  static const _githubRepo = 'vivek-app';

  http.Client? _httpClient;

  UpdateService({http.Client? client}) : _httpClient = client;

  http.Client get client => _httpClient ??= http.Client();

  /// Checks GitHub releases for a newer version.
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
      );
      final response = await client.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');

      if (!_isNewer(latestVersion, currentVersion)) return null;

      final body = data['body'] as String? ?? '';
      final changelog = _parseChangelog(body);

      String downloadUrl = '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      if (downloadUrl.isEmpty) return null;

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        body: body,
        changelog: changelog,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compares two semantic version strings.
  /// Returns true if [latest] is newer than [current].
  bool _isNewer(String latest, String current) {
    final latestParts = latest
        .split('.')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final currentParts = current
        .split('.')
        .map(int.tryParse)
        .whereType<int>()
        .toList();

    for (var i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Parses a markdown changelog body into clean bullet points.
  List<String> _parseChangelog(String body) {
    final lines = <String>[];
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        lines.add(trimmed.substring(2).trim());
      } else if (trimmed.startsWith('###')) {
        // Section header — add as a bold item
        final header = trimmed.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        if (header.isNotEmpty) lines.add(header);
      }
    }
    return lines.isEmpty ? ['Bug fixes and improvements'] : lines;
  }
}

/// Provider for the update service.
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// Provider that checks for updates on app launch.
/// Returns [UpdateInfo] if an update is available, null otherwise.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  try {
    final service = ref.watch(updateServiceProvider);
    final appInfo = await ref.watch(appInfoProvider.future);
    return service.checkForUpdate(appInfo.version);
  } catch (_) {
    return null;
  }
});
