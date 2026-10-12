import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PendingSyncItem {
  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final int createdAt;

  const PendingSyncItem({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'payload': payload,
    'created_at': createdAt,
  };

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) =>
      PendingSyncItem(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        payload: (json['payload'] as Map<String, dynamic>? ?? {}),
        createdAt: json['created_at'] as int? ?? 0,
      );
}

class PendingSyncStore {
  final String? overrideDir;

  PendingSyncStore({this.overrideDir});

  Future<File> _file() async {
    if (overrideDir != null) return File('$overrideDir/pending_sync.json');
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/pending_sync.json');
  }

  Future<List<PendingSyncItem>> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      return ((jsonDecode(raw) as List<dynamic>?) ?? [])
          .map((e) => PendingSyncItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> append(PendingSyncItem item) async {
    final items = await read();
    items.add(item);
    await _write(items);
  }

  Future<void> remove(String id) async {
    final items = await read();
    items.removeWhere((e) => e.id == id);
    await _write(items);
  }

  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }

  Future<void> _write(List<PendingSyncItem> items) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
