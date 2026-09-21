import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL configuration
  // For web / windows desktop / iOS simulator: 'http://localhost:8000/api'
  // For Android emulator: 'http://10.0.2.2:8000/api'
  // For real device: Use your machine's LAN IP, e.g. 'http://192.168.1.xxx:8000/api'
  
  static const String defaultLocalhostUrl = 'http://localhost:8000/api';
  // static const String defaultLocalhostUrl = 'https://app.zoy.web.id/api';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000/api';

  // Active Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return defaultLocalhostUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // If running in an emulator vs actual localhost
      // Default to localhost:8000 for standard setup
      return defaultLocalhostUrl;
    }
    return defaultLocalhostUrl;
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Member Endpoints
  static const String dashboard = '/member/dashboard';
  static const String simpananRiwayat = '/member/simpanan/riwayat';
  static const String sijaka = '/member/sijaka';
  static String sijakaDetail(int id) => '/member/sijaka/$id';
}
