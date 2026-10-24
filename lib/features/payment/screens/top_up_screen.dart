import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../sijaka/screens/sijaka_submission_screen.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import '../models/payment_channel_model.dart';
import 'doku_webview_screen.dart';
import 'native_payment_detail_screen.dart';
import 'native_qris_screen.dart';
import '../widgets/pending_payments_modal.dart';
import '../../../../core/services/storage_service.dart';

class TopUpScreen extends StatefulWidget {
  final String? initialType; // 'sukarela', 'wajib', 'simpanan_wajib', 'pokok', 'sijaka'
  final int? initialStartMonth;
  final int? initialEndMonth;
  final int? initialYear;

  const TopUpScreen({
    Key? key,
    this.initialType,
    this.initialStartMonth,
    this.initialEndMonth,
    this.initialYear,
  }) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  late String _selectedType;
  final TextEditingController _amountController = TextEditingController(text: '100000');

  // For Simpanan Wajib (Rp 2.500 / bulan)
  static const int _wajibPerBulan = 2500;
  static const int _pokokNominal = 15000;

  late int _wajibStartMonth;
  late int _wajibEndMonth;
  late int _wajibYear;
  bool _isBatchWajib = true; // Default batch mode up to December
  String _selectedPaymentMethod = 'bca';
  String? _lastUsedMethodCode; // Default: BCA Virtual Account (Native)

  final List<int> _presetNominalsSukarela = [
    25000,
    50000,
    100000,
    250000,
    500000,
    1000000,
  ];

