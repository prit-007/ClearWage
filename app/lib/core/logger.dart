import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  static Talker? _talker;

  /// Single Talker instance backing the [AppLogger] facade.
  ///
  /// Lazily created on first access so callers (e.g. the log viewer route)
  /// can read it without an explicit init.
  static Talker get talker => _talker ??= _buildTalker();

  static Talker _buildTalker() {
    return TalkerFlutter.init(
      settings: TalkerSettings(
        useHistory: true,
        maxHistoryItems: 500,
        useConsoleLogs: kDebugMode,
      ),
    );
  }

  /// Replaces the backing Talker instance.
  ///
  /// Tests inject a Talker with console output disabled here; a [Talker]
  /// with default settings is built when [talker] is null.
  static void init({Talker? talker}) {
    _talker = talker ?? _buildTalker();
  }

  static void info(String message) => talker.info(message);

  static void warn(String message) => talker.warning(message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    talker.error(message, error, stackTrace);
  }

  static void request(
    String method,
    String path, {
    int? status,
    Duration? duration,
  }) {
    final parts = ['$method $path'];
    if (status != null) parts.add('status=$status');
    if (duration != null) parts.add('duration=${duration.inMilliseconds}ms');
    talker.logCustom(_HttpRequestLog(parts.join(' ')));
  }
}

class _HttpRequestLog extends TalkerLog {
  _HttpRequestLog(super.message);

  @override
  String get key => TalkerKey.httpRequest;

  @override
  AnsiPen get pen => AnsiPen()..xterm(49);
}
