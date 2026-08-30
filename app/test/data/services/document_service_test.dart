import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/document_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _FakeApiClient(this._response)
    : _error = null,
      super(baseUrl: 'http://localhost');

  _FakeApiClient.error(this._error)
    : _response = {},
      super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> delete(String path) async {
    lastMethod = 'DELETE';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('DocumentService.listDocuments', () {
    test('hits staff/{id}/documents endpoint', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'doc-1',
            'doc_type': 'aadhaar',
            'file_path': '/uploads/aadhaar.pdf',
            'original_name': 'aadhaar.pdf',
          },
        ],
      });
      final svc = DocumentService(client);

      final docs = await svc.listDocuments('emp-1');

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/staff/emp-1/documents');
      expect(docs, hasLength(1));
      expect(docs[0].docType, 'aadhaar');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = DocumentService(client);

      final docs = await svc.listDocuments('emp-1');

      expect(docs, isEmpty);
    });

    test('returns empty list when data key is missing', () async {
      final client = _FakeApiClient({});
      final svc = DocumentService(client);

      final docs = await svc.listDocuments('emp-1');

      expect(docs, isEmpty);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DocumentService(client);

      expect(() => svc.listDocuments('emp-1'), throwsException);
    });
  });

  group('DocumentService.deleteDocument', () {
    test('DELETEs staff/{id}/documents/{type}', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = DocumentService(client);

      await svc.deleteDocument(employeeId: 'emp-1', docType: 'pan');

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/api/v1/staff/emp-1/documents/pan');
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DocumentService(client);

      expect(
        () => svc.deleteDocument(employeeId: 'emp-1', docType: 'aadhaar'),
        throwsException,
      );
    });
  });
}
