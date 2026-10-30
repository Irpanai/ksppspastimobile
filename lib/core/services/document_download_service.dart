import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentDownloadService {
  /// Mengunduh dokumen PDF langsung ke dalam penyimpanan perangkat
  /// dan langsung membukanya secara native di HP tanpa keluar ke browser web.
  static Future<bool> downloadAndOpen({
    required BuildContext context,
    required String url,
    required String fileName,
    required String documentTitle,
    String? token,
  }) async {
    try {
      // 1. Sanitasi nama file agar valid di filesystem Android
      final safeFileName = fileName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(' ', '_');
      final finalFileName = safeFileName.endsWith('.pdf') ? safeFileName : '$safeFileName.pdf';

      // 2. Siapkan direktori penyimpanan lokal HP
      Directory? targetDir;
      try {
        if (Platform.isAndroid) {
          targetDir = await getDownloadsDirectory();
        }
      } catch (_) {}
      targetDir ??= await getApplicationDocumentsDirectory();

      final filePath = '${targetDir.path}/$finalFileName';
      final file = File(filePath);

      // 3. Request ke API backend
      final headers = <String, String>{
        'Accept': 'application/pdf',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}: Gagal mengambil dokumen.');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('File dokumen kosong.');
      }

      // 4. Simpan bytes PDF ke file lokal
      await file.writeAsBytes(response.bodyBytes, flush: true);

      // 5. Buka langsung di HP via OpenFilex
      final openResult = await OpenFilex.open(filePath);

      // 6. Beri notifikasi sukses ke user dengan opsi bagikan
      if (context.mounted) {
        final message = openResult.type == ResultType.noAppToOpen
            ? 'Dokumen berhasil diunduh. Tidak ada aplikasi pembaca PDF di perangkat.'
            : 'Dokumen $documentTitle siap dibuka.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$documentTitle Berhasil Diunduh',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Bagikan',
              textColor: const Color(0xFFFDE68A),
              onPressed: () {
                Share.shareXFiles(
                  [XFile(filePath)],
                  text: '$documentTitle - KSPPS PASTI',
                );
              },
            ),
            backgroundColor: const Color(0xFF0E7955),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal mengunduh dokumen: ${e.toString().replaceAll("Exception: ", "")}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
      return false;
    }
  }
}