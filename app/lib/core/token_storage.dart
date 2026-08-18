import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/auth_model.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userInfoKey = 'user_info';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> load() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> save(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userInfoKey);
  }

  static Future<void> saveUserInfo(AppUser info) async {
    await _storage.write(key: _userInfoKey, value: jsonEncode(info.toJson()));
  }

  static Future<AppUser?> loadUserInfo() async {
    final raw = await _storage.read(key: _userInfoKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
