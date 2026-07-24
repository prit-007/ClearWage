import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';

class ApiClient {
  final String baseUrl;
  String? _token;

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
    return _handle(await http.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(
        await http.post(uri, headers: _headers, body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(
        await http.put(uri, headers: _headers, body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _handle(await http.delete(uri, headers: _headers));
  }

  Map<String, dynamic> _handle(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    final msg = json['message'] as String? ?? 'Unknown error';
    if (response.statusCode == 401) {
      _token = null;
      throw AuthException(msg);
    }
    throw ApiException(msg, statusCode: response.statusCode);
  }
}
