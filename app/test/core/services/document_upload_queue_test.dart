import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/document_upload_queue.dart';
import 'package:clearwage/core/services/media_service.dart';

void main() {
  group('MediaService.needsCompression', () {
    test('returns false for small file', () async {
      final f = await File(
        '${Directory.systemTemp.path}/small.bin',
      ).writeAsBytes(List.filled(1024, 1));
      expect(MediaService.needsCompression(f.path), isFalse);
      await f.delete();
    });

    test('returns true for file over 200KB', () async {
      final f = await File(
        '${Directory.systemTemp.path}/big.bin',
      ).writeAsBytes(List.filled(300 * 1024, 1));
      expect(MediaService.needsCompression(f.path), isTrue);
      await f.delete();
    });
  });

  group('DocumentUploadQueue', () {
    late Directory dir;
    late DocumentUploadQueue queue;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('cw_queue');
      queue = DocumentUploadQueue(overrideDir: dir.path);
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test(
      'enqueue persists, dedupes by employee+type, and filters missing files',
      () async {
        final img = await File('${dir.path}/photo.jpg').writeAsBytes([1, 2, 3]);
        await queue.enqueue(
          PendingDocument(
            employeeId: 'e1',
            docType: 'aadhaar',
            filePath: img.path,
          ),
        );
        await queue.enqueue(
          const PendingDocument(
            employeeId: 'e1',
            docType: 'pan',
            filePath: '/missing.jpg',
          ),
        );
        await queue.enqueue(
          PendingDocument(
            employeeId: 'e1',
            docType: 'aadhaar',
            filePath: img.path,
          ),
        );

        final pending = await queue.pending();
        expect(pending, hasLength(1));
        expect(pending.single.docType, 'aadhaar');
      },
    );

    test('remove clears a specific item', () async {
      final img = await File('${dir.path}/photo.jpg').writeAsBytes([1]);
      await queue.enqueue(
        PendingDocument(
          employeeId: 'e1',
          docType: 'aadhaar',
          filePath: img.path,
        ),
      );
      await queue.enqueue(
        PendingDocument(employeeId: 'e1', docType: 'pan', filePath: img.path),
      );
      await queue.remove('e1', 'aadhaar');

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.docType, 'pan');
    });

    test('clear removes the queue file', () async {
      final img = await File('${dir.path}/photo.jpg').writeAsBytes([1]);
      await queue.enqueue(
        PendingDocument(
          employeeId: 'e1',
          docType: 'aadhaar',
          filePath: img.path,
        ),
      );
      await queue.clear();
      expect(await queue.pending(), isEmpty);
    });
  });
}
