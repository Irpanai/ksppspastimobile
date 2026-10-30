import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class SplashConfig {
  final bool isCustom;
  final String mediaType; // 'video' atau 'image'
  final String? filePath; // path file di disk lokal
  final Color backgroundColor;
  final bool isSkippable;
  final int durationSeconds;
  final String fitMode; // 'cover' atau 'contain'

  const SplashConfig({
    required this.isCustom,
    required this.mediaType,
    this.filePath,
    required this.backgroundColor,
    required this.isSkippable,
    required this.durationSeconds,
    this.fitMode = 'cover',
  });

  static Color parseHexColor(String? hexString, {Color fallback = const Color(0xFF1B5E20)}) {
    if (hexString == null || hexString.trim().isEmpty) return fallback;
    var hex = hexString.trim().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

class SplashService {
  static const String _keyVersion = 'splash_cached_version';
  static const String _keyMediaType = 'splash_cached_media_type';
  static const String _keyFilePath = 'splash_cached_file_path';
  static const String _keyBgColor = 'splash_cached_bg_color';
  static const String _keySkippable = 'splash_cached_is_skippable';
  static const String _keyDuration = 'splash_cached_duration';
  static const String _keyFitMode = 'splash_cached_fit_mode';

  /// Mendapatkan konfigurasi splash aktif dari cache penyimpanan lokal
  static Future<SplashConfig?> getActiveLocalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filePath = prefs.getString(_keyFilePath);

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists() && (await file.length()) > 0) {
          final mediaType = prefs.getString(_keyMediaType) ?? 'video';
          final bgHex = prefs.getString(_keyBgColor) ?? '#1B5E20';
          final isSkippable = prefs.getBool(_keySkippable) ?? true;
          final duration = prefs.getInt(_keyDuration) ?? 4;
          final fitMode = prefs.getString(_keyFitMode) ?? 'cover';

          return SplashConfig(
            isCustom: true,
            mediaType: mediaType,
            filePath: filePath,
            backgroundColor: SplashConfig.parseHexColor(bgHex),
            isSkippable: isSkippable,
            durationSeconds: duration,
            fitMode: fitMode,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reading local splash config: $e');
    }
    return null;
  }

  /// Sinkronisasi konfigurasi splash terbaru dari CMS Admin (di latar belakang)
  static Future<void> syncSplashWithServer() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/app-config/splash');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body['success'] != true || body['data'] == null) return;

      final data = body['data'] as Map<String, dynamic>;
      final isActive = data['is_active'] == true;
      final serverVersion = (data['version'] is int)
          ? data['version'] as int
          : int.tryParse(data['version']?.toString() ?? '1') ?? 1;
      final rawMediaUrl = data['media_url']?.toString();
      final mediaType = data['media_type']?.toString() ?? 'video';
      final bgColorHex = data['background_color']?.toString() ?? '#1B5E20';
      final isSkippable = data['is_skippable'] == true;
      final fitMode = data['fit_mode']?.toString() ?? 'cover';
      final duration = (data['duration_seconds'] is int)
          ? data['duration_seconds'] as int
          : int.tryParse(data['duration_seconds']?.toString() ?? '4') ?? 4;

      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt(_keyVersion) ?? 0;
      final currentCachedPath = prefs.getString(_keyFilePath);

      // Jika splash dinonaktifkan di CMS atau media_url kosong -> bersihkan cache
      if (!isActive || rawMediaUrl == null || rawMediaUrl.trim().isEmpty) {
        if (currentCachedPath != null) {
          final file = File(currentCachedPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        await prefs.remove(_keyVersion);
        await prefs.remove(_keyMediaType);
        await prefs.remove(_keyFilePath);
        await prefs.remove(_keyBgColor);
        await prefs.remove(_keySkippable);
        await prefs.remove(_keyDuration);
        await prefs.remove(_keyFitMode);
        debugPrint('Splash reset to default bundle asset.');
        return;
      }

      // Resolusi URL media lengkap
      final resolvedUrl = ApiConstants.resolveImageUrl(rawMediaUrl) ?? rawMediaUrl;

      // Jika versi server lebih baru atau file lokal belum ada, unduh media baru
      final localFileExists = currentCachedPath != null && await File(currentCachedPath).exists();
      if (serverVersion != cachedVersion || !localFileExists) {
        debugPrint('Downloading new splash media from server (v$serverVersion): $resolvedUrl');

        final mediaResponse = await http.get(Uri.parse(resolvedUrl)).timeout(const Duration(seconds: 25));
        if (mediaResponse.statusCode == 200 && mediaResponse.bodyBytes.isNotEmpty) {
          final dir = await getApplicationDocumentsDirectory();
          final cacheDir = Directory('${dir.path}/splash_cache');
          if (!await cacheDir.exists()) {
            await cacheDir.create(recursive: true);
          }

          // Ekstensi file
          final uriPath = Uri.parse(resolvedUrl).path;
          final ext = uriPath.contains('.') ? uriPath.split('.').last : (mediaType == 'video' ? 'mp4' : 'webp');
          final newFilePath = '${cacheDir.path}/splash_v$serverVersion.$ext';

          final newFile = File(newFilePath);
          await newFile.writeAsBytes(mediaResponse.bodyBytes);

          // Hapus file lama jika berbeda
          if (currentCachedPath != null && currentCachedPath != newFilePath) {
            final oldFile = File(currentCachedPath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          }

          // Simpan metadata baru
          await prefs.setInt(_keyVersion, serverVersion);
          await prefs.setString(_keyMediaType, mediaType);
          await prefs.setString(_keyFilePath, newFilePath);
          await prefs.setString(_keyBgColor, bgColorHex);
          await prefs.setBool(_keySkippable, isSkippable);
          await prefs.setInt(_keyDuration, duration);
          await prefs.setString(_keyFitMode, fitMode);

          debugPrint('Splash media cached successfully at: $newFilePath');
        }
      }
    } catch (e) {
      debugPrint('Error syncing splash screen with server: $e');
    }
  }
}