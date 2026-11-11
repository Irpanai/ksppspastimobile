import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mengecek dari layer native Android apakah peluncuran UI saat ini berasal dari
/// pemulihan task yang hanya di-minimize (bukan start segar setelah aplikasi ditutup).
class AppLaunchService {
  static const MethodChannel _channel = MethodChannel('com.ksppspasti.mobile/app_lifecycle');

  static Future<bool> shouldSkipSplash() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('shouldSkipSplash');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}

