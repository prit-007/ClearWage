import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';

class ApiClient {
  final String baseUrl;
  static const _timeout = Duration(seconds: 30);
  String? _token;
  Future<void> Function()? onUnauthorized;

  ApiClient({required this.baseUrl});

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

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _handle(await http.get(uri, headers: _headers).timeout(_timeout));
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(
        await http.post(uri, headers: _headers, body: jsonEncode(body)).timeout(_timeout));
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(
        await http.put(uri, headers: _headers, body: jsonEncode(body)).timeout(_timeout));
  }

  Future<List<int>> getRaw(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = json['message'] as String? ?? 'Unknown error';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<List<int>> postRaw(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body)).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = json['message'] as String? ?? 'Unknown error';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(await http.delete(uri, headers: _headers).timeout(_timeout));
  }

  Map<String, dynamic> _handle(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    final msg = json['message'] as String? ?? 'Unknown error';
    if (response.statusCode == 401) {
      _token = null;
      onUnauthorized?.call();
      throw AuthException(msg);
    }
    throw ApiException(msg, statusCode: response.statusCode);
  }
}
