import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String currentVersion;
  final int currentBuildNumber;
  final bool forceUpdate;
  final String title;
  final String message;
  final String playStoreUrl;
  final List<String> releaseNotes;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.playStoreUrl,
    required this.releaseNotes,
  });
}

class InAppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const InAppUpdateDialog({
    Key? key,
    required this.updateInfo,
    this.onDismiss,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    AppUpdateInfo updateInfo, {
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !updateInfo.forceUpdate,
        child: InAppUpdateDialog(
          updateInfo: updateInfo,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  Future<void> _launchPlayStore(BuildContext context) async {
    final uri = Uri.parse(updateInfo.playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch Play Store URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Header Berwarna Hijau Koperasi
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.system_update_rounded,
                    size: 38,
                    color: Color(0xFF047857),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Judul & Subtitle
            Text(
              updateInfo.title.isNotEmpty ? updateInfo.title : 'Versi Baru Tersedia!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'v${updateInfo.currentVersion} ➔ v${updateInfo.latestVersion}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Pesan Pengantar
            Text(
              updateInfo.message.isNotEmpty
                  ? updateInfo.message
                  : 'Versi terbaru KSPPS PASTI telah tersedia dengan peningkatan fitur dan performa.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Catatan Rilis (Release Notes)
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yang Baru di Versi Ini:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...updateInfo.releaseNotes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tombol Update Sekarang
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _launchPlayStore(context),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Perbarui di Google Play',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            // Tombol Nanti Saja (Hanya jika bukan force update)
            if (!updateInfo.forceUpdate) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () {
                    onDismiss?.call();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Nanti Saja',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