  final List<Map<String, dynamic>> _months = [
    {'id': 1, 'name': 'Januari', 'short': 'Jan'},
    {'id': 2, 'name': 'Februari', 'short': 'Feb'},
    {'id': 3, 'name': 'Maret', 'short': 'Mar'},
    {'id': 4, 'name': 'April', 'short': 'Apr'},
    {'id': 5, 'name': 'Mei', 'short': 'Mei'},
    {'id': 6, 'name': 'Juni', 'short': 'Jun'},
    {'id': 7, 'name': 'Juli', 'short': 'Jul'},
    {'id': 8, 'name': 'Agustus', 'short': 'Agt'},
    {'id': 9, 'name': 'September', 'short': 'Sep'},
    {'id': 10, 'name': 'Oktober', 'short': 'Okt'},
    {'id': 11, 'name': 'November', 'short': 'Nov'},
    {'id': 12, 'name': 'Desember', 'short': 'Des'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _wajibStartMonth = widget.initialStartMonth ?? now.month;
    _wajibEndMonth = widget.initialEndMonth ?? 12; // Default up to December (end of year)
    _wajibYear = widget.initialYear ?? now.year;
    StorageService.getLastPaymentMethod().then((saved) {
      if (saved != null && mounted) {
        setState(() {
          _lastUsedMethodCode = saved;
          _selectedPaymentMethod = saved;
        });
      }
    });

    final init = widget.initialType?.toLowerCase();
    if (init == 'wajib' || init == 'simpanan_wajib') {
      _selectedType = 'simpanan_wajib';
      _updateWajibAmount();
    } else if (init == 'pokok' || init == 'simpanan_pokok') {
      _selectedType = 'simpanan_pokok';
      _amountController.text = AppCurrency.format(_pokokNominal).replaceAll('Rp ', '');
    } else if (init == 'sijaka' || init == 'pembukaan_sijaka') {
      _selectedType = 'pembukaan_sijaka';
      _amountController.text = AppCurrency.format(1000000).replaceAll('Rp ', '');
    } else {
      _selectedType = 'simpanan_sukarela';
      _amountController.text = AppCurrency.format(100000).replaceAll('Rp ', '');
    }

    // Ambil kanal pembayaran dinamis yang aktif dari Admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPaymentChannels().then((_) {
        if (!mounted) return;
        final channels = context.read<PaymentProvider>().activeChannels.where((c) => c.isActive).toList();
        if (channels.isNotEmpty && !channels.any((c) => c.code == _selectedPaymentMethod)) {
          setState(() {
            _selectedPaymentMethod = channels.first.code;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    if (_selectedType == 'simpanan_pokok') return _pokokNominal;
    if (_selectedType == 'simpanan_wajib') return _calculateTotalWajib();
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  int _calculateTotalWajib() {
    if (!_isBatchWajib) {
      return _wajibPerBulan;
    }
    final count = (_wajibEndMonth - _wajibStartMonth + 1).clamp(1, 12);
    return count * _wajibPerBulan;
  }

  int get _wajibMonthCount {
    if (!_isBatchWajib) return 1;
    return (_wajibEndMonth - _wajibStartMonth + 1).clamp(1, 12);
  }

  void _updateWajibAmount() {
    final total = _calculateTotalWajib();
    _amountController.text = AppCurrency.format(total).replaceAll('Rp ', '');
  }

  void _onTypeChanged(String type, bool isPokokPaid) {
    if (type == 'simpanan_pokok' && isPokokPaid) {
      _showPokokAlreadyPaidDialog();
      return;
    }

    setState(() {
      _selectedType = type;
      if (type == 'simpanan_sukarela') {
        _amountController.text = AppCurrency.format(100000).replaceAll('Rp ', '');
      } else if (type == 'simpanan_wajib') {
        _updateWajibAmount();
      } else if (type == 'simpanan_pokok') {
        _amountController.text = AppCurrency.format(_pokokNominal).replaceAll('Rp ', '');
      }
    });
  }

  void _showPokokAlreadyPaidDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'Simpanan Pokok Sudah Lunas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Setoran awal Simpanan Pokok sebesar Rp 15.000 telah terverifikasi. Simpanan pokok hanya dibayarkan 1 (satu) kali selama menjadi anggota aktif KSPPS PASTI dan tidak perlu disetor lagi.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bisa dicairkan kembali saat keluar keanggotaan.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceedPayment() async {
    final amount = _parsedAmount;
    if (amount < 1000) {
      AppDialog.showWarning(
        context,
        title: 'Nominal Tidak Sesuai',
        message: 'Nominal pembayaran minimal adalah Rp 1.000.',
      );
      return;
    }

    final activeChannels = context.read<PaymentProvider>().activeChannels.where((c) => c.isActive).toList();
    if (activeChannels.isEmpty) {
      AppDialog.showWarning(
        context,
        title: 'Metode Tidak Tersedia',
        message: 'Tidak ada metode pembayaran yang aktif saat ini. Silakan coba kembali beberapa saat lagi.',
      );
      return;
    }

    StorageService.saveLastPaymentMethod(_selectedPaymentMethod);
    final paymentProvider = context.read<PaymentProvider>();
    final result = await paymentProvider.createPayment(
      type: _selectedType,
      nominal: amount,
      paymentMethod: _selectedPaymentMethod,
      bank: _selectedPaymentMethod != 'checkout' ? _selectedPaymentMethod : null,
      bulan: _selectedType == 'simpanan_wajib' ? _wajibStartMonth : null,
      tahun: _selectedType == 'simpanan_wajib' ? _wajibYear : null,
    );

    if (!mounted) return;

    if (result != null) {
      final Widget targetScreen = result.isDirectQris
          ? NativeQrisScreen(paymentResponse: result)
          : (result.isDirectVa
              ? NativePaymentDetailScreen(paymentResponse: result)
              : DokuWebViewScreen(paymentResponse: result));

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => targetScreen,
        ),
      );

      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Setoran simpanan berhasil diverifikasi!')),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      AppDialog.showError(
        context,
        title: 'Pembayaran Belum Berhasil',
        message: paymentProvider.errorMessage ?? 'Gagal membuat transaksi pembayaran. Silakan periksa kembali rincian pembayaran Anda.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>().dashboardData?.ringkasanSaldo;
    final isPokokPaid = (dashboard?.saldoPokok ?? 0) >= _pokokNominal;
    final paymentProvider = context.watch<PaymentProvider>();
    final isCreating = paymentProvider.isCreatingToken;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Setor & Top Up Simpanan',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saldo Info Banner
                  _buildBalanceBanner(dashboard),
                  if (paymentProvider.pendingPayments.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildActivePendingBanner(context, paymentProvider.pendingPayments),
                    ],
                  const SizedBox(height: 24),

                  // Jenis Simpanan Selector
                  const Text(
                    'PILIH JENIS SIMPANAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(isPokokPaid),
                  const SizedBox(height: 24),

                  // Content based on selected type
                  if (_selectedType == 'pembukaan_sijaka') ...[
                    _buildSijakaPromoCard(),
                  ] else if (_selectedType == 'simpanan_pokok') ...[
                    _buildPokokSection(isPokokPaid),
                  ] else if (_selectedType == 'simpanan_wajib') ...[
                    _buildWajibBatchSection(),
                  ] else ...[
                    _buildSukarelaSection(),
                  ],

                  if (_selectedType != 'pembukaan_sijaka') ...[
                    const SizedBox(height: 20),
                    _buildPaymentMethodNotice(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedType != 'pembukaan_sijaka'
          ? _buildBottomBar(isCreating, isPokokPaid)
          : null,
    );
  }

  Widget _buildActivePendingBanner(BuildContext context, List<SnapTokenResponse> pendingList) {
    if (pendingList.isEmpty) return const SizedBox.shrink();
    final first = pendingList.first;
    final count = pendingList.length;

    final title = count > 1 ? 'Ada $count Pembayaran Menunggu' : 'Ada Pembayaran Menunggu Transfer';
    final subtitle = count > 1
        ? '${first.displayPaymentMethod} dan ${count - 1} lainnya • Ketuk untuk lihat'
        : '${first.displayPaymentMethod} • ${first.nominalFormat}';

    return InkWell(
      onTap: () => PendingPaymentsModal.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => PendingPaymentsModal.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Buka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBanner(dynamic dashboard) {
    num activeBalance = 0;
    String label = 'Saldo Sirela (Sukarela)';
    if (_selectedType == 'simpanan_wajib') {
      activeBalance = dashboard?.saldoWajib ?? 0;
      label = 'Saldo Simpanan Wajib';
    } else if (_selectedType == 'simpanan_pokok') {
      activeBalance = dashboard?.saldoPokok ?? 0;
      label = 'Saldo Simpanan Pokok';
    } else if (_selectedType == 'pembukaan_sijaka') {
      activeBalance = dashboard?.saldoSijaka ?? 0;
      label = 'Total Modal Sijaka Aktif';
    } else {
      activeBalance = dashboard?.saldoSukarela ?? 0;
      label = 'Saldo Sirela (Sukarela)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    AppCurrency.format(activeBalance),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          )
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isPokokPaid) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'simpanan_sukarela',
                title: 'Sirela (Sukarela)',
                subtitle: 'Bebas setor & tarik',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeCard(
                type: 'simpanan_wajib',
                title: 'Simpanan Wajib',
                subtitle: 'Rp 2.500/bln',
                icon: Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'simpanan_pokok',
                title: 'Simpanan Pokok',
                subtitle: isPokokPaid ? 'Sudah Lunas' : 'Rp 15.000 (1x)',
                icon: Icons.shield_outlined,
                isLocked: isPokokPaid,
                isSuccessBadge: isPokokPaid,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeCard(
                type: 'pembukaan_sijaka',
                title: 'Sijaka (Berjangka)',
                subtitle: 'Bagi hasil bulanan',
                icon: Icons.pie_chart_outline_rounded,
                isHighlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isHighlight = false,
    bool isLocked = false,
    bool isSuccessBadge = false,
  }) {
    final isSelected = _selectedType == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTypeChanged(type, isLocked),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                : (isLocked ? const Color(0xFFF1F5F9).withOpacity(0.7) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.04 : 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuccessBadge ? Icons.check_circle_outline_rounded : icon,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocked)
                          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSuccessBadge ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        fontWeight: isSuccessBadge ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // --- 1. SIMPANAN SUKARELA (SIRELA) SECTION ---
  Widget _buildSukarelaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Ketentuan Sirela (Simpanan Sukarela)',
          desc: 'Bebas disetor dan ditarik kapan saja tanpa bunga/bagi hasil. Saldo dapat ditarik sewaktu-waktu sesuai kebutuhan.',
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        const SizedBox(height: 20),
        _buildNominalInputCard(),
        const SizedBox(height: 18),
        const Text(
          'Pilihan Cepat Nominal',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 10),
        _buildPresetChips(),
      ],
    );
  }

  // --- 2. SIMPANAN WAJIB SECTION (WITH BATCH PAYMENT) ---
  Widget _buildWajibBatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Ketentuan Simpanan Wajib (Rp 2.500 / Bulan)',
          desc: 'Iuran rutin wajib untuk memelihara keaktifan keanggotaan. Anda dapat melunasi sekaligus (batch) hingga akhir tahun (Desember).',
          icon: Icons.event_repeat_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        const SizedBox(height: 20),

        // Mode Switcher: 1 Bulan vs Batch Hingga Akhir Tahun
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isBatchWajib = true;
                      _wajibEndMonth = 12;
                      _updateWajibAmount();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isBatchWajib ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isBatchWajib
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      'Batch Hingga Akhir Tahun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isBatchWajib ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isBatchWajib = false;
                      _updateWajibAmount();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isBatchWajib ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_isBatchWajib
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      'Bayar 1 Bulan Saja',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !_isBatchWajib ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Picker Periode
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBatchWajib ? 'Pilih Rentang Bulan' : 'Pilih Bulan Iuran',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tahun $_wajibYear',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isBatchWajib) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dari Bulan:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _wajibStartMonth,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                items: _months.map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m['id'] as int,
                                    child: Text(m['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _wajibStartMonth = val;
                                      if (_wajibEndMonth < val) _wajibEndMonth = val;
                                      _updateWajibAmount();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sampai Bulan:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _wajibEndMonth,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                items: _months.where((m) => (m['id'] as int) >= _wajibStartMonth).map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m['id'] as int,
                                    child: Text(m['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _wajibEndMonth = val;
                                      _updateWajibAmount();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _wajibStartMonth,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      items: _months.map((m) {
                        return DropdownMenuItem<int>(
                          value: m['id'] as int,
                          child: Text(m['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _wajibStartMonth = val;
                            _updateWajibAmount();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Rincian Batch Wajib
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_wajibMonthCount Bulan x ${AppCurrency.format(_wajibPerBulan)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isBatchWajib
                            ? '${_months[_wajibStartMonth - 1]['short']} - ${_months[_wajibEndMonth - 1]['short']} $_wajibYear'
                            : '${_months[_wajibStartMonth - 1]['name']} $_wajibYear',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  Text(
                    AppCurrency.format(_calculateTotalWajib()),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. SIMPANAN POKOK SECTION ---
  Widget _buildPokokSection(bool isPokokPaid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Ketentuan Simpanan Pokok (Rp 15.000)',
          desc: 'Setoran awal saat mendaftar keanggotaan. Hanya disetor 1 kali selama menjadi anggota aktif dan tidak bisa diambil kecuali saat keluar keanggotaan (dicairkan saat RAT).',
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nominal Simpanan Pokok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPokokPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPokokPaid ? 'LUNAS' : 'WAJIB AWAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isPokokPaid ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppCurrency.format(_pokokNominal),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                '*Nominal tetap Rp 15.000 (tidak dapat diubah)',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 11, color: iconColor.withOpacity(0.85), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominalInputCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nominal Setoran Sukarela',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: Row(
            children: [
              const Text(
                'Rp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_amountController.text.isNotEmpty)
                InkWell(
                  onTap: () {
                    _amountController.clear();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '*Minimum transaksi Rp 1.000',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetNominalsSukarela.map((nom) {
        final isSelected = _parsedAmount == nom;
        return InkWell(
          onTap: () {
            _amountController.text = AppCurrency.format(nom).replaceAll('Rp ', '');
            setState(() {});
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              AppCurrency.format(nom),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodNotice() {
    final providerChannels = context.watch<PaymentProvider>().activeChannels;
    final channels = providerChannels.where((c) => c.isActive).toList();

    if (channels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Saat ini seluruh kanal pembayaran online sedang dalam pemeliharaan sistem. Silakan coba beberapa saat lagi atau hubungi kantor KSPPS PASTI.',
                style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final selectedChannel = channels.firstWhere(
      (c) => c.code == _selectedPaymentMethod,
      orElse: () => channels.first,
    );

    // Bangun daftar saran (hanya 2 atau 3 pilihan terkurasi)
    final List<_PaymentSuggestionItem> suggestions = [];

    // 1. Saran Pertama: Riwayat Digunakan / Sering Digunakan
    final historyCode = _lastUsedMethodCode ?? 'bsi';
    PaymentChannelModel historyChannel = channels.firstWhere(
      (c) => c.code.toLowerCase() == historyCode.toLowerCase(),
      orElse: () => channels.firstWhere(
        (c) => c.code.toLowerCase() == 'bsi',
        orElse: () => channels.first,
      ),
    );

    suggestions.add(_PaymentSuggestionItem(
      channel: historyChannel,
      badgeText: _lastUsedMethodCode != null ? 'Riwayat Digunakan' : 'Sering Digunakan',
      badgeIcon: _lastUsedMethodCode != null ? Icons.history_rounded : Icons.star_rounded,
      badgeColor: const Color(0xFF0F766E),
    ));

    // 2. Saran Kedua: QRIS (Semua Bank & E-Wallet)
    PaymentChannelModel? qrisChannel;
    try {
      qrisChannel = channels.firstWhere((c) => c.code.toLowerCase() == 'qris');
    } catch (_) {}

    if (qrisChannel != null && qrisChannel.code != historyChannel.code) {
      suggestions.add(_PaymentSuggestionItem(
        channel: qrisChannel,
        badgeText: 'Saran Instan',
        badgeIcon: Icons.electric_bolt_rounded,
        badgeColor: const Color(0xFFDC2626),
      ));
    }

    // 3. Saran Ketiga (Opsional): Jika pengguna memilih metode di luar item 1 & 2
    if (_selectedPaymentMethod != historyChannel.code &&
        (qrisChannel == null || _selectedPaymentMethod != qrisChannel.code)) {
      final activeChannel = channels.firstWhere(
        (c) => c.code == _selectedPaymentMethod,
        orElse: () => channels.first,
      );
      suggestions.add(_PaymentSuggestionItem(
        channel: activeChannel,
        badgeText: 'Pilihan Anda',
        badgeIcon: Icons.check_circle_outline_rounded,
        badgeColor: const Color(0xFF2563EB),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with "Lihat Semua"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'METODE PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _showPaymentMethodSelector(context, channels),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih Lainnya (${channels.length})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF0F766E),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Selected Method Card (Compact, Elegant, Tap-to-Change)
        InkWell(
          onTap: () => _showPaymentMethodSelector(context, channels),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF0F766E),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedChannel.tagColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selectedChannel.icon,
                    color: selectedChannel.tagColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              selectedChannel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedChannel.badge != null && selectedChannel.badge!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: selectedChannel.code == 'bsi'
                                    ? const Color(0xFFE6FFFA)
                                    : (selectedChannel.code == 'qris'
                                        ? const Color(0xFFFEF2F2)
                                        : const Color(0xFFF0FDF4)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selectedChannel.code == 'bsi'
                                      ? const Color(0xFF00A39D).withValues(alpha: 0.3)
                                      : (selectedChannel.code == 'qris'
                                          ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                                          : const Color(0xFF16A34A).withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Text(
                                selectedChannel.badge!,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: selectedChannel.code == 'bsi'
                                      ? const Color(0xFF00A39D)
                                      : (selectedChannel.code == 'qris'
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF15803D)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedChannel.description ?? 'Transfer instan otomatis 24 jam',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: const [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 2),
                              Text(
                                'Instan 24 Jam',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          Text('•', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                          Text(
                            'Bebas Biaya Admin',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Ubah',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Header Saran Rekomendasi
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF0F766E)),
            SizedBox(width: 5),
            Text(
              'SARAN METODE (SERING DIGUNAKAN)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Pilihan Saran Rekomendasi (Hanya 2 atau 3 Item Terkurasi)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...suggestions.map((item) {
                final isSel = item.channel.code == _selectedPaymentMethod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = item.channel.code;
                      });
                      StorageService.saveLastPaymentMethod(item.channel.code);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                          width: isSel ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          if (isSel)
                            BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge Teks (Riwayat Digunakan / Saran Instan)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFDCFCE7)
                                  : item.badgeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.badgeIcon,
                                  size: 11,
                                  color: isSel ? const Color(0xFF15803D) : item.badgeColor,
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  item.badgeText,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? const Color(0xFF15803D) : item.badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            item.channel.icon,
                            size: 15,
                            color: item.channel.tagColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _getShortChannelName(item.channel),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              color: isSel ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                            ),
                          ),
                          if (isSel) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF0F766E)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Tombol Semua Metode
              InkWell(
                onTap: () => _showPaymentMethodSelector(context, channels),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        '+ Semua (${channels.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

    void _showPaymentMethodSelector(BuildContext context, List<PaymentChannelModel> channels) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final vaChannels = channels.where((c) => c.category.toLowerCase() == 'virtual_account').toList();
        final qrisChannels = channels.where((c) => c.category.toLowerCase() == 'qris').toList();
        final otherChannels = channels.where((c) =>
            c.category.toLowerCase() != 'virtual_account' &&
            c.category.toLowerCase() != 'qris'
        ).toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag bar & Header
              Container(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pilih Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Verifikasi instan otomatis 24 jam tanpa antre',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Scrollable Channel Groups
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Group 1: Virtual Account
                    if (vaChannels.isNotEmpty) ...[
                      _buildCategoryHeader(
                        title: 'Virtual Account (Transfer Bank)',
                        subtitle: 'Transfer via BSI Mobile, m-BCA, Livin, BRImo, & ATM',
                        icon: Icons.account_balance_rounded,
                        count: vaChannels.length,
                      ),
                      const SizedBox(height: 10),
                      ...vaChannels.map((ch) => _buildBottomSheetChannelTile(ctx, ch)),
                      const SizedBox(height: 18),
                    ],

                    // Group 2: QRIS & Dompet Digital
                    if (qrisChannels.isNotEmpty) ...[
                      _buildCategoryHeader(
                        title: 'QRIS & Dompet Digital',
                        subtitle: 'Scan QRIS via BCA, Mandiri, BRI, BSI, GoPay, OVO, Dana',
                        icon: Icons.qr_code_scanner_rounded,
                        count: qrisChannels.length,
                      ),
                      const SizedBox(height: 10),
                      ...qrisChannels.map((ch) => _buildBottomSheetChannelTile(ctx, ch)),
                      const SizedBox(height: 18),
                    ],

                    // Group 3: Other Channels (e.g. Checkout)
                    if (otherChannels.isNotEmpty) ...[
                      _buildCategoryHeader(
                        title: 'Kanal Pembayaran Lainnya',
                        subtitle: 'Gateway pembayaran terintegrasi',
                        icon: Icons.payment_rounded,
                        count: otherChannels.length,
                      ),
                      const SizedBox(height: 10),
                      ...otherChannels.map((ch) => _buildBottomSheetChannelTile(ctx, ch)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetChannelTile(BuildContext sheetContext, PaymentChannelModel ch) {
    final isSelected = _selectedPaymentMethod == ch.code;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = ch.code;
          });
          Navigator.pop(sheetContext);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ch.tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ch.icon,
                  color: ch.tagColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ch.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ch.badge != null && ch.badge!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ch.code == 'bsi'
                                  ? const Color(0xFFE6FFFA)
                                  : (ch.code == 'qris'
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFDCFCE7)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ch.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: ch.code == 'bsi'
                                    ? const Color(0xFF00A39D)
                                    : (ch.code == 'qris'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF15803D)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ch.description ?? 'Transfer instan otomatis 24 jam',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortChannelName(PaymentChannelModel ch) {
    final code = ch.code.toLowerCase();
    if (code == 'bsi') return 'BSI Syariah';
    if (code == 'qris') return 'QRIS Instan';
    if (code == 'bca') return 'BCA VA';
    if (code == 'mandiri') return 'Mandiri VA';
    if (code == 'bri') return 'BRIVA';
    if (code == 'bni') return 'BNI VA';
    if (code == 'cimb') return 'CIMB VA';
    if (code == 'danamon') return 'Danamon VA';
    if (code == 'checkout') return 'DOKU Gateway';
    return ch.name.replaceAll(' Virtual Account', ' VA');
  }

    Widget _buildSijakaPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('INVESTASI SYARIAH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.auto_graph_rounded, color: Color(0xFFFBBF24), size: 24),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Simpanan Berjangka (Sijaka)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Investasi amanah dengan bagi hasil kompetitif setiap bulan. Pilihan tenor 1, 6, dan 12 bulan.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SijakaSubmissionScreen()),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Buka Pengajuan Bilyet Sijaka'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isCreating, bool isPokokPaid) {
    final isDisabled = _selectedType == 'simpanan_pokok' && isPokokPaid;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  AppCurrency.format(_parsedAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (isCreating || isDisabled)
                    ? (isDisabled ? () => _showPokokAlreadyPaidDialog() : null)
                    : _handleProceedPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? const Color(0xFF94A3B8) : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: isDisabled ? 0 : 2,
                ),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isDisabled ? 'Sudah Lunas' : 'Bayar Sekarang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSuggestionItem {
  final PaymentChannelModel channel;
  final String badgeText;
  final IconData badgeIcon;
  final Color badgeColor;

  const _PaymentSuggestionItem({
    required this.channel,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeColor,
  });
}