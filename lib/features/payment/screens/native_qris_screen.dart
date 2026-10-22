import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../sijaka/providers/sijaka_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import 'doku_webview_screen.dart';

class NativeQrisScreen extends StatefulWidget {
  final SnapTokenResponse paymentResponse;

  const NativeQrisScreen({
    super.key,
    required this.paymentResponse,
  });

  @override
  State<NativeQrisScreen> createState() => _NativeQrisScreenState();
}

class _NativeQrisScreenState extends State<NativeQrisScreen> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  Timer? _countdownTimer;
  Timer? _autoCheckTimer;
  Duration _timeLeft = const Duration(minutes: 30);
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _hasSettled = false;

  @override
  void initState() {
    super.initState();
    _initCountdown();
    _startAutoPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _initCountdown() {
    if (widget.paymentResponse.expiredDate != null &&
        widget.paymentResponse.expiredDate!.isNotEmpty) {
      try {
        final exp = DateTime.parse(widget.paymentResponse.expiredDate!);
        final now = DateTime.now().toUtc();
        final diff = exp.difference(now);
        if (diff.isNegative) {
          _timeLeft = Duration.zero;
        } else {
          _timeLeft = diff;
        }
      } catch (_) {
        _timeLeft = const Duration(minutes: 30);
      }
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = Duration(seconds: _timeLeft.inSeconds - 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startAutoPolling() {
    // Polling setiap 7 detik untuk mendeteksi pembayaran QRIS realtime
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && !_isChecking && !_hasSettled) {
        _checkStatus(silent: true);
      }
    });
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_hasSettled) return;

    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final status = await paymentProvider.checkStatus(widget.paymentResponse.orderId);

      if (!mounted) return;

      if (!silent) {
        setState(() => _isChecking = false);
      }

      if (status != null && status.isSettlement) {
        _hasSettled = true;
        _autoCheckTimer?.cancel();

        // Refresh Provider Global
        try {
          context.read<DashboardProvider>().fetchDashboard(refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('sukarela', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('wajib', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('pokok', refresh: true);
          context.read<SijakaProvider>().fetchBilyetList(refresh: true);
        } catch (_) {}

        _showSuccessDialog(status);
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran QRIS belum terdeteksi. Silakan selesaikan pembayaran di aplikasi m-Banking/e-Wallet Anda lalu coba lagi.'),
            backgroundColor: Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa status: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(PaymentStatusResponse status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pembayaran QRIS Berhasil!',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Setoran Anda telah diverifikasi oleh sistem KSPPS PASTI dan saldo simpanan telah bertambah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Setoran:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        AppCurrency.format(status.nominal),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const Text('QRIS Nasional', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order ID:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        status.orderId,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Selesai & Kembali', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadQr() async {
    final qrData = widget.paymentResponse.qrString ?? '';
    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode QR belum tersedia untuk diunduh.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // 1. Cek atau minta izin akses galeri jika dibutuhkan platform
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final requestGranted = await Gal.requestAccess();
        if (!requestGranted) {
          if (!mounted) return;
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin akses galeri tidak diberikan. Silakan izinkan akses untuk menyimpan gambar QR.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // 2. Render kartu QR menjadi Uint8List PNG resolusi tinggi
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Komponen QR belum siap dirender.');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses gambar QR.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. Simpan ke Galeri menggunakan plugin Gal
      final cleanOrderId = widget.paymentResponse.orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Gal.putImageBytes(pngBytes, name: 'QRIS_KSPPS_$cleanOrderId');

      if (!mounted) return;
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'QRIS berhasil disimpan ke Galeri! Anda dapat memilih gambar ini di m-Banking/e-Wallet.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan ke galeri: ${e.type.message}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh QR: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label berhasil disalin'),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.paymentResponse;
    final qrData = res.qrString ?? '';
    final nmid = res.nmid ?? 'ID2026102056853';

    return PopScope(
      canPop: _hasSettled,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tinggalkan Halaman QRIS?'),
            content: const Text(
              'Pembayaran Anda masih pending. Anda tetap dapat menyelesaikan pembayaran sebelum batas waktu berakhir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Tetap di Sini'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Pembayaran QRIS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          actions: [
            IconButton(
              onPressed: _isDownloading ? null : _downloadQr,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                    )
                  : const Icon(Icons.file_download_outlined, color: Color(0xFFDC2626)),
              tooltip: 'Download QR ke Galeri',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Countdown Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_outlined, color: Color(0xFFDC2626), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selesaikan Pembayaran Dalam',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDuration(_timeLeft),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'QR Dinamis',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kartu QRIS Utama (Dapat di-download sebagai gambar)
              RepaintBoundary(
                key: _qrBoundaryKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Header QRIS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'QRIS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  'STANDAR PEMBAYARAN',
                                  style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                ),
                                Text(
                                  'BANK INDONESIA',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Merchant Info & NMID
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          children: [
                            const Text(
                              'KSPPS PASTI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NMID: $nmid',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Box QR Code
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: qrData.isNotEmpty
                              ? QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 240.0,
                                  backgroundColor: Colors.white,
                                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                                )
                              : Container(
                                  height: 240,
                                  width: 240,
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 12),
                                      Text('Gagal memuat QR Code', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      // Logo Bank & E-Wallet Icons Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'BCA • Mandiri • BRI • BSI • GoPay • OVO • Dana • ShopeePay',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Rincian Nominal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nominal Tagihan', style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                    res.nominalFormat.isNotEmpty ? res.nominalFormat : AppCurrency.format(res.nominal),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => _copyToClipboard(res.nominal.toInt().toString(), 'Nominal'),
                                icon: const Icon(Icons.copy_rounded, color: Color(0xFF0F766E)),
                                tooltip: 'Salin Nominal',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Tombol Aksi Download QR & Salin Kode QR
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadQr,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isDownloading ? 'Menyimpan...' : 'Download QR',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(qrData, 'Kode QR'),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Salin Kode',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rincian Order ID
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nomor Transaksi (Order ID)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(
                          res.orderId,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(res.orderId, 'Order ID'),
                      icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF64748B)),
                      tooltip: 'Salin Order ID',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Petunjuk Pembayaran (Expandable / Cards)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.help_outline_rounded, color: Color(0xFFDC2626)),
                    title: const Text(
                      'Panduan Cara Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            _buildInstructionStep(
                              step: '1',
                              title: 'Buka Aplikasi Pembayaran',
                              desc: 'Buka BCA mobile, Livin\' Mandiri, BRImo, BSI Mobile, GoPay, OVO, Dana, atau ShopeePay Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '2',
                              title: 'Pilih Menu Scan QRIS / Bayar',
                              desc: 'Pilih menu Bayar / Scan QR pada aplikasi Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '3',
                              title: 'Pindai Kode QR / Upload Gambar',
                              desc: 'Arahkan kamera ke kode QR di layar ini, atau tekan tombol "Download QR" lalu unggah gambar QR dari Galeri aplikasi perbankan Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '4',
                              title: 'Periksa & Masukkan PIN',
                              desc: 'Pastikan nama penerima "KSPPS PASTI" dan nominal tagihan sesuai, lalu masukkan PIN transaksi Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '5',
                              title: 'Verifikasi Otomatis',
                              desc: 'Setelah pembayaran selesai di m-Banking Anda, layar ini akan otomatis mendeteksi dan menyelesaikan setoran.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Cek Status Manual
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : () => _checkStatus(silent: false),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    _isChecking ? 'Memeriksa Pembayaran...' : 'Cek Status Pembayaran',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              // Opsi fallback buka halaman DOKU jika diperlukan
              if (res.paymentUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DokuWebViewScreen(paymentResponse: res),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: Color(0xFF64748B)),
                    label: const Text(
                      'Buka Halaman DOKU Checkout',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required String step, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
