import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'app_dialog.dart';

class StrukTransaksiData {
  final String idTransaksi;
  final String noReferensi;
  final String jenisTransaksi;
  final String namaAnggota;
  final String noAnggota;
  final String? cabang;
  final String nominal;
  final String tanggalWaktu;
  final String keterangan;
  final String status;
  final bool isMasuk;

  StrukTransaksiData({
    required this.idTransaksi,
    required this.noReferensi,
    required this.jenisTransaksi,
    required this.namaAnggota,
    required this.noAnggota,
    this.cabang,
    required this.nominal,
    required this.tanggalWaktu,
    required this.keterangan,
    this.status = 'BERHASIL',
    this.isMasuk = true,
  });
}

class StrukTransaksiDialog extends StatefulWidget {
  final StrukTransaksiData data;

  const StrukTransaksiDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  /// Helper statis untuk menampilkan dialog struk
  static void show(BuildContext context, StrukTransaksiData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StrukTransaksiDialog(data: data),
    );
  }

  @override
  State<StrukTransaksiDialog> createState() => _StrukTransaksiDialogState();
}

class _StrukTransaksiDialogState extends State<StrukTransaksiDialog> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isProcessing = false;

  /// Menangkap widget struk menjadi file gambar PNG
  Future<File?> _captureReceiptAsFile() async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 3.0 pixelRatio agar resolusi tajam dan jernih saat dibagikan
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final cleanRef = widget.data.noReferensi.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${tempDir.path}/Struk_KSPPS_PASTI_$cleanRef.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

  /// Bagikan Struk ke WhatsApp atau Media Sosial
  Future<void> _shareReceipt() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final file = await _captureReceiptAsFile();
      if (file == null) {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'Gagal Membuat Gambar',
            message: 'Tidak dapat membuat gambar struk untuk dibagikan.',
          );
        }
        return;
      }

      final shareText = '''
*BUKTI TRANSAKSI KSPPS PASTI*
--------------------------------
• No. Ref: ${widget.data.noReferensi}
• Jenis: ${widget.data.jenisTransaksi}
• Nominal: ${widget.data.nominal}
• Waktu: ${widget.data.tanggalWaktu}
• Status: ${widget.data.status}
--------------------------------
KSPPS INOVASI PASTI NUSANTARA
_Transaksi syariah aman, amanah, dan terpercaya._
''';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Bukti Transaksi - KSPPS PASTI',
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Simpan gambar struk ke Galeri HP
  Future<void> _saveToGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final file = await _captureReceiptAsFile();
      if (file == null) {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'Gagal Memproses Gambar',
            message: 'Tidak dapat menghasilkan gambar struk transaksi.',
          );
        }
        return;
      }

      await Gal.putImage(file.path);

      if (mounted) {
        AppDialog.showSuccess(
          context,
          title: 'Struk Tersimpan',
          message: 'Struk transaksi berhasil disimpan ke Galeri HP Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Gagal Menyimpan Gambar',
          message: 'Tidak dapat menyimpan gambar struk ke galeri: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Judul Atas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bukti Transaksi Resmi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Receipt Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Center(
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kop Surat Koperasi
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'KSPPS PASTI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'KSPPS INOVASI PASTI NUSANTARA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tanda Terima Transaksi Elektronik',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge & Nominal
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          color: const Color(0xFFF8FAFC),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.data.isMasuk ? Icons.check_circle_rounded : Icons.arrow_outward_rounded,
                                      color: const Color(0xFF059669),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'TRANSAKSI ${widget.data.status}',
                                      style: const TextStyle(
                                        color: Color(0xFF065F46),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Nominal Transaksi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.data.nominal,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dashed Separator Line
                        _buildDashedLine(),

                        // Rincian Transaksi
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReceiptRow('No. Referensi', widget.data.noReferensi, isBold: true),
                              _buildReceiptRow('ID Transaksi', '#${widget.data.idTransaksi}'),
                              _buildReceiptRow('Waktu Transaksi', widget.data.tanggalWaktu),
                              _buildReceiptRow('Jenis Transaksi', widget.data.jenisTransaksi),
                              _buildReceiptRow('Nama Anggota', widget.data.namaAnggota),
                              _buildReceiptRow('No. Anggota', widget.data.noAnggota),
                              if (widget.data.cabang != null && widget.data.cabang!.isNotEmpty)
                                _buildReceiptRow('Kantor Cabang', widget.data.cabang!),
                              _buildReceiptRow('Biaya Admin', 'Rp 0 (GRATIS)', valueColor: const Color(0xFF059669)),
                              _buildReceiptRow('Keterangan', widget.data.keterangan),
                            ],
                          ),
                        ),

                        // Dashed Separator Line
                        _buildDashedLine(),

                        // QR Code Verifikasi & Catatan Keabsahan
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: QrImageView(
                                  data: 'KSPPS-PASTI:${widget.data.noReferensi}:${widget.data.nominal}',
                                  version: QrVersions.auto,
                                  size: 64.0,
                                  gapless: true,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Dokumen Sah Elektronik',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Struk ini diterbitkan otomatis oleh sistem KSPPS PASTI dan berlaku sebagai bukti transaksi yang sah.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Tombol Simpan Gambar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _saveToGallery,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Simpan Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Bagikan ke WhatsApp
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _shareReceipt,
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Bagikan Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

