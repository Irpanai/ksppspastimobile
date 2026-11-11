import 'package:flutter/material.dart';
import '../../payment/screens/top_up_screen.dart';

class WajibSimpananModalDialog extends StatelessWidget {
  const WajibSimpananModalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Wajib, tidak bisa di-dismiss
      builder: (ctx) => const PopScope(
        canPop: false, // Mencegah tombol back
        child: WajibSimpananModalDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header (Informasi tanda seru yang ramah dan elegan)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5), // Light emerald background
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E7955).withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: Color(0xFF0E7955),
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Title
            const Text(
              'Aktivasi Keanggotaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            // Description
            const Text(
              'Anda diwajibkan untuk membayar Simpanan Pokok dan Simpanan Wajib terlebih dahulu untuk mengaktifkan seluruh fitur layanan KSPPS INOVASI PASTI NUSANTARA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  // Tutup dialog
                  Navigator.of(context).pop();
                  // Arahkan ke halaman top up simpanan pokok
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopUpScreen(initialType: 'pokok'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7955),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
