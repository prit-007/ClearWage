import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaService {
  static const int targetMaxBytes = 200 * 1024;

  static bool needsCompression(String path) {
    try {
      return File(path).lengthSync() > targetMaxBytes;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> compressImage(String path) async {
    try {
      final file = File(path);
      final target =
          '${file.parent.path}/cw_compress_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        quality: 65,
        minWidth: 1200,
        minHeight: 1200,
      );
      return result?.path;
    } catch (_) {
      return null;
    }
  }
}
