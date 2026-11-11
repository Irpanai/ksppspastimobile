import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/widgets/app_dialog.dart';

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
            ? '$documentTitle berhasil diunduh ke perangkat. Tidak ada aplikasi pembaca PDF yang terpasang.'
            : '$documentTitle berhasil diunduh dan siap dibuka.';

        AppDialog.showSuccess(
          context,
          title: 'Dokumen Berhasil Diunduh',
          message: message,
          buttonText: 'Selesai',
          secondaryButtonText: 'Bagikan',
          onSecondaryPressed: () {
            Share.shareXFiles(
              [XFile(filePath)],
              text: '$documentTitle - KSPPS PASTI',
            );
          },
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(
          context,
          title: 'Gagal Mengunduh Dokumen',
          message: 'Tidak dapat mengunduh dokumen: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
      return false;
    }
  }
}