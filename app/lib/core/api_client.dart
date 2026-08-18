import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';
import 'logger.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 30);
  String? _token;
  Future<void> Function()? onUnauthorized;
  Completer<void>? _refreshLock;

  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  void setToken(String? token) => _token = token;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _request('GET', path, () => _client.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _request(
      'POST',
      path,
      () => _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _request(
      'PUT',
      path,
      () => _client.put(uri, headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<List<int>> getRaw(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final sw = Stopwatch()..start();
    try {
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      sw.stop();
      AppLogger.request(
        'GET',
        path,
        status: res.statusCode,
        duration: sw.elapsed,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
      Map<String, dynamic> json;
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(
          'Invalid response from server',
          statusCode: res.statusCode,
        );
      }
      final msg = json['message'] as String? ?? 'Unknown error';
      throw ApiException(msg, statusCode: res.statusCode);
    } catch (e, st) {
      sw.stop();
      if (e is! ApiException) AppLogger.error('GET $path (raw) failed', e, st);
      rethrow;
    }
  }

  Future<List<int>> postRaw(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final sw = Stopwatch()..start();
    try {
      final res = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      sw.stop();
      AppLogger.request(
        'POST',
        path,
        status: res.statusCode,
        duration: sw.elapsed,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
      Map<String, dynamic> json;
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(
          'Invalid response from server',
          statusCode: res.statusCode,
        );
      }
      final msg = json['message'] as String? ?? 'Unknown error';
      throw ApiException(msg, statusCode: res.statusCode);
    } catch (e, st) {
      sw.stop();
      if (e is! ApiException) AppLogger.error('POST $path (raw) failed', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _request(
      'DELETE',
      path,
      () => _client.delete(uri, headers: _headers),
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    if (_token != null) {
      req.headers['Authorization'] = 'Bearer $_token';
    }
    if (fields != null) req.fields.addAll(fields);
    req.files.addAll(files);
    final sw = Stopwatch()..start();
    try {
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      sw.stop();
      AppLogger.request(
        'POST',
        path,
        status: res.statusCode,
        duration: sw.elapsed,
      );
      return await _handle(res);
    } catch (e, st) {
      sw.stop();
      AppLogger.error('POST $path (multipart) failed', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _handle(http.Response response) async {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      throw ApiException(
        'Invalid response from server',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    final msg = json['message'] as String? ?? 'Unknown error';
    if (response.statusCode == 401) {
      _token = null;
      if (_refreshLock != null) {
        await _refreshLock!.future;
      } else {
        _refreshLock = Completer<void>();
        try {
          await onUnauthorized?.call();
        } finally {
          _refreshLock!.complete();
          _refreshLock = null;
        }
      }
      throw AuthException(msg);
    }
    throw ApiException(msg, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    Future<http.Response> Function() fn,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final res = await fn().timeout(_timeout);
      sw.stop();
      AppLogger.request(
        method,
        path,
        status: res.statusCode,
        duration: sw.elapsed,
      );
      return await _handle(res);
    } catch (e, st) {
      sw.stop();
      AppLogger.error('$method $path failed', e, st);
      rethrow;
    }
  }
}
