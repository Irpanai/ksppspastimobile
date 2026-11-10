import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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

  /// Memeriksa apakah sensor biometrik aktif dan siap digunakan
  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar tipe biometrik yang didukung (fingerprint, face, iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Label nama jenis biometrik yang tersedia di HP user
  static Future<String> getBiometricLabel() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return 'Face ID / Pengenalan Wajah';
    } else if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) {
      return 'Sidik Jari (Fingerprint)';
    }
    return 'Biometrik';
  }

  /// Menjalankan otentikasi biometrik
  static Future<bool> authenticate({
    String localizedReason = 'Pindai sidik jari atau Face ID Anda untuk masuk ke KSPPS PASTI',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
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
