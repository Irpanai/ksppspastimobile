import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyAnggota = 'auth_anggota';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    await init();
    return _prefs!.getString(_keyToken);
  }

  static Future<void> removeToken() async {
    await init();
    await _prefs!.remove(_keyToken);
  }

  // User & Anggota data management
  static Future<void> saveUserData(Map<String, dynamic> userJson) async {
    await init();
    await _prefs!.setString(_keyUser, jsonEncode(userJson));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    await init();
    final data = _prefs!.getString(_keyUser);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAnggotaData(Map<String, dynamic> anggotaJson) async {
    await init();
    await _prefs!.setString(_keyAnggota, jsonEncode(anggotaJson));
  }

  static Future<Map<String, dynamic>?> getAnggotaData() async {
    await init();
    final data = _prefs!.getString(_keyAnggota);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    await init();
    await _prefs!.remove(_keyToken);
    await _prefs!.remove(_keyUser);
    await _prefs!.remove(_keyAnggota);
  }
}
