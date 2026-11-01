import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PendingDocument {
  final String employeeId;
  final String docType;
  final String filePath;

  const PendingDocument({
    required this.employeeId,
    required this.docType,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'doc_type': docType,
    'file_path': filePath,
  };

  factory PendingDocument.fromJson(Map<String, dynamic> json) =>
      PendingDocument(
        employeeId: json['employee_id'] as String? ?? '',
        docType: json['doc_type'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
      );
}

class DocumentUploadQueue {
  final String? overrideDir;

  DocumentUploadQueue({this.overrideDir});

  Future<File> _file() async {
    if (overrideDir != null) {
      return File('$overrideDir/pending_uploads.json');
    }
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/pending_uploads.json');
  }

  Future<List<PendingDocument>> pending() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      final list = (jsonDecode(raw) as List<dynamic>? ?? [])
          .map((e) => PendingDocument.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.where((e) => File(e.filePath).existsSync()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> enqueue(PendingDocument item) async {
    final items = await pending();
    items.removeWhere(
      (e) => e.employeeId == item.employeeId && e.docType == item.docType,
    );
    items.add(item);
    await _write(items);
  }

  Future<void> remove(String employeeId, String docType) async {
    final items = await pending();
    items.removeWhere(
      (e) => e.employeeId == employeeId && e.docType == docType,
    );
    await _write(items);
  }

  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }

  Future<void> _write(List<PendingDocument> items) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
