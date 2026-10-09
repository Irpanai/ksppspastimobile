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

  /// Resolves relative storage paths, localhost URLs, and CORS endpoints to the active backend host
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var trimmed = rawUrl.trim();

    // 1. If relative path (e.g. 'profile-photos/abc.webp', '/storage/profile-photos/abc.webp')
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('/api/storage/')) {
        trimmed = trimmed.substring(13);
      } else if (trimmed.startsWith('api/storage/')) {
        trimmed = trimmed.substring(12);
      } else if (trimmed.startsWith('/storage/')) {
        trimmed = trimmed.substring(9);
      } else if (trimmed.startsWith('storage/')) {
        trimmed = trimmed.substring(8);
      }
      if (trimmed.startsWith('/')) {
        trimmed = trimmed.substring(1);
      }
      // Route via /api/storage/ which has CORS headers enabled
      return '$baseUrl/storage/$trimmed';
    }

    final host = baseHost;
    final hostUri = Uri.tryParse(host);

    // 2. If full URL (http or https)
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
      final isMatchingHost = hostUri != null && uri.host == hostUri.host;

      String targetScheme = uri.scheme;
      String targetHost = uri.host;
      int? targetPort = uri.hasPort ? uri.port : null;
      String targetPath = uri.path;

      // Ensure storage images route through /api/storage for CORS if they use /storage/
      if (targetPath.startsWith('/storage/') && !targetPath.startsWith('/api/storage/')) {
        targetPath = targetPath.replaceFirst('/storage/', '/api/storage/');
      }

      if (isLocal && hostUri != null && hostUri.host.isNotEmpty) {
        targetScheme = hostUri.scheme;
        targetHost = hostUri.host;
        targetPort = hostUri.hasPort ? hostUri.port : null;
      } else if (hostUri != null && hostUri.scheme == 'https' && (isMatchingHost || isLocal)) {
        targetScheme = 'https';
        if (targetPort == 80 || targetPort == 443) {
          targetPort = null;
        }
      }

      return uri.replace(
        scheme: targetScheme,
        host: targetHost,
        port: targetPort,
        path: targetPath,
      ).toString();
    }

    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$host$cleanPath';
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // Member Endpoints
  static const String dashboard = '/member/dashboard';
  static const String simpananRiwayat = '/member/simpanan/riwayat';
  static const String simpananTarik = '/member/simpanan/tarik';
  static const String simpananPenarikanRiwayat = '/member/simpanan/penarikan-riwayat';
  static const String sijaka = '/member/sijaka';
  static const String sijakaProduk = '/member/sijaka/produk';
  static String sijakaDetail(int id) => '/member/sijaka/$id';
  static const String memberProfile = '/member/profile';
  static const String updateProfile = '/member/profile';
  static const String changePassword = '/member/profile/password';
  static const String resetPasswordWithPin = '/member/profile/password-reset-pin';

  // PIN Security Endpoints
  static const String pinStatus = '/member/pin/status';
  static const String pinSetup = '/member/pin/setup';
  static const String pinVerify = '/member/pin/verify';
  static const String pinChange = '/member/pin/change';

  // Payment Gateway Endpoints
  static const String snapToken = '/payment/snap-token';
  static String paymentStatus(String orderId) => '/payment/status/$orderId';
  static const String paymentHistory = '/payment/history';
}
