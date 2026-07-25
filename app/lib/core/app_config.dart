import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

String _defaultBaseUrl() {
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
  } catch (_) {}
  return 'http://127.0.0.1:8081';
}

final serverUrlProvider = StateProvider<String>((_) => _defaultBaseUrl());

