import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/employee_document_model.dart';

void main() {
  group('EmployeeDocument', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'doc-1',
        'doc_type': 'aadhaar',
        'file_path': '/uploads/aadhaar.pdf',
        'public_id': 'pub-1',
        'original_name': 'aadhaar_card.pdf',
        'uploaded_at': '2026-08-10T12:00:00.000Z',
      };

      final doc = EmployeeDocument.fromJson(json);

      expect(doc.id, 'doc-1');
      expect(doc.docType, 'aadhaar');
      expect(doc.filePath, '/uploads/aadhaar.pdf');
      expect(doc.publicId, 'pub-1');
      expect(doc.originalName, 'aadhaar_card.pdf');
      expect(doc.uploadedAt, isNotNull);
    });

    test('fromJson handles null/missing optional fields', () {
      final doc = EmployeeDocument.fromJson({
        'id': 'doc-2',
        'doc_type': 'pan',
        'file_path': '/uploads/pan.jpg',
      });

      expect(doc.publicId, isNull);
      expect(doc.originalName, isNull);
      expect(doc.uploadedAt, isNull);
    });

    test('fromJson defaults missing fields to empty strings', () {
      final doc = EmployeeDocument.fromJson(<String, dynamic>{});

      expect(doc.id, '');
      expect(doc.docType, '');
      expect(doc.filePath, '');
    });

    test('isPdf returns true when file_path ends with .pdf', () {
      final doc = EmployeeDocument(
        id: '',
        docType: '',
        filePath: '/uploads/doc.PDF',
      );
      expect(doc.isPdf, true);
    });

    test('isPdf returns true when original_name ends with .pdf', () {
      final doc = EmployeeDocument(
        id: '',
        docType: '',
        filePath: '/uploads/doc.jpg',
        originalName: 'document.pdf',
      );
      expect(doc.isPdf, true);
    });

    test('isPdf returns false for image files', () {
      final doc = EmployeeDocument(
        id: '',
        docType: '',
        filePath: '/uploads/photo.png',
      );
      expect(doc.isPdf, false);
    });

    test('toJson round-trips correctly', () {
      final doc = EmployeeDocument(
        id: 'doc-3',
        docType: 'bank',
        filePath: '/uploads/bank.pdf',
        publicId: 'pub-3',
        originalName: 'bank_passbook.pdf',
        uploadedAt: DateTime(2026, 8, 10),
      );

      final json = doc.toJson();

      expect(json['id'], 'doc-3');
      expect(json['doc_type'], 'bank');
      expect(json['file_path'], '/uploads/bank.pdf');
      expect(json['public_id'], 'pub-3');
      expect(json['original_name'], 'bank_passbook.pdf');
      expect(json['uploaded_at'], isNotNull);
    });

    test('toJson omits null optional fields as null', () {
      final doc = EmployeeDocument(
        id: 'doc-4',
        docType: 'aadhaar',
        filePath: '/uploads/aadhaar.jpg',
      );

      final json = doc.toJson();

      expect(json['public_id'], isNull);
      expect(json['original_name'], isNull);
      expect(json['uploaded_at'], isNull);
    });

    test('fromJson parses uploaded_at as DateTime', () {
      final doc = EmployeeDocument.fromJson({
        'id': 'doc-5',
        'doc_type': 'aadhaar',
        'file_path': '/uploads/aadhaar.jpg',
        'uploaded_at': '2026-01-15T10:30:00.000Z',
      });

      expect(doc.uploadedAt, isA<DateTime>());
      expect(doc.uploadedAt!.year, 2026);
      expect(doc.uploadedAt!.month, 1);
      expect(doc.uploadedAt!.day, 15);
    });
  });
}
