import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../models/employee_document_model.dart';

class DocumentService {
  final ApiClient _client;
  DocumentService(this._client);

  Future<List<EmployeeDocument>> listDocuments(String employeeId) async {
    final res = await _client.get('/api/v1/staff/$employeeId/documents');
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => EmployeeDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required String docType,
    required String filePath,
  }) async {
    final file = await http.MultipartFile.fromPath('file', filePath);
    final res = await _client.postMultipart(
      '/api/v1/staff/$employeeId/documents/$docType',
      files: [file],
    );
    return EmployeeDocument.fromJson(
      res['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<void> deleteDocument({
    required String employeeId,
    required String docType,
  }) async {
    await _client.delete('/api/v1/staff/$employeeId/documents/$docType');
  }
}
