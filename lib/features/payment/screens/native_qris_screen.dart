import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../sijaka/providers/sijaka_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../widgets/doku_qris_web_bridge.dart';

class NativeQrisScreen extends StatefulWidget {
  final SnapTokenResponse? paymentResponse;
  final Future<SnapTokenResponse?> Function()? onGeneratePayment;
  final Uint8List? initialQrBytes;
  final String? initialQrImageUrl;
  final DokuQrisWebController? preloadedWebController;

  const NativeQrisScreen({
    super.key,
    this.paymentResponse,
    this.onGeneratePayment,
    this.initialQrBytes,
    this.initialQrImageUrl,
    this.preloadedWebController,
  }) : assert(
          paymentResponse != null || onGeneratePayment != null,
          'paymentResponse atau onGeneratePayment harus diisi',
        );

  @override
  State<NativeQrisScreen> createState() => _NativeQrisScreenState();
}

class _NativeQrisScreenState extends State<NativeQrisScreen> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  SnapTokenResponse? _payment;
  Timer? _countdownTimer;
  Timer? _autoCheckTimer;
  Duration _timeLeft = const Duration(minutes: 30);
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _hasSettled = false;
  bool _isLoadingQris = false;
  String? _generationError;
  Uint8List? _extractedQrBytes;
  String? _extractedQrImageUrl;
  DokuQrisWebController? _inlineDokuController;
  bool _inlineDokuLoading = true;
  double _inlineDokuProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _payment = widget.paymentResponse;
    _extractedQrBytes = widget.initialQrBytes;
    _extractedQrImageUrl = widget.initialQrImageUrl;
    final initialQr = _payment?.qrString?.trim() ?? '';
    final preloaded = widget.preloadedWebController;

    if (preloaded != null && !preloaded.isDisposed && preloaded.webViewController != null) {
      _inlineDokuController = preloaded;
      _inlineDokuLoading = preloaded.isLoading;
      _inlineDokuProgress = preloaded.progress;
      preloaded.setCallbacks(
        onExtracted: (payload) => _applyExtractedPayload(payload),
        onPaymentFinishedUrl: () => _checkStatus(silent: true),
        onProgress: (p) {
          if (mounted) setState(() => _inlineDokuProgress = p);
        },
        onPageLoadingChanged: (loading) {
          if (mounted) setState(() => _inlineDokuLoading = loading);
        },
      );
    }

    final hasPreloadedContent = initialQr.isNotEmpty ||
        _extractedQrBytes != null ||
        _extractedQrImageUrl != null ||
        _inlineDokuController != null;

    if (_payment != null && hasPreloadedContent) {
      _isLoadingQris = false;
      _initCountdown();
      _startAutoPolling();
    } else {
      // Tampilkan skeleton loading terlebih dahulu sampai generate/fetch QRIS selesai
      _isLoadingQris = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadOrGenerateQris();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _disposeWebControllers();
    super.dispose();
  }

  void _disposeWebControllers() {
    _inlineDokuController?.dispose();
    _inlineDokuController = null;
  }

  void _refreshGlobalProviders() {
    try {
      context.read<DashboardProvider>().fetchDashboard(refresh: true);
      context.read<SavingsProvider>().fetchRiwayat('sukarela', refresh: true);
      context.read<SavingsProvider>().fetchRiwayat('wajib', refresh: true);
      context.read<SavingsProvider>().fetchRiwayat('pokok', refresh: true);
      context.read<SijakaProvider>().fetchBilyetList(refresh: true);
    } catch (_) {}
  }

  Future<void> _applyExtractedPayload(ExtractedQrisPayload payload) async {
    if (!mounted) return;
    final active = _payment;
    if (active == null) return;

    final paymentProvider = context.read<PaymentProvider>();

    if (payload.hasQrString) {
      final updated = active.copyWithQr(qrString: payload.qrString);
      _payment = updated;
      await paymentProvider.updatePendingPayment(updated);
    }

    Uint8List? downloadedBytes;
    String? fallbackImageUrl;
    if (payload.hasImageUrl && !payload.hasImageBytes && (_payment?.qrString?.trim().isEmpty ?? true)) {
      try {
        final resp = await http
            .get(Uri.parse(payload.imageUrl!))
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200 && resp.bodyBytes.length > 80) {
          downloadedBytes = resp.bodyBytes;
        } else {
          fallbackImageUrl = payload.imageUrl;
        }
      } catch (_) {
        fallbackImageUrl = payload.imageUrl;
      }
    }

    if (!mounted) return;
    setState(() {
      if ((_payment?.qrString?.trim().isEmpty ?? true)) {
        if (payload.hasImageBytes) {
          _extractedQrBytes = payload.imageBytes;
          _extractedQrImageUrl = null;
        } else if (downloadedBytes != null) {
          _extractedQrBytes = downloadedBytes;
          _extractedQrImageUrl = null;
        } else if (fallbackImageUrl != null && _extractedQrBytes == null) {
          _extractedQrImageUrl = fallbackImageUrl;
        }
      }
      _isLoadingQris = false;
    });

    final hasFinalQr = (_payment?.qrString?.trim().isNotEmpty ?? false) ||
        _extractedQrBytes != null ||
        _extractedQrImageUrl != null;

    if (hasFinalQr) {
      _inlineDokuController?.dispose();
      _inlineDokuController = null;
    }
  }

  void _activateInlineDokuFallback(String checkoutUrl) {
    if (!mounted || checkoutUrl.trim().isEmpty) return;

    _inlineDokuController?.dispose();
    final inlineCtrl = DokuQrisWebController();
    _inlineDokuLoading = true;
    _inlineDokuProgress = 0.0;

    final started = inlineCtrl.start(
      url: checkoutUrl,
      onExtracted: (payload) => _applyExtractedPayload(payload),
      onPaymentFinishedUrl: () => _checkStatus(silent: true),
      onProgress: (p) {
        if (mounted) setState(() => _inlineDokuProgress = p);
      },
      onPageLoadingChanged: (loading) {
        if (mounted) setState(() => _inlineDokuLoading = loading);
      },
    );

    if (started) {
      setState(() => _inlineDokuController = inlineCtrl);
    } else {
      inlineCtrl.dispose();
    }
  }

  Future<void> _loadOrGenerateQris() async {
    if (!mounted) return;
    final generatedFresh = _payment == null && widget.onGeneratePayment != null;
    _disposeWebControllers();
    setState(() {
      _isLoadingQris = true;
      _generationError = null;
      _extractedQrBytes = null;
      _extractedQrImageUrl = null;
    });

    final paymentProvider = context.read<PaymentProvider>();

    if (_payment == null && widget.onGeneratePayment != null) {
      try {
        final created = await widget.onGeneratePayment!();
        if (!mounted) return;

        if (created == null) {
          setState(() {
            _isLoadingQris = false;
            _generationError = paymentProvider.errorMessage ??
                'Gagal membuat transaksi QRIS. Silakan periksa koneksi Anda dan coba kembali.';
          });
          return;
        }

        _payment = created;
        _initCountdown();
        _startAutoPolling();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoadingQris = false;
          _generationError = 'Gagal membuat kode QRIS: ${e.toString()}';
        });
        return;
      }
    } else if (_payment != null && _countdownTimer == null) {
      _initCountdown();
      _startAutoPolling();
    }

    final active = _payment;
    if (active != null && (active.qrString == null || active.qrString!.trim().isEmpty)) {
      if (!generatedFresh || active.snapRedirectUrl.trim().isEmpty) {
        try {
          final status = await paymentProvider
              .checkStatus(active.orderId)
              .timeout(const Duration(seconds: 18));
          if (!mounted) return;

          if (status != null && status.isSettlement) {
            _hasSettled = true;
            _autoCheckTimer?.cancel();
            _refreshGlobalProviders();
            setState(() => _isLoadingQris = false);
            _showSuccessDialog(status);
            return;
          }

          final fetchedQr = status?.qrString?.trim() ?? '';
          if (fetchedQr.isNotEmpty) {
            final updated = active.copyWithQr(
              qrString: fetchedQr,
              nmid: status?.nmid ?? active.nmid,
              expiredDate: status?.expiredDate ?? active.expiredDate,
            );
            _payment = updated;
            await paymentProvider.updatePendingPayment(updated);
          }
        } catch (_) {}
      }

      final current = _payment;
      if (current != null &&
          (current.qrString == null || current.qrString!.trim().isEmpty) &&
          current.snapRedirectUrl.trim().isNotEmpty) {
        _activateInlineDokuFallback(current.snapRedirectUrl);
      }
    }

    if (!mounted) return;
    setState(() => _isLoadingQris = false);
  }

  void _initCountdown() {
    _countdownTimer?.cancel();
    final payment = _payment;
    if (payment == null) return;

    if (payment.expiredDate != null && payment.expiredDate!.isNotEmpty) {
      try {
        final exp = DateTime.parse(payment.expiredDate!);
        final now = DateTime.now().toUtc();
        final diff = exp.difference(now);
        _timeLeft = diff.isNegative ? Duration.zero : diff;
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
    _autoCheckTimer?.cancel();
    // Polling setiap 7 detik untuk mendeteksi pembayaran QRIS realtime
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && !_isLoadingQris && !_isChecking && !_hasSettled && _payment != null) {
        _checkStatus(silent: true);
      }
    });
  }

  Future<void> _checkStatus({bool silent = false}) async {
    final active = _payment;
    if (_hasSettled || active == null) return;

    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final status = await paymentProvider.checkStatus(active.orderId);

      if (!mounted) return;

      if (!silent) {
        setState(() => _isChecking = false);
      }

      if (status != null && status.isSettlement) {
        _hasSettled = true;
        _autoCheckTimer?.cancel();
        _refreshGlobalProviders();
        _showSuccessDialog(status);
      } else {
        // Jika QR baru tersedia saat polling, langsung perbarui UI
        final fetchedQr = status?.qrString?.trim() ?? '';
        if (fetchedQr.isNotEmpty && (active.qrString == null || active.qrString!.trim().isEmpty)) {
          final updated = active.copyWithQr(
            qrString: fetchedQr,
            nmid: status?.nmid ?? active.nmid,
            expiredDate: status?.expiredDate ?? active.expiredDate,
          );
          _inlineDokuController?.dispose();
          setState(() {
            _payment = updated;
            _inlineDokuController = null;
          });
          await paymentProvider.updatePendingPayment(updated);
        } else if (!silent) {
          AppDialog.showWarning(
            context,
            title: 'Pembayaran Belum Terdeteksi',
            message: 'Pembayaran QRIS belum terdeteksi. Silakan selesaikan pembayaran di aplikasi m-Banking atau e-Wallet Anda lalu coba lagi.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isChecking = false);
        AppDialog.showError(
          context,
          title: 'Gagal Memeriksa Status',
          message: 'Terjadi kendala saat memeriksa status pembayaran: ${e.toString()}',
        );
      }
    }
  }

  void _showSuccessDialog(PaymentStatusResponse status) {
    AppDialog.showSuccess(
      context,
      title: 'Pembayaran QRIS Berhasil!',
      message: 'Setoran Anda telah diverifikasi oleh sistem KSPPS PASTI dan saldo simpanan telah bertambah.',
      buttonText: 'Selesai & Kembali',
      barrierDismissible: false,
      onConfirm: () {
        if (mounted) Navigator.pop(context, true);
      },
      customContent: Container(
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metode:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text('QRIS Nasional', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order ID:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Flexible(
                  child: Text(
                    status.orderId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadQr() async {
    final res = _payment;
    final qrData = res?.qrString?.trim() ?? '';
    if (res == null || (qrData.isEmpty && _extractedQrBytes == null && _extractedQrImageUrl == null)) {
      AppDialog.showWarning(
        context,
        title: 'QR Belum Tersedia',
        message: 'Kode QR belum tersedia untuk diunduh.',
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
          AppDialog.showError(
            context,
            title: 'Izin Galeri Diperlukan',
            message: 'Izin akses galeri tidak diberikan. Silakan izinkan akses untuk menyimpan gambar QR.',
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
      final cleanOrderId = res.orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Gal.putImageBytes(pngBytes, name: 'QRIS_KSPPS_$cleanOrderId');

      if (!mounted) return;
      setState(() => _isDownloading = false);

      AppDialog.showSuccess(
        context,
        title: 'QRIS Tersimpan ke Galeri',
        message: 'QRIS berhasil disimpan ke Galeri! Anda dapat memilih gambar ini melalui menu upload QR di m-Banking atau e-Wallet.',
      );
    } on GalException catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      AppDialog.showError(
        context,
        title: 'Gagal Menyimpan ke Galeri',
        message: 'Gagal menyimpan gambar ke galeri: ${e.type.message}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      AppDialog.showError(
        context,
        title: 'Gagal Mengunduh QR',
        message: 'Terjadi kesalahan saat mengunduh QR: ${e.toString()}',
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppDialog.showFloatingToast(
      context,
      message: '$label berhasil disalin',
    );
  }

  String _formatDisplayOrderId(String orderId) {
    if (orderId.isEmpty) return orderId;
    return orderId
        .replaceAll('SIMPANAN_SUKARELA', 'Sirela')
        .replaceAll('simpanan_sukarela', 'Sirela')
        .replaceAll('PEMBUKAAN_SIJAKA', 'Sijaka')
        .replaceAll('pembukaan_sijaka', 'Sijaka')
        .replaceAll('SIMPANAN_POKOK_WAJIB', 'RegAwal')
        .replaceAll('simpanan_pokok_wajib', 'RegAwal')
        .replaceAll('SIMPANAN_POKOK', 'Sipokok')
        .replaceAll('simpanan_pokok', 'Sipokok')
        .replaceAll('SIMPANAN_WAJIB', 'Siwajib')
        .replaceAll('simpanan_wajib', 'Siwajib');
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
    final res = _payment;
    final qrData = res?.qrString?.trim() ?? '';
    final nmid = res?.nmid ?? 'ID2026102056853';
    final hasQrImage = qrData.isNotEmpty || _extractedQrBytes != null || _extractedQrImageUrl != null;
    final hasCopyableQr = qrData.isNotEmpty;

    // Warna aksen QRIS dinamis dari pengaturan web (tag_color), default resmi merah QRIS
    Color qrisColor = const Color(0xFFDC2626);
    try {
      final channels = context.watch<PaymentProvider>().activeChannels;
      final matched = channels.firstWhere((c) => c.code.toLowerCase() == 'qris');
      qrisColor = matched.tagColor;
    } catch (_) {}

    return PopScope(
      canPop: _hasSettled || _isLoadingQris || _generationError != null || res == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await AppDialog.showConfirmation(
          context,
          title: 'Tinggalkan Halaman QRIS?',
          message: 'Pembayaran Anda masih dalam status menunggu. Anda tetap dapat menyelesaikan pembayaran sebelum batas waktu berakhir.',
          confirmText: 'Keluar',
          cancelText: 'Tetap di Sini',
          isDestructive: false,
          icon: Icons.qr_code_scanner_rounded,
          iconColor: const Color(0xFF475569),
          iconBgColor: const Color(0xFFF1F5F9),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: 'Pembayaran QRIS',
              showBackButton: true,
              onBackPressed: () => Navigator.maybePop(context),
              actions: [
                IconButton(
                  onPressed: (_isDownloading || _isLoadingQris || !hasQrImage) ? null : _downloadQr,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          Icons.file_download_outlined,
                          color: (_isLoadingQris || !hasQrImage)
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.white,
                        ),
                  tooltip: 'Download QR ke Galeri',
                ),
              ],
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  child: _isLoadingQris
                      ? _buildQrisSkeleton(qrisColor)
                      : (_generationError != null || res == null)
                          ? _buildGenerationErrorState(qrisColor)
                          : Column(
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
                      // Header QRIS (Warna aksen dari pengaturan web)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: qrisColor,
                          borderRadius: const BorderRadius.only(
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

                      // Box QR Code (sejajar margin kartu dengan border rapi)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildQrBoxContent(res, qrData, qrisColor),
                      ),

                      const SizedBox(height: 12),

                      // Rincian Nominal (Aksen QRIS)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: qrisColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Tagihan QRIS', style: TextStyle(fontSize: 12, color: qrisColor, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    res.grossAmountFormat.isNotEmpty ? res.grossAmountFormat : AppCurrency.format(res.grossAmount),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: qrisColor,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => _copyToClipboard(res.grossAmount.toInt().toString(), 'Nominal Tagihan'),
                                icon: Icon(Icons.copy_rounded, color: qrisColor),
                                tooltip: 'Salin Nominal Tagihan',
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
                      onPressed: (_isDownloading || !hasQrImage) ? null : _downloadQr,
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
                        backgroundColor: qrisColor,
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
                      onPressed: hasCopyableQr ? () => _copyToClipboard(qrData, 'Kode QR') : null,
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

              // Rincian Transaksi & Order ID
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nomor Transaksi (Order ID)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () => _copyToClipboard(res.orderId, 'Order ID'),
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                          tooltip: 'Salin Order ID',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatDisplayOrderId(res.orderId),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(height: 18, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nominal Simpanan', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(res.nominalFormat, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biaya Admin', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          res.adminFee > 0 ? res.adminFeeFormat : 'Gratis',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: res.adminFee > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tagihan QRIS', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(
                          res.grossAmountFormat,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: qrisColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Petunjuk Pembayaran (Expandable / Cards)
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: Icon(Icons.help_outline_rounded, color: qrisColor),
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
                              accentColor: qrisColor,
                              title: 'Buka Aplikasi Pembayaran',
                              desc: 'Buka BCA mobile, Livin\' Mandiri, BRImo, BSI Mobile, GoPay, OVO, Dana, atau ShopeePay Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '2',
                              accentColor: qrisColor,
                              title: 'Pilih Menu Scan QRIS / Bayar',
                              desc: 'Pilih menu Bayar / Scan QR pada aplikasi Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '3',
                              accentColor: qrisColor,
                              title: 'Pindai Kode QR / Upload Gambar',
                              desc: 'Arahkan kamera ke kode QR di layar ini, atau tekan tombol "Download QR" lalu unggah gambar QR dari Galeri aplikasi perbankan Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '4',
                              accentColor: qrisColor,
                              title: 'Periksa & Masukkan PIN',
                              desc: 'Pastikan nama penerima "KSPPS PASTI" dan nominal tagihan sesuai, lalu masukkan PIN transaksi Anda.',
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionStep(
                              step: '5',
                              accentColor: qrisColor,
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
                    backgroundColor: qrisColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
    ],
  ),
),
);
  }

  Widget _buildQrBoxContent(
    SnapTokenResponse res,
    String qrData,
    Color qrisColor,
  ) {
    Widget framedQrBox(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double qrSize = constraints.hasBoundedWidth
            ? (constraints.maxWidth - 48).clamp(195.0, 248.0)
            : 230.0;

        if (qrData.isNotEmpty) {
          return Center(
            child: framedQrBox(
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: qrSize,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          );
        }

        if (_extractedQrBytes != null) {
          return Center(
            child: framedQrBox(
              Image.memory(
                _extractedQrBytes!,
                width: qrSize,
                height: qrSize,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          );
        }

        if (_extractedQrImageUrl != null) {
          return Center(
            child: framedQrBox(
              Image.network(
                _extractedQrImageUrl!,
                width: qrSize,
                height: qrSize,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: _loadOrGenerateQris,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Muat Ulang QR', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: qrisColor,
                          side: BorderSide(color: qrisColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        final inlineController = _inlineDokuController?.webViewController;
        if (inlineController != null) {
          return InlineDokuQrisWebView(
            controller: inlineController,
            isLoading: _inlineDokuLoading,
            progress: _inlineDokuProgress,
            accentColor: qrisColor,
            onReload: () => _inlineDokuController?.reload(),
          );
        }

        final hasCheckoutUrl = res.snapRedirectUrl.trim().isNotEmpty;
        return framedQrBox(
          SizedBox(
            width: 240,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 52,
                    color: hasCheckoutUrl ? qrisColor : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasCheckoutUrl ? 'Menyiapkan Kode QRIS' : 'QR Code Belum Tersedia',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tekan tombol di bawah untuk memuat ulang tampilan QRIS langsung di halaman ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadOrGenerateQris,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Muat Ulang QR', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: qrisColor,
                        side: BorderSide(color: qrisColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Widget _buildQrisSkeleton(Color qrisColor) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skeleton Countdown Timer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                AppSkeletonBox(width: 36, height: 36, borderRadius: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(width: 160, height: 12),
                      SizedBox(height: 6),
                      AppSkeletonBox(width: 100, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Skeleton Kartu QRIS Utama
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Header banner skeleton mengikuti aksen kartu QRIS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: qrisColor.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSkeletonBox(width: 96, height: 22),
                      AppSkeletonBox(width: 112, height: 18),
                    ],
                  ),
                ),

                // Merchant Info & NMID skeleton
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      AppSkeletonBox(width: 140, height: 18),
                      SizedBox(height: 8),
                      AppSkeletonBox(width: 170, height: 12),
                    ],
                  ),
                ),

                // QR Code Box skeleton
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        AppSkeletonBox(width: 224, height: 224, borderRadius: 12),
                        SizedBox(height: 10),
                        AppSkeletonBox(width: 130, height: 11),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Total Tagihan QRIS skeleton
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: AppSkeletonBox(width: double.infinity, height: 68, borderRadius: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Skeleton Action Buttons Row
          const Row(
            children: [
              Expanded(flex: 3, child: AppSkeletonBox(height: 46, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(flex: 2, child: AppSkeletonBox(height: 46, borderRadius: 14)),
            ],
          ),

          const SizedBox(height: 16),

          // Skeleton Rincian Transaksi Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: 150, height: 12),
                SizedBox(height: 8),
                AppSkeletonBox(width: 190, height: 14),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeletonBox(width: 110, height: 12),
                    AppSkeletonBox(width: 85, height: 14),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeletonBox(width: 90, height: 12),
                    AppSkeletonBox(width: 75, height: 14),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeletonBox(width: 125, height: 14),
                    AppSkeletonBox(width: 95, height: 16),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Skeleton CTA Button
          const AppSkeletonBox(width: double.infinity, height: 50, borderRadius: 14),
        ],
      ),
    );
  }

  Widget _buildGenerationErrorState(Color qrisColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: qrisColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_2_rounded, size: 36, color: qrisColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal Menyiapkan QRIS',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _generationError ?? 'Terjadi kendala saat membuat kode QRIS.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loadOrGenerateQris,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Coba Generate Ulang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: qrisColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({required String step, required String title, required String desc, Color? accentColor}) {
    final effectiveColor = accentColor ?? const Color(0xFFDC2626);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: effectiveColor),
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
