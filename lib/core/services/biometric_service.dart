import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah perangkat memiliki dukungan sensor biometrik (hardware)
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah sensor biometrik (Sidik Jari atau Face ID) aktif dan siap digunakan
  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar tipe biometrik yang didukung (fingerprint, face, iris, dll)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Label nama jenis biometrik yang didukung aplikasi (khusus Sidik Jari)
  static Future<String> getBiometricLabel() async {
    return 'Sidik Jari (Fingerprint)';
  }

  /// Menjalankan otentikasi biometrik khusus sidik jari (fingerprint)
  static Future<bool> authenticate({
    String localizedReason = 'Pindai sidik jari Anda untuk masuk ke KSPPS PASTI',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autentikasi Sidik Jari KSPPS PASTI',
            signInHint: 'Sentuh sensor sidik jari perangkat Anda',
            cancelButton: 'Batal',
          ),
          IOSAuthMessages(
            cancelButton: 'Batal',
          ),
        ],
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
