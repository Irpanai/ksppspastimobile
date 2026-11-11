import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../screens/native_qris_screen.dart';
import 'doku_qris_web_bridge.dart';

/// Hasil persiapan QRIS sebelum masuk ke layar Pembayaran QRIS.
class QrisPreparationResult {
  final SnapTokenResponse? payment;
  final Uint8List? qrBytes;
  final String? qrImageUrl;
  final DokuQrisWebController? preloadedWebController;
  final bool cancelled;
  final String? errorMessage;

  const QrisPreparationResult({
    this.payment,
    this.qrBytes,
    this.qrImageUrl,
    this.preloadedWebController,
    this.cancelled = false,
    this.errorMessage,
  });
}

/// Menyiapkan & memuat transaksi QRIS (termasuk preload halaman DOKU Checkout)
/// terlebih dahulu sebelum membuka [NativeQrisScreen], agar QRIS langsung siap tampil.
class QrisPreparationHelper {
  QrisPreparationHelper._();

  static Future<bool?> open(
    BuildContext context, {
    Future<SnapTokenResponse?> Function()? onGeneratePayment,
    SnapTokenResponse? existingPayment,
    bool forceStatusCheckForExisting = true,
  }) async {
    assert(
      onGeneratePayment != null || existingPayment != null,
      'onGeneratePayment atau existingPayment harus diisi',
    );

    final paymentProvider = context.read<PaymentProvider>();

    final prepResult = await showDialog<QrisPreparationResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QrisPreparationDialog(
        paymentProvider: paymentProvider,
        onGeneratePayment: onGeneratePayment,
        existingPayment: existingPayment,
        forceStatusCheckForExisting: forceStatusCheckForExisting,
      ),
    );

    if (!context.mounted) {
      prepResult?.preloadedWebController?.dispose();
      return null;
    }

    if (prepResult == null || prepResult.cancelled) {
      prepResult?.preloadedWebController?.dispose();
      return false;
    }

    if (prepResult.errorMessage != null || prepResult.payment == null) {
      prepResult.preloadedWebController?.dispose();
      await AppDialog.showError(
        context,
        title: 'Pembayaran QRIS Belum Siap',
        message: prepResult.errorMessage ??
            'Gagal menyiapkan transaksi QRIS. Silakan periksa koneksi Anda dan coba kembali.',
      );
      return false;
    }

    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NativeQrisScreen(
          paymentResponse: prepResult.payment,
          initialQrBytes: prepResult.qrBytes,
          initialQrImageUrl: prepResult.qrImageUrl,
          preloadedWebController: prepResult.preloadedWebController,
        ),
      ),
    );
  }
}

class _QrisPreparationDialog extends StatefulWidget {
  final PaymentProvider paymentProvider;
  final Future<SnapTokenResponse?> Function()? onGeneratePayment;
  final SnapTokenResponse? existingPayment;
  final bool forceStatusCheckForExisting;

  const _QrisPreparationDialog({
    required this.paymentProvider,
    this.onGeneratePayment,
    this.existingPayment,
    required this.forceStatusCheckForExisting,
  });

  @override
  State<_QrisPreparationDialog> createState() => _QrisPreparationDialogState();
}

