import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../sijaka/providers/sijaka_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class DokuWebViewScreen extends StatefulWidget {
  final SnapTokenResponse paymentResponse;

  const DokuWebViewScreen({
    super.key,
    required this.paymentResponse,
  });

  @override
  State<DokuWebViewScreen> createState() => _DokuWebViewScreenState();
}

class _DokuWebViewScreenState extends State<DokuWebViewScreen> {
  WebViewController? _controller;
  bool _isLoadingWeb = true;
  double _loadingProgress = 0.0;
  bool _hasSettled = false;

  String get _paymentUrl {
    final url = widget.paymentResponse.paymentUrl;
    if (url.isNotEmpty) return url;
    return widget.paymentResponse.snapRedirectUrl;
  }

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
            onNavigationRequest: (NavigationRequest request) async {
              final url = request.url;
              final uri = Uri.tryParse(url);

              // 1. Tangani deep-link e-Wallet & Banking Apps (GoPay, ShopeePay, OVO, DANA, BSI Mobile, intent://)
              if (uri != null &&
                  !uri.scheme.startsWith('http') &&
                  !uri.scheme.startsWith('https')) {
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationDecision.prevent;
                  }
                } catch (e) {
                  debugPrint('[DokuWebView] Deep-link error: $e');
                }
              }

              // 2. Deteksi Halaman Selesai Pembayaran
              _checkUrlForStatus(url);
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_paymentUrl));

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
        lower.contains('status=success') ||
        lower.contains('status=settlement') ||
        lower.contains('transaction_status=settlement')) {
      _triggerStatusCheck(silent: false);
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.tryParse(_paymentUrl);
    if (uri != null && await canLaunchUrl(uri)) {
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
    final status = await paymentProvider.checkStatus(widget.paymentResponse.orderId);

    if (!mounted) return;

    if (status != null) {
      if (status.isSettlement) {
        setState(() {
          _hasSettled = true;
        });

        // Refresh global member providers
        try {
          context.read<DashboardProvider>().fetchDashboard(refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('sukarela', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('wajib', refresh: true);
          context.read<SavingsProvider>().fetchRiwayat('pokok', refresh: true);
          context.read<SijakaProvider>().fetchBilyetList(refresh: true);
        } catch (_) {}

        _showStatusResultDialog(status);
      } else if (!silent) {
        _showStatusResultDialog(status);
      }
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Gagal memeriksa status pembayaran'),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFF0FDF4)
                      : (isPending ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : (isPending ? Icons.access_time_filled_rounded : Icons.cancel_rounded),
                  size: 40,
                  color: isSuccess
                      ? const Color(0xFF16A34A)
                      : (isPending ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSuccess
                    ? 'Pembayaran Berhasil!'
                    : (isPending ? 'Menunggu Pembayaran' : 'Pembayaran Dibatalkan'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Transaksi Anda telah diterima dan saldo simpanan berhasil ditambahkan.'
                    : (isPending
                        ? 'Selesaikan pembayaran melalui channel yang Anda pilih di DOKU Checkout.'
                        : 'Transaksi gagal atau dibatalkan oleh pengguna.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        const Text('Nominal:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          AppCurrency.format(status.nominal),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          status.orderId.length > 18
                              ? '${status.orderId.substring(0, 18)}...'
                              : status.orderId,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    if (status.paymentChannel != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Channel:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text(
                            status.paymentChannel!.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0E7955)),
                          ),
                        ],
                      ),
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
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF64748B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isSuccess ? 'Kembali ke Dashboard' : 'Tutup',
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_hasSettled) {
          Navigator.pop(context, true);
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Batalkan Transaksi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari halaman pembayaran? Anda tetap dapat melanjutkan pembayaran sebelum batas waktu berakhir.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Lanjutkan Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'DOKU Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 14),
                ],
              ),
              Text(
                'Order ID: ${widget.paymentResponse.orderId}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 1,
          shadowColor: Colors.black12,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Muat Ulang',
              onPressed: () {
                _controller?.reload();
                _triggerStatusCheck(silent: true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Buka di Browser',
              onPressed: _openInExternalBrowser,
            ),
          ],
        ),
        body: Stack(
          children: [
            if (kIsWeb)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_rounded, size: 64, color: primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Pembayaran Digital DOKU Checkout',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan klik tombol di bawah untuk membuka halaman pembayaran DOKU di browser Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openInExternalBrowser,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Buka Halaman DOKU'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _triggerStatusCheck(silent: false),
                        child: const Text('Cek Status Pembayaran'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_controller != null)
              WebViewWidget(controller: _controller!)
            else
              const Center(child: Text('Gagal memuat WebView')),

            // Loading Progress Bar
            if (_isLoadingWeb && !kIsWeb)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 3.5,
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(
                        widget.paymentResponse.nominalFormat,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _triggerStatusCheck(silent: false),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Cek Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
