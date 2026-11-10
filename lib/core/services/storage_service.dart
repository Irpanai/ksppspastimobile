import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyAnggota = 'auth_anggota';
  static const String _keyPendingPayment = 'pending_payment';
  static const String _keyPendingPayments = 'pending_payments_list';
  static const String _keyLastPaymentMethod = 'last_used_payment_method';
  static const String _keyDashboard = 'cached_dashboard_data';
  static const String _keyBiometricEnabled = 'biometric_login_enabled';
  static const String _keyBiometricCredentials = 'biometric_credentials';
  static const String _keyLastUpdateDismissed = 'last_update_check_dismissed';

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

  // Cached Dashboard Data (for instant 0ms load on startup/login)
  static Future<void> saveDashboardData(Map<String, dynamic> dashboardJson) async {
    await init();
    await _prefs!.setString(_keyDashboard, jsonEncode(dashboardJson));
  }

  static Future<Map<String, dynamic>?> getDashboardData() async {
    await init();
    final data = _prefs!.getString(_keyDashboard);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearDashboardData() async {
    await init();
    await _prefs!.remove(_keyDashboard);
  }

  // Multiple Pending Payments management
  static Future<void> savePendingPayment(Map<String, dynamic> json) async {
    await init();
    final list = await getPendingPaymentsList();
    final orderId = json['order_id']?.toString() ?? '';
    // Hapus jika sudah ada sebelumnya agar berada di posisi paling baru
    list.removeWhere((item) => item['order_id']?.toString() == orderId);
    list.insert(0, json);
    // Batasi riwayat pending maksimal 10 transaksi terakhir
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await _prefs!.setString(_keyPendingPayments, jsonEncode(list));
    // Simpan juga ke key tunggal untuk kompatibilitas ke belakang
    await _prefs!.setString(_keyPendingPayment, jsonEncode(json));
  }

  static Future<List<Map<String, dynamic>>> getPendingPaymentsList() async {
    await init();
    final data = _prefs!.getString(_keyPendingPayments);
    if (data == null || data.isEmpty) {
      // Periksa single key legacy jika list belum pernah dibuat
      final legacy = await getPendingPayment();
      if (legacy != null) {
        return [legacy];
      }
      return [];
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPendingPayment() async {
    await init();
    final data = _prefs!.getString(_keyPendingPayment);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removePendingPayment(String orderId) async {
    await init();
    final list = await getPendingPaymentsList();
    list.removeWhere((item) => item['order_id']?.toString() == orderId);
    await _prefs!.setString(_keyPendingPayments, jsonEncode(list));
    if (list.isEmpty) {
      await _prefs!.remove(_keyPendingPayment);
    } else {
      await _prefs!.setString(_keyPendingPayment, jsonEncode(list.first));
    }
  }

  static Future<void> clearPendingPayment() async {
    await init();
    await _prefs!.remove(_keyPendingPayment);
    await _prefs!.remove(_keyPendingPayments);
  }

  // Last Used Payment Method
  static Future<void> saveLastPaymentMethod(String code) async {
    await init();
    await _prefs!.setString(_keyLastPaymentMethod, code);
  }

  static Future<String?> getLastPaymentMethod() async {
    await init();
    final direct = _prefs!.getString(_keyLastPaymentMethod);
    if (direct != null && direct.isNotEmpty) return direct;
    final list = await getPendingPaymentsList();
    if (list.isNotEmpty) {
      final code = list.first['payment_method']?.toString();
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
  }

  // Biometric Settings & Credentials
  static Future<bool> isBiometricEnabled() async {
    await init();
    return _prefs!.getBool(_keyBiometricEnabled) ?? true;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_keyBiometricEnabled, enabled);
    if (!enabled) {
      await clearBiometricCredentials();
    }
  }

  static Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await init();
    await _prefs!.setString(
      _keyBiometricCredentials,
      jsonEncode({'email': email, 'password': password}),
    );
  }

  static Future<Map<String, String>?> getBiometricCredentials() async {
    await init();
    final raw = _prefs!.getString(_keyBiometricCredentials);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'email': decoded['email']?.toString() ?? '',
        'password': decoded['password']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearBiometricCredentials() async {
    await init();
    await _prefs!.remove(_keyBiometricCredentials);
  }

  // In-App Update Dismissed Timestamp
  static Future<int> getLastUpdateDismissedTime() async {
    await init();
    return _prefs!.getInt(_keyLastUpdateDismissed) ?? 0;
  }

  static Future<void> setLastUpdateDismissedTime(int timestamp) async {
    await init();
    await _prefs!.setInt(_keyLastUpdateDismissed, timestamp);
  }

  static Future<void> clearAll() async {
    await init();
    await _prefs!.remove(_keyToken);
    await _prefs!.remove(_keyUser);
    await _prefs!.remove(_keyAnggota);
    await _prefs!.remove(_keyPendingPayment);
    await _prefs!.remove(_keyPendingPayments);
    await _prefs!.remove(_keyDashboard);
  }
}
