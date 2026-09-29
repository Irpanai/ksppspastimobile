import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class MidtransWebViewScreen extends StatefulWidget {
  final SnapTokenResponse snapResponse;

  const MidtransWebViewScreen({
    Key? key,
    required this.snapResponse,
  }) : super(key: key);

  @override
  State<MidtransWebViewScreen> createState() => _MidtransWebViewScreenState();
}

class _MidtransWebViewScreenState extends State<MidtransWebViewScreen> {
  WebViewController? _controller;
  bool _isLoadingWeb = true;
  double _loadingProgress = 0.0;
  bool _hasSettled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    if (kIsWeb) {
      _isLoadingWeb = false;
      return;
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF8FAFC))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoadingWeb = true;
                });
              }
              _checkUrlForStatus(url);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoadingWeb = false;
                });
              }
              _checkUrlForStatus(url);
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoadingWeb = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              _checkUrlForStatus(request.url);
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.snapResponse.snapRedirectUrl));

      _controller = controller;
    } catch (_) {
      _isLoadingWeb = false;
    }
  }

  void _checkUrlForStatus(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('finish') ||
        lower.contains('settlement') ||
        lower.contains('status_code=200') ||
        lower.contains('transaction_status=settlement')) {
      _triggerStatusCheck(silent: false);
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.snapResponse.snapRedirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka browser eksternal')),
        );
      }
    }
  }

  Future<void> _triggerStatusCheck({bool silent = false}) async {
    final paymentProvider = context.read<PaymentProvider>();
    final status = await paymentProvider.checkStatus(widget.snapResponse.orderId);

    if (!mounted) return;

    if (status != null) {
      if (status.isSettlement) {
        setState(() {
          _hasSettled = true;
        });

        // Refresh global member data
        try {
          context.read<DashboardProvider>().fetchDashboard(refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('sukarela', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('wajib', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('pokok', refresh: true);
        } catch (_) {}

        _showStatusResultDialog(status);
      } else if (!silent) {
        _showStatusResultDialog(status);
      }
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Gagal memeriksa status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showStatusResultDialog(PaymentStatusResponse status) {
    showDialog(
      context: context,
      barrierDismissible: !status.isSettlement,
      builder: (dialogCtx) {
        final isSuccess = status.isSettlement;
        final isPending = status.isPending;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFDCFCE7)
                      : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : (isPending ? Icons.access_time_filled_rounded : Icons.cancel_rounded),
                  color: isSuccess
                      ? const Color(0xFF16A34A)
                      : (isPending ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess
                    ? 'Pembayaran Berhasil!'
                    : (isPending ? 'Menunggu Pembayaran' : 'Status: ${status.status.toUpperCase()}'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Setoran simpanan telah masuk ke akun rekening Anda.'
                    : (isPending
                        ? 'Selesaikan pembayaran melalui metode yang dipilih di Midtrans.'
                        : 'Transaksi belum selesai atau telah kedaluwarsa.'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
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
                    _buildDialogRow('Order ID', status.orderId),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildDialogRow('Nominal', AppCurrency.format(status.nominal), isHighlight: true),
                    if (status.paymentType != null) ...[
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildDialogRow('Metode', status.paymentType!.toUpperCase()),
                    ],
                    if (status.vaNumber != null) ...[
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildDialogRow('No. VA / Pembayaran', status.vaNumber!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    if (isSuccess) {
                      Navigator.pop(context, true); // Return to home/previous screen with success
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isSuccess ? 'Kembali ke Beranda' : 'Tutup',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 14 : 12,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final isChecking = paymentProvider.isCheckingStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Pembayaran Midtrans Snap',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              '${widget.snapResponse.nominalFormat} • ${widget.snapResponse.orderId}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B)),
          onPressed: () {
            if (_hasSettled) {
              Navigator.pop(context, true);
            } else {
              _showConfirmExitDialog();
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Buka di Browser Luar',
            icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF1E293B)),
            onPressed: _openInExternalBrowser,
          ),
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            _buildFallbackView(),
          if (_isLoadingWeb)
            LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.primary,
              minHeight: 3,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isChecking ? null : () => _triggerStatusCheck(silent: false),
                  icon: isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                  label: Text(
                    isChecking ? 'Memeriksa...' : 'Cek Status Pembayaran',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_rounded, color: Theme.of(context).colorScheme.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lanjutkan di Browser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Klik tombol di bawah ini untuk membuka halaman pembayaran Midtrans di browser perangkat Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: const Text('Buka Halaman Midtrans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tutup Pembayaran?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Jika Anda sudah melakukan transfer/pembayaran, status saldo akan otomatis diperbarui setelah proses settlement selesai.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lanjutkan Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tutup Halaman'),
          ),
        ],
      ),
    );
  }
}
