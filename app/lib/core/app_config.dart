import 'package:flutter_riverpod/flutter_riverpod.dart';

String _defaultBaseUrl() => 'https://work-force-nckb.onrender.com';

final serverUrlProvider = StateProvider<String>((_) => _defaultBaseUrl());

