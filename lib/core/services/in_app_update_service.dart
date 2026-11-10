import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/api_constants.dart';
import '../widgets/in_app_update_dialog.dart';
import 'storage_service.dart';

class InAppUpdateService {
  static bool _hasCheckedThisSession = false;

  /// Memeriksa apakah ada versi baru di backend/Play Store
  /// dan menampilkan dialog pembaruan jika versi baru tersedia.
  static Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    // Batasi pengecekan agar hanya berjalan 1 kali per sesi aplikasi dibuka (kecuali dipaksa)
    if (_hasCheckedThisSession && !forceCheck) return;
    _hasCheckedThisSession = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.appVersion}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final latestVersion = data['latest_version']?.toString() ?? currentVersion;
      final latestBuild = int.tryParse(data['latest_build_number']?.toString() ?? '0') ?? 0;
      final minSupportedBuild = int.tryParse(data['min_supported_build']?.toString() ?? '0') ?? 0;
      final serverForce = data['force_update'] == true || data['force_update'] == 1;

      // Apakah ada versi yang lebih tinggi dari versi yang saat ini terpasang?
      final isNewerAvailable = latestBuild > currentBuild || _isVersionGreater(latestVersion, currentVersion);
      if (!isNewerAvailable) return;

      // Wajib update jika build saat ini di bawah minimum yang didukung atau server menetapkan force update
      final isForceUpdate = serverForce || currentBuild < minSupportedBuild;

      // Jika bukan force update, cek apakah pengguna baru saja menolak dalam 24 jam terakhir
      if (!isForceUpdate && !forceCheck) {
        final lastDismissed = await StorageService.getLastUpdateDismissedTime();
        final now = DateTime.now().millisecondsSinceEpoch;
        const oneDayMillis = 24 * 60 * 60 * 1000;
        if (now - lastDismissed < oneDayMillis) {
          return;
        }
      }

      final notesRaw = data['release_notes'];
      final List<String> releaseNotes = [];
      if (notesRaw is List) {
        for (final item in notesRaw) {
          if (item != null) releaseNotes.add(item.toString());
        }
      }

      final updateInfo = AppUpdateInfo(
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        forceUpdate: isForceUpdate,
        title: data['title']?.toString() ?? 'Pembaruan Tersedia',
        message: data['message']?.toString() ?? '',
        playStoreUrl: data['play_store_url']?.toString() ??
            'https://play.google.com/store/apps/details?id=com.ksppspasti.mobile',
        releaseNotes: releaseNotes,
      );

      if (!context.mounted) return;

      await InAppUpdateDialog.show(
        context,
        updateInfo,
        onDismiss: () async {
          await StorageService.setLastUpdateDismissedTime(
            DateTime.now().millisecondsSinceEpoch,
          );
        },
      );
    } catch (e) {
      debugPrint('InAppUpdateService check error: $e');
    }
  }

  /// Membandingkan string semver sederhana (misal '1.0.4' > '1.0.3')
  static bool _isVersionGreater(String serverVersion, String localVersion) {
    try {
      final sParts = serverVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final lParts = localVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final s = i < sParts.length ? sParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (s > l) return true;
        if (s < l) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

