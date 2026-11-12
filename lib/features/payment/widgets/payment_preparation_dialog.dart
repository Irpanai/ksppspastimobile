import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_dialog.dart';

/// Kartu konten persiapan pembayaran yang dipakai bersama oleh QRIS, Virtual
/// Account / Bank, maupun metode pembayaran lainnya saat tombol Bayar Sekarang ditekan.
class PaymentPreparationCard extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String statusText;
  final String helperText;
  final String cancelText;
  final VoidCallback? onCancel;

  const PaymentPreparationCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.statusText,
    required this.helperText,
    this.cancelText = 'Batalkan',
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              cancelText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hasil eksekusi proses asinkron di balik [PaymentPreparationHelper.run].
class PaymentPreparationOutcome<T> {
  final T? data;
  final bool cancelled;
  final Object? error;

  const PaymentPreparationOutcome({
    this.data,
    this.cancelled = false,
    this.error,
  });
}

/// Menjalankan proses pembuatan transaksi sembari menampilkan popup persiapan
/// [PaymentPreparationCard] melalui [AppDialog.showShell] secara seragam.
class PaymentPreparationHelper {
  PaymentPreparationHelper._();

  static Future<PaymentPreparationOutcome<T>> run<T>({
    required BuildContext context,
    required Future<T> Function() task,
    required Color accentColor,
    String title = 'Menyiapkan Pembayaran...',
    String statusText = 'Menghubungkan ke server pembayaran...',
    String helperText =
        'Halaman instruksi pembayaran akan terbuka otomatis setelah kode siap.',
    String cancelText = 'Batalkan',
  }) async {
    BuildContext? loadingDialogContext;
    bool isDialogOpen = true;
    bool isCancelled = false;
    bool isRequestFinished = false;

    void closeLoadingDialog() {
      if (!isDialogOpen) return;
      final ctx = loadingDialogContext;
      if (ctx != null && ctx.mounted) {
        isDialogOpen = false;
        Navigator.of(ctx).pop();
      }
    }

    unawaited(
      AppDialog.showShell<void>(
        context: context,
        barrierDismissible: false,
        child: Builder(
          builder: (dialogCtx) {
            loadingDialogContext = dialogCtx;
            if (isRequestFinished && isDialogOpen) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => closeLoadingDialog());
            }
            return PopScope(
              canPop: false,
              child: PaymentPreparationCard(
                accentColor: accentColor,
                title: title,
                statusText: statusText,
                helperText: helperText,
                cancelText: cancelText,
                onCancel: () {
                  isCancelled = true;
                  closeLoadingDialog();
                },
              ),
            );
          },
        ),
      ).whenComplete(() {
        isDialogOpen = false;
      }),
    );

    T? data;
    Object? error;
    try {
      data = await task();
    } catch (e) {
      error = e;
    } finally {
      isRequestFinished = true;
      closeLoadingDialog();
    }

    if (isCancelled) {
      return const PaymentPreparationOutcome(cancelled: true);
    }
    return PaymentPreparationOutcome<T>(data: data, error: error);
  }
}