class _QrisPreparationDialogState extends State<_QrisPreparationDialog> {
  String _statusText = 'Menghubungkan ke server pembayaran...';
  bool _cancelled = false;
  DokuQrisWebController? _webCtrl;
  Completer<void>? _activeCompleter;
  Timer? _overallTimer;
  Timer? _postLoadGraceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepare();
    });
  }

  @override
  void dispose() {
    _overallTimer?.cancel();
    _overallTimer = null;
    _postLoadGraceTimer?.cancel();
    _postLoadGraceTimer = null;
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
    _webCtrl?.dispose();
    _webCtrl = null;
    super.dispose();
  }

  void _completeNow() {
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
  }

  void _handleCancel() {
    if (_cancelled) return;
    _cancelled = true;
    _overallTimer?.cancel();
    _postLoadGraceTimer?.cancel();
    _webCtrl?.dispose();
    _webCtrl = null;
    _completeNow();
    if (mounted) {
      Navigator.of(context).pop(const QrisPreparationResult(cancelled: true));
    }
  }

  Future<void> _prepare() async {
    if (_cancelled || !mounted) return;

    SnapTokenResponse? payment = widget.existingPayment;

    // 1. Buat transaksi baru atau muat ulang status transaksi pending
    if (payment == null && widget.onGeneratePayment != null) {
      try {
        payment = await widget.onGeneratePayment!();
      } catch (e) {
        if (!_cancelled && mounted) {
          Navigator.of(context).pop(
            QrisPreparationResult(
              errorMessage: 'Gagal membuat kode QRIS: ${e.toString()}',
            ),
          );
        }
        return;
      }

      if (_cancelled || !mounted) return;
      if (payment == null) {
        Navigator.of(context).pop(
          QrisPreparationResult(
            errorMessage: widget.paymentProvider.errorMessage ??
                'Gagal membuat transaksi QRIS. Silakan periksa koneksi Anda dan coba kembali.',
          ),
        );
        return;
      }
    } else if (payment != null &&
        widget.forceStatusCheckForExisting &&
        (payment.qrString == null || payment.qrString!.trim().isEmpty)) {
      try {
        final status = await widget.paymentProvider
            .checkStatus(payment.orderId)
            .timeout(const Duration(seconds: 4));
        if (_cancelled || !mounted) return;
        final fetchedQr = status?.qrString?.trim() ?? '';
        if (fetchedQr.isNotEmpty) {
          payment = payment.copyWithQr(
            qrString: fetchedQr,
            nmid: status?.nmid ?? payment.nmid,
            expiredDate: status?.expiredDate ?? payment.expiredDate,
          );
          await widget.paymentProvider.updatePendingPayment(payment);
        }
      } catch (_) {}
    }

    if (_cancelled || !mounted || payment == null) return;

    // Jika qr_string EMVCo sudah langsung tersedia dari backend, langsung masuk ke NativeQrisScreen
    if (payment.qrString != null && payment.qrString!.trim().isNotEmpty) {
      Navigator.of(context).pop(QrisPreparationResult(payment: payment));
      return;
    }

    final checkoutUrl = payment.snapRedirectUrl.trim();
    if (checkoutUrl.isEmpty) {
      Navigator.of(context).pop(QrisPreparationResult(payment: payment));
      return;
    }

    // 2. Preload halaman DOKU Checkout & ekstrak QRIS sebelum layar QRIS dibuka
    if (mounted) {
      setState(() {
        _statusText = 'Mengambil kode QRIS resmi DOKU...';
      });
    }

    var activePayment = payment;
    Uint8List? readyBytes;
    String? readyImageUrl;
    var resolvingImage = false;
    final done = Completer<void>();
    _activeCompleter = done;

    final ctrl = DokuQrisWebController();
    final started = ctrl.start(
      url: checkoutUrl,
      onExtracted: (payload) async {
        if (_cancelled || !mounted || done.isCompleted) return;

        if (payload.hasQrString) {
          final updated = activePayment.copyWithQr(qrString: payload.qrString);
          activePayment = updated;
          await widget.paymentProvider.updatePendingPayment(updated);
          if (!done.isCompleted) done.complete();
          return;
        }

        if (payload.hasImageBytes) {
          readyBytes = payload.imageBytes;
          readyImageUrl = null;
          if (!done.isCompleted) done.complete();
          return;
        }

        if (payload.hasImageUrl && !resolvingImage && readyBytes == null) {
          resolvingImage = true;
          if (mounted) {
            setState(() => _statusText = 'Mengunduh gambar QRIS...');
          }
          try {
            final resp = await http
                .get(Uri.parse(payload.imageUrl!))
                .timeout(const Duration(seconds: 5));
            if (resp.statusCode == 200 && resp.bodyBytes.length > 80) {
              readyBytes = resp.bodyBytes;
              readyImageUrl = null;
            } else {
              readyImageUrl = payload.imageUrl;
            }
          } catch (_) {
            readyImageUrl = payload.imageUrl;
          }
          if (!done.isCompleted) done.complete();
        }
      },
      onPaymentFinishedUrl: () {
        if (!done.isCompleted) done.complete();
      },
      onPageFinished: () {
        if (_cancelled || !mounted || done.isCompleted) return;
        setState(() {
          _statusText = 'Menyiapkan tampilan QRIS...';
        });
        _postLoadGraceTimer ??= Timer(const Duration(milliseconds: 2200), () {
          if (!done.isCompleted) done.complete();
        });
      },
    );

    if (!started) {
      ctrl.dispose();
      _activeCompleter = null;
      if (!_cancelled && mounted) {
        Navigator.of(context).pop(QrisPreparationResult(payment: activePayment));
      }
      return;
    }

    if (mounted) {
      setState(() => _webCtrl = ctrl);
    }

    _overallTimer = Timer(const Duration(seconds: 14), () {
      if (!done.isCompleted) done.complete();
    });

    await done.future;

    _overallTimer?.cancel();
    _overallTimer = null;
    _postLoadGraceTimer?.cancel();
    _postLoadGraceTimer = null;
    _activeCompleter = null;

    if (_cancelled || !mounted) {
      ctrl.dispose();
      _webCtrl = null;
      return;
    }

    final hasNativeQr =
        (activePayment.qrString?.trim().isNotEmpty ?? false) ||
        readyBytes != null ||
        readyImageUrl != null;

    if (hasNativeQr) {
      ctrl.dispose();
      _webCtrl = null;
      Navigator.of(context).pop(
        QrisPreparationResult(
          payment: activePayment,
          qrBytes: readyBytes,
          qrImageUrl: readyImageUrl,
        ),
      );
    } else {
      // Serahkan WebViewController yang sudah dimuat langsung ke NativeQrisScreen
      // agar tidak mengulang loading dari awal.
      _webCtrl = null;
      Navigator.of(context).pop(
        QrisPreparationResult(
          payment: activePayment,
          preloadedWebController: ctrl,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const qrisRed = Color(0xFFDC2626);
    final webController = _webCtrl?.webViewController;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (webController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.01,
                      child: OverflowBox(
                        maxWidth: 380,
                        maxHeight: 480,
                        child: SizedBox(
                          width: 340,
                          height: 440,
                          child: WebViewWidget(
                            key: ValueKey('qris_preload_wv_${identityHashCode(webController)}'),
                            controller: webController,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: qrisRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(qrisRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Menyiapkan Kode QRIS...',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'QRIS sedang dimuat hingga siap dipakai sebelum halaman pembayaran dibuka.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _handleCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Batalkan',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

