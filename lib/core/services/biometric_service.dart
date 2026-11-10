import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
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

  /// Label nama jenis biometrik yang tersedia di HP user (Sidik Jari, Face ID, atau Keduanya)
  static Future<String> getBiometricLabel() async {
    final types = await getAvailableBiometrics();
    final hasFace = types.contains(BiometricType.face);
    final hasFinger = types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);

    if (hasFace && hasFinger) {
      return 'Sidik Jari & Face ID';
    } else if (hasFace) {
      return 'Face ID / Pengenalan Wajah';
    } else if (hasFinger) {
      return 'Sidik Jari (Fingerprint)';
    }
    return 'Sidik Jari & Face ID';
  }

  /// Menjalankan otentikasi biometrik (Mendukung Sidik Jari dan Face ID)
  static Future<bool> authenticate({
    String localizedReason = 'Pindai sidik jari atau Face ID Anda untuk masuk ke KSPPS PASTI',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      // biometricOnly: false agar Android mengizinkan Face Unlock (Class 2) dan Fingerprint (Class 3)
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autentikasi KSPPS PASTI',
            signInHint: 'Pindai sidik jari atau gunakan Face ID Anda',
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
