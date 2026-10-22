import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../sijaka/providers/sijaka_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class NativePaymentDetailScreen extends StatefulWidget {
  final SnapTokenResponse paymentResponse;

  const NativePaymentDetailScreen({
    super.key,
    required this.paymentResponse,
  });

  @override
  State<NativePaymentDetailScreen> createState() => _NativePaymentDetailScreenState();
}

class _NativePaymentDetailScreenState extends State<NativePaymentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;
  Timer? _autoCheckTimer;
  Duration _timeLeft = const Duration(hours: 24);
  bool _isChecking = false;
  bool _hasSettled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCountdown();
    _startAutoPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _tabController.dispose();
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
        _timeLeft = const Duration(hours: 24);
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
    // Polling setiap 8 detik untuk mendeteksi pembayaran realtime tanpa tombol manual
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 8), (_) {
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
            content: Text('Pembayaran belum terdeteksi. Silakan selesaikan transfer lalu coba lagi.'),
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
              'Pembayaran Berhasil!',
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
                      Text(
                        (status.paymentChannel ?? 'Virtual Account').toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Close payment screen with success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label berhasil disalin'),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  Color _getBankThemeColor(String? bank) {
    switch (bank?.toLowerCase()) {
      case 'bca':
        return const Color(0xFF005DAA);
      case 'mandiri':
        return const Color(0xFF003D79);
      case 'bri':
        return const Color(0xFF00529C);
      case 'bni':
        return const Color(0xFFE55300);
      case 'cimb':
        return const Color(0xFF8B0000);
      case 'danamon':
        return const Color(0xFFFF6600);
      case 'bsi':
        return const Color(0xFF00A39D);
      default:
        return const Color(0xFF0F766E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.paymentResponse;
    final bankKey = res.bank?.toLowerCase() ?? 'bca';
    final bankName = res.bankName ?? '${bankKey.toUpperCase()} Virtual Account';
    final vaNumber = res.vaNumber ?? res.orderId;
    final bankColor = _getBankThemeColor(bankKey);

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
            title: const Text('Keluar Halaman Pembayaran?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: const Text(
              'Nomor Virtual Account tetap aktif selama 24 jam. Anda dapat melanjutkan pembayaran melalui aplikasi m-Banking Anda kapan saja.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Tetap di Sini', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Pembayaran Virtual Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Countdown Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selesaikan Pembayaran Dalam',
                            style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDuration(_timeLeft),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Card Nomor Virtual Account
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: bankColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bankKey.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: bankColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              bankName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Menunggu Transfer',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'NOMOR VIRTUAL ACCOUNT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            vaNumber,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(vaNumber, 'Nomor Virtual Account'),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Salin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bankColor.withValues(alpha: 0.1),
                            foregroundColor: bankColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PEMBAYARAN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              res.nominalFormat,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(res.nominal.toString(), 'Nominal Pembayaran'),
                          icon: const Icon(Icons.copy_rounded, size: 15),
                          label: const Text('Salin Nominal'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Rincian Tagihan Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rincian Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildDetailRow('Order ID', res.orderId),
                    const SizedBox(height: 8),
                    _buildDetailRow('Tujuan Setoran', _getTypeLabel(res.type)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Verifikasi', 'Otomatis 24 Jam (Realtime)'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Petunjuk Transfer (Tabs: m-Banking, ATM, Internet Banking)
              const Text(
                'TATA CARA PEMBAYARAN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF0F766E),
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: const Color(0xFF0F766E),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'm-Banking'),
                        Tab(text: 'ATM'),
                        Tab(text: 'i-Banking'),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: SizedBox(
                        height: 240,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInstructionSteps(res.instructions?['m_banking'] ?? _getDefaultInstructions(bankKey, 'm_banking')),
                            _buildInstructionSteps(res.instructions?['atm'] ?? _getDefaultInstructions(bankKey, 'atm')),
                            _buildInstructionSteps(res.instructions?['klik_bca'] ?? _getDefaultInstructions(bankKey, 'i_banking')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Bayar Nanti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : () => _checkStatus(silent: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Cek Status Pembayaran',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildInstructionSteps(dynamic instructionData) {
    List<String> steps = [];
    if (instructionData is Map && instructionData['steps'] is List) {
      steps = (instructionData['steps'] as List).map((e) => e.toString()).toList();
    } else if (instructionData is List) {
      steps = instructionData.map((e) => e.toString()).toList();
    }

    if (steps.isEmpty) {
      steps = [
        'Buka aplikasi mobile banking Anda.',
        'Pilih menu Transfer atau Pembayaran Virtual Account.',
        'Masukkan nomor Virtual Account yang tertera.',
        'Pastikan detail pembayaran telah sesuai dan selesaikan transaksi.',
      ];
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE6FFFA),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                steps[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getDefaultInstructions(String bank, String type) {
    return {
      'steps': [
        'Buka layanan perbankan Anda ($type).',
        'Pilih menu Transfer > Virtual Account.',
        'Masukkan nomor Virtual Account.',
        'Konfirmasi nominal dan masukkan PIN untuk menyelesaikan transaksi.',
      ]
    };
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'simpanan_sukarela':
        return 'Top-Up Simpanan Sukarela';
      case 'simpanan_wajib':
        return 'Simpanan Wajib Bulanan';
      case 'simpanan_pokok':
        return 'Simpanan Pokok Anggota';
      case 'pembukaan_sijaka':
        return 'Setoran Deposito Sijaka';
      default:
        return 'Setoran Simpanan KSPPS';
    }
  }
}
