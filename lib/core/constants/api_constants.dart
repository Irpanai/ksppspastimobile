import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL configuration
  // For web / windows desktop / iOS simulator: 'http://localhost:8000/api'
  // For Android emulator: 'http://10.0.2.2:8000/api'
  // For real device: Use your machine's LAN IP, e.g. 'http://192.168.1.xxx:8000/api'
  
  // static const String defaultLocalhostUrl = 'http://localhost:8000/api';
  static const String defaultLocalhostUrl = 'https://app.zoy.web.id/api';
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

  /// Get the active host (without /api suffix)
  static String get baseHost {
    return baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  }

  /// Resolves relative storage paths or localhost URLs to the active backend host
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    final host = baseHost;
    final hostUri = Uri.tryParse(host);

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        if (hostUri != null && hostUri.host.isNotEmpty) {
          final replaced = uri.replace(
            scheme: hostUri.scheme,
            host: hostUri.host,
            port: hostUri.hasPort ? hostUri.port : (hostUri.scheme == 'https' ? 443 : (hostUri.scheme == 'http' ? 80 : null)),
          );
          return replaced.toString();
        }
      }
      return trimmed;
    }

    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$host$cleanPath';
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Member Endpoints
  static const String dashboard = '/member/dashboard';
  static const String simpananRiwayat = '/member/simpanan/riwayat';
  static const String sijaka = '/member/sijaka';
  static const String sijakaProduk = '/member/sijaka/produk';
  static String sijakaDetail(int id) => '/member/sijaka/$id';
  static const String memberProfile = '/member/profile';
  static const String updateProfile = '/member/profile';
  static const String changePassword = '/member/profile/password';

  // Payment Gateway Endpoints
  static const String snapToken = '/payment/snap-token';
  static String paymentStatus(String orderId) => '/payment/status/$orderId';
  static const String paymentHistory = '/payment/history';
}
