import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/dashboard_alert_banner.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../home/models/dashboard_model.dart';
import '../../sijaka/screens/sijaka_submission_screen.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import '../models/payment_channel_model.dart';
import 'doku_webview_screen.dart';
import 'native_payment_detail_screen.dart';
import '../widgets/payment_preparation_dialog.dart';
import '../widgets/qris_preparation_dialog.dart';
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
  bool _activationBatchUntilDec = false; // Default Pokok + Wajib bulan ini (Rp 17.500), opsional lunas s/d Des
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

  bool _hasInitializedWajib = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Membaca status tunggakan iuran dari akun anggota
    final dashboardAnggota = context.read<DashboardProvider>().dashboardData?.anggota;
    if (dashboardAnggota != null && dashboardAnggota.tunggakanWajib.isNotEmpty) {
      final firstT = dashboardAnggota.tunggakanWajib.first;
      final lastT = dashboardAnggota.tunggakanWajib.last;
      _wajibStartMonth = widget.initialStartMonth ?? firstT.bulan;
      _wajibEndMonth = widget.initialEndMonth ?? lastT.bulan;
      _wajibYear = widget.initialYear ?? firstT.tahun;
      _hasInitializedWajib = true;
    } else {
      final minMonth = (dashboardAnggota?.tahunDaftar == now.year && dashboardAnggota?.bulanDaftar != null)
          ? dashboardAnggota!.bulanDaftar!
          : now.month;
      final effectiveStart = widget.initialStartMonth ?? (now.month < minMonth ? minMonth : now.month);
      _wajibStartMonth = effectiveStart;
      _wajibEndMonth = widget.initialEndMonth ?? 12; // Default up to December (end of year)
      _wajibYear = widget.initialYear ?? now.year;
    }

    StorageService.getLastPaymentMethod().then((saved) {
      if (saved != null && mounted) {
        setState(() {
          _lastUsedMethodCode = saved;
          _selectedPaymentMethod = saved;
        });
      }
    });

    final init = widget.initialType?.toLowerCase();
    if (init == 'simpanan_pokok_wajib' || init == 'pokok_wajib' || init == 'registrasi' || init == 'aktivasi') {
      _selectedType = 'simpanan_pokok_wajib';
      _updateActivationAmount();
    } else if (init == 'wajib' || init == 'simpanan_wajib') {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedWajib && widget.initialStartMonth == null) {
      final dashboardAnggota = context.read<DashboardProvider>().dashboardData?.anggota;
      final now = DateTime.now();
      if (dashboardAnggota != null) {
        if (dashboardAnggota.tunggakanWajib.isNotEmpty) {
          final firstT = dashboardAnggota.tunggakanWajib.first;
          final lastT = dashboardAnggota.tunggakanWajib.last;
          _wajibStartMonth = firstT.bulan;
          _wajibEndMonth = lastT.bulan;
          _wajibYear = firstT.tahun;
        } else {
          final minMonth = (dashboardAnggota.tahunDaftar == now.year && dashboardAnggota.bulanDaftar != null)
              ? dashboardAnggota.bulanDaftar!
              : now.month;
          _wajibStartMonth = now.month < minMonth ? minMonth : now.month;
          _wajibEndMonth = 12;
          _wajibYear = now.year;
        }
        _hasInitializedWajib = true;
        if (_selectedType == 'simpanan_wajib') {
          _updateWajibAmount();
        } else if (_selectedType == 'simpanan_pokok_wajib') {
          _updateActivationAmount();
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _activationEndMonth => _activationBatchUntilDec ? 12 : _wajibStartMonth;

  int get _activationMonthCount =>
      (_activationEndMonth - _wajibStartMonth + 1).clamp(1, 12);

  int _calculateTotalActivation() {
    return _pokokNominal + (_activationMonthCount * _wajibPerBulan);
  }

  void _updateActivationAmount() {
    _amountController.text =
        AppCurrency.format(_calculateTotalActivation()).replaceAll('Rp ', '');
  }

  int get _parsedAmount {
    if (_selectedType == 'simpanan_pokok') return _pokokNominal;
    if (_selectedType == 'simpanan_pokok_wajib') return _calculateTotalActivation();
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
    if ((type == 'simpanan_pokok' || type == 'simpanan_pokok_wajib') && isPokokPaid) {
      _showPokokAlreadyPaidDialog();
      return;
    }

    setState(() {
      _selectedType = type;
      if (type == 'simpanan_sukarela') {
        _amountController.text = AppCurrency.format(100000).replaceAll('Rp ', '');
      } else if (type == 'simpanan_wajib') {
        final anggota = context.read<DashboardProvider>().dashboardData?.anggota;
        if (anggota != null && anggota.tunggakanWajib.isNotEmpty && widget.initialStartMonth == null) {
          _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
          _wajibEndMonth = anggota.tunggakanWajib.last.bulan;
          _wajibYear = anggota.tunggakanWajib.first.tahun;
        }
        _updateWajibAmount();
      } else if (type == 'simpanan_pokok_wajib') {
        final anggota = context.read<DashboardProvider>().dashboardData?.anggota;
        if (anggota != null && anggota.tunggakanWajib.isNotEmpty && widget.initialStartMonth == null) {
          _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
          _wajibYear = anggota.tunggakanWajib.first.tahun;
        }
        _updateActivationAmount();
      } else if (type == 'simpanan_pokok') {
        _amountController.text = AppCurrency.format(_pokokNominal).replaceAll('Rp ', '');
      }
    });
  }

  void _showPokokAlreadyPaidDialog() {
    AppDialog.showInfo(
      context,
      title: 'Simpanan Pokok Sudah Lunas',
      message:
          'Setoran awal Simpanan Pokok sebesar Rp 15.000 telah terverifikasi. Simpanan pokok hanya dibayarkan 1 (satu) kali selama menjadi anggota aktif KSPPS PASTI dan tidak perlu disetor lagi.',
      icon: Icons.check_circle_rounded,
      primaryColor: const Color(0xFF16A34A),
      buttonText: 'Mengerti',
      customContent: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bisa dicairkan kembali saat keluar keanggotaan.',
                style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
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

    PaymentChannelModel? selectedChannel;
    for (final channel in activeChannels) {
      if (channel.code.toLowerCase() == _selectedPaymentMethod.toLowerCase()) {
        selectedChannel = channel;
        break;
      }
    }

    final isQrisSelected = _selectedPaymentMethod.toLowerCase() == 'qris';

    Future<SnapTokenResponse?> triggerCreatePayment() {
      final int? paramBulan = (_selectedType == 'simpanan_wajib' || _selectedType == 'simpanan_pokok_wajib')
          ? _wajibStartMonth
          : null;
      final int? paramBulanAkhir = _selectedType == 'simpanan_wajib'
          ? (_isBatchWajib ? _wajibEndMonth : null)
          : (_selectedType == 'simpanan_pokok_wajib' ? _activationEndMonth : null);
      final int? paramTahun = (_selectedType == 'simpanan_wajib' || _selectedType == 'simpanan_pokok_wajib')
          ? _wajibYear
          : null;

      return paymentProvider.createPayment(
        type: _selectedType,
        nominal: amount,
        paymentMethod: _selectedPaymentMethod,
        bank: _selectedPaymentMethod != 'checkout' ? _selectedPaymentMethod : null,
        bulan: paramBulan,
        bulanAkhir: paramBulanAkhir,
        tahun: paramTahun,
      );
    }

    bool? success;

    // Untuk QRIS maupun VA / Bank: tampilkan popup persiapan terpadu yang seragam
    if (isQrisSelected) {
      success = await QrisPreparationHelper.open(
        context,
        onGeneratePayment: triggerCreatePayment,
        accentColor: selectedChannel?.tagColor ?? const Color(0xFFDC2626),
      );
    } else {
      final accentColor = selectedChannel?.tagColor ?? Theme.of(context).colorScheme.primary;
      final outcome = await PaymentPreparationHelper.run<SnapTokenResponse?>(
        context: context,
        task: triggerCreatePayment,
        accentColor: accentColor,
        title: 'Menyiapkan Pembayaran...',
        statusText: 'Menghubungkan ke server pembayaran...',
        helperText: 'Halaman instruksi pembayaran akan terbuka otomatis setelah kode siap.',
      );

      if (!mounted || outcome.cancelled) return;
      final result = outcome.data;

      if (result != null) {
        final isQris = result.isDirectQris ||
            result.paymentMethod.toLowerCase() == 'qris' ||
            result.bank?.toLowerCase() == 'qris';

        if (isQris) {
          success = await QrisPreparationHelper.open(
            context,
            existingPayment: result,
            forceStatusCheckForExisting: false,
          );
        } else {
          final Widget targetScreen = result.isDirectVa
              ? NativePaymentDetailScreen(paymentResponse: result)
              : DokuWebViewScreen(paymentResponse: result);

          success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => targetScreen,
            ),
          );
        }
      } else {
        AppDialog.showError(
          context,
          title: 'Pembayaran Belum Berhasil',
          message: paymentProvider.errorMessage ?? 'Gagal membuat transaksi pembayaran. Silakan periksa kembali rincian pembayaran Anda.',
        );
      }
    }

    if (success == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = context.watch<DashboardProvider>().dashboardData;
    final dashboard = dashboardData?.ringkasanSaldo;
    final anggota = dashboardData?.anggota;
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
                  _buildBalanceBanner(dashboard, anggota),
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
                  ] else if (_selectedType == 'simpanan_pokok_wajib' && !isPokokPaid) ...[
                    _buildPokokWajibSection(),
                  ] else if (_selectedType == 'simpanan_pokok') ...[
                    _buildPokokSection(isPokokPaid),
                  ] else if (_selectedType == 'simpanan_wajib') ...[
                    _buildWajibBatchSection(anggota),
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

    return DashboardAlertBanner.amber(
      margin: EdgeInsets.zero,
      title: title,
      subtitle: subtitle,
      actionLabel: 'Buka',
      icon: Icons.receipt_long_rounded,
      onCardTap: () => PendingPaymentsModal.show(context),
      onActionTap: () => PendingPaymentsModal.show(context),
    );
  }

  Widget _buildBalanceBanner(dynamic dashboard, [DashboardAnggota? anggota]) {
    num activeBalance = 0;
    String label = 'Saldo Sirela (Sukarela)';
    if (_selectedType == 'simpanan_pokok_wajib') {
      activeBalance = (dashboard?.saldoPokok ?? 0) + (dashboard?.saldoWajib ?? 0);
      label = 'Saldo Aktivasi (Pokok + Wajib)';
    } else if (_selectedType == 'simpanan_wajib') {
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
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isPokokPaid) {
    return Column(
      children: [
        if (!isPokokPaid) ...[
          _buildTypeCard(
            type: 'simpanan_pokok_wajib',
            title: 'Aktivasi Anggota (Pokok + Wajib)',
            subtitle: 'Bayar Simpanan Pokok Rp 15.000 + Wajib sekaligus • 1x biaya layanan',
            badgeText: 'Khusus Baru',
            icon: Icons.how_to_reg_rounded,
            isHighlight: true,
            isSuccessBadge: true,
          ),
          const SizedBox(height: 10),
        ],
        _buildTypeCard(
          type: 'simpanan_sukarela',
          title: 'Sirela (Simpanan Sukarela)',
          subtitle: 'Bebas setor dan tarik kapan saja sesuai kebutuhan',
          badgeText: 'Fleksibel',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        _buildTypeCard(
          type: 'simpanan_wajib',
          title: 'Simpanan Wajib',
          subtitle: 'Kewajiban rutin bulanan anggota • Rp 2.500/bulan',
          badgeText: 'Wajib Bulanan',
          icon: Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 10),
        _buildTypeCard(
          type: 'simpanan_pokok',
          title: 'Simpanan Pokok',
          subtitle: isPokokPaid
              ? 'Simpanan pokok awal keanggotaan telah lunas'
              : 'Kewajiban awal keanggotaan • Rp 15.000 (1x bayar)',
          badgeText: isPokokPaid ? 'Sudah Lunas' : 'Wajib Awal',
          icon: Icons.shield_outlined,
          isLocked: isPokokPaid,
          isSuccessBadge: isPokokPaid,
        ),
        const SizedBox(height: 10),
        _buildTypeCard(
          type: 'pembukaan_sijaka',
          title: 'Sijaka (Simpanan Berjangka)',
          subtitle: 'Investasi deposito syariah dengan bagi hasil bulanan',
          badgeText: 'Bagi Hasil',
          icon: Icons.pie_chart_outline_rounded,
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : (isLocked ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSuccessBadge ? Icons.check_circle_rounded : icon,
                  color: isSelected
                      ? Colors.white
                      : (isLocked ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
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
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isLocked)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                          ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isSuccessBadge
                                  ? const Color(0xFFECFDF5)
                                  : (isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSuccessBadge
                                    ? const Color(0xFFA7F3D0)
                                    : (isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSuccessBadge
                                    ? const Color(0xFF0E7955)
                                    : (isSelected ? const Color(0xFF0E7955) : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isSuccessBadge ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFCBD5E1),
                    width: isSelected ? 6 : 2,
                  ),
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
  Widget _buildWajibBatchSection(DashboardAnggota? anggota) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Ketentuan Simpanan Wajib (Rp 2.500 / Bulan)',
          desc: 'Iuran rutin wajib untuk memelihara keaktifan keanggotaan. Anda dapat melunasi sekaligus (batch) atau bayar per bulan.',
          icon: Icons.event_repeat_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        const SizedBox(height: 16),

        // Status Tunggakan Akun User
        if (anggota != null && anggota.tunggakanWajib.isNotEmpty) ...[
          DashboardAlertBanner.amber(
            margin: EdgeInsets.zero,
            title: 'Ada ${anggota.tunggakanWajib.length} Bulan Iuran Belum Dibayar',
            subtitle:
                'Total ${AppCurrency.format(anggota.totalTunggakanWajib)} (${anggota.tunggakanWajib.first.label} s/d ${anggota.tunggakanWajib.last.label})',
            actionLabel: 'Pilih Semua',
            icon: Icons.warning_amber_rounded,
            onActionTap: () {
              setState(() {
                _isBatchWajib = true;
                _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                _wajibEndMonth = anggota.tunggakanWajib.last.bulan;
                _wajibYear = anggota.tunggakanWajib.first.tahun;
                _updateWajibAmount();
              });
              AppDialog.showInfo(
                context,
                title: 'Tunggakan Dipilih',
                message:
                    'Semua ${anggota.tunggakanWajib.length} bulan tunggakan dipilih (${AppCurrency.format(anggota.totalTunggakanWajib)}).',
                icon: Icons.done_all_rounded,
              );
            },
          ),
          const SizedBox(height: 16),
        ] else if (anggota != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Iuran: Lancar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        'Tidak ada tunggakan iuran. Anda dapat membayar untuk bulan berjalan atau simpanan di muka.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Mode Switcher: Bayar Batch vs Bayar 1 Bulan Saja
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
                    final now = DateTime.now();
                    setState(() {
                      _isBatchWajib = true;
                      if (anggota != null && anggota.tunggakanWajib.isNotEmpty) {
                        _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                        _wajibEndMonth = anggota.tunggakanWajib.last.bulan;
                        _wajibYear = anggota.tunggakanWajib.first.tahun;
                      } else {
                        if (anggota != null &&
                            (anggota.isBeforeRegistration(_wajibStartMonth, _wajibYear) ||
                                anggota.isMonthPaid(_wajibStartMonth, _wajibYear, now: now))) {
                          _wajibStartMonth = now.month;
                          _wajibYear = now.year;
                        }
                        _wajibEndMonth = 12;
                      }
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
                      'Bayar Batch',
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
                    final now = DateTime.now();
                    setState(() {
                      _isBatchWajib = false;
                      if (anggota != null && anggota.tunggakanWajib.isNotEmpty) {
                        _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                        _wajibYear = anggota.tunggakanWajib.first.tahun;
                      } else if (anggota != null &&
                          (anggota.isBeforeRegistration(_wajibStartMonth, _wajibYear) ||
                              anggota.isMonthPaid(_wajibStartMonth, _wajibYear, now: now))) {
                        _wajibStartMonth = now.month;
                        _wajibYear = now.year;
                      }
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
                  Expanded(
                    child: Text(
                      _isBatchWajib ? 'Pilih Rentang Bulan' : 'Pilih Bulan Iuran',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                          const Text('Dari Bulan:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showMonthPickerSheet(isStart: true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _months[_wajibStartMonth - 1]['name'] as String,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                                ],
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
                          const Text('Sampai Bulan:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showMonthPickerSheet(isStart: false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _months[_wajibEndMonth - 1]['name'] as String,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick shortcuts for batch (single neat row)
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final hasTunggakan = anggota != null && anggota.tunggakanWajib.isNotEmpty;
                    final isAllTunggakanActive = hasTunggakan &&
                        _wajibStartMonth == anggota.tunggakanWajib.first.bulan &&
                        _wajibEndMonth == anggota.tunggakanWajib.last.bulan &&
                        _wajibYear == anggota.tunggakanWajib.first.tahun;
                    final isUntilDecActive = _wajibEndMonth == 12;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildBatchShortcutButton(
                            icon: hasTunggakan ? Icons.flash_on_rounded : Icons.calendar_today_rounded,
                            iconColor: hasTunggakan ? const Color(0xFFD97706) : const Color(0xFF059669),
                            label: hasTunggakan
                                ? 'Semua Tunggakan (${anggota.tunggakanWajib.length} bln)'
                                : 'Bulan Ini (${_months[now.month - 1]['name']})',
                            isActive: hasTunggakan ? isAllTunggakanActive : (_wajibStartMonth == now.month && _wajibEndMonth == now.month),
                            onTap: () {
                              setState(() {
                                if (hasTunggakan) {
                                  _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                                  _wajibEndMonth = anggota.tunggakanWajib.last.bulan;
                                  _wajibYear = anggota.tunggakanWajib.first.tahun;
                                } else {
                                  _wajibStartMonth = now.month;
                                  _wajibEndMonth = now.month;
                                  _wajibYear = now.year;
                                }
                                _updateWajibAmount();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBatchShortcutButton(
                            icon: Icons.date_range_rounded,
                            iconColor: const Color(0xFF0F766E),
                            label: 's/d Desember',
                            isActive: isUntilDecActive,
                            onTap: () {
                              setState(() {
                                if (hasTunggakan) {
                                  _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                                  _wajibYear = anggota.tunggakanWajib.first.tahun;
                                } else {
                                  _wajibStartMonth = now.month;
                                  _wajibYear = now.year;
                                }
                                _wajibEndMonth = 12;
                                _updateWajibAmount();
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bulan Iuran:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showMonthPickerSheet(isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Text(
                                  '${_months[_wajibStartMonth - 1]['name']} $_wajibYear',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildBatchShortcutButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF059669) : iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? const Color(0xFF065F46) : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPickerSheet({required bool isStart}) {
    final anggota = context.read<DashboardProvider>().dashboardData?.anggota;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 14, bottom: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !_isBatchWajib
                                ? 'Pilih Bulan Iuran'
                                : (isStart ? 'Pilih Bulan Mulai (Dari)' : 'Pilih Bulan Selesai (Sampai)'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Tahun $_wajibYear • Iuran Rp 2.500 / bulan',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 14),

              // Quick shortcut chips if delinquent
              if (anggota != null && anggota.tunggakanWajib.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickFilterChip(
                          label: 'Awal Tunggakan (${_months[anggota.tunggakanWajib.first.bulan - 1]['name']})',
                          onTap: () {
                            setState(() {
                              if (isStart || !_isBatchWajib) {
                                _wajibStartMonth = anggota.tunggakanWajib.first.bulan;
                                if (_wajibEndMonth < _wajibStartMonth) _wajibEndMonth = _wajibStartMonth;
                              } else {
                                _wajibEndMonth = anggota.tunggakanWajib.first.bulan;
                              }
                              _updateWajibAmount();
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          label: 'Akhir Tunggakan (${_months[anggota.tunggakanWajib.last.bulan - 1]['name']})',
                          onTap: () {
                            setState(() {
                              if (isStart || !_isBatchWajib) {
                                _wajibStartMonth = anggota.tunggakanWajib.last.bulan;
                              } else {
                                _wajibEndMonth = anggota.tunggakanWajib.last.bulan;
                              }
                              _updateWajibAmount();
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          label: 'Desember',
                          onTap: () {
                            setState(() {
                              if (isStart && !_isBatchWajib) {
                                _wajibStartMonth = 12;
                              } else {
                                _wajibEndMonth = 12;
                              }
                              _updateWajibAmount();
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 12 Months Grid (3 columns x 4 rows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.85,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final m = _months[index];
                    final monthId = m['id'] as int;
                    final monthName = m['name'] as String;

                    final isSelected = !_isBatchWajib
                        ? (_wajibStartMonth == monthId)
                        : (isStart ? _wajibStartMonth == monthId : _wajibEndMonth == monthId);

                    final isInBatchRange = _isBatchWajib &&
                        monthId >= _wajibStartMonth &&
                        monthId <= _wajibEndMonth;

                    final isTunggakan = anggota?.tunggakanWajib.any(
                          (t) => t.bulan == monthId && t.tahun == _wajibYear,
                        ) ??
                        false;

                    final isBeforeReg = anggota?.isBeforeRegistration(monthId, _wajibYear) ?? false;
                    final isPast = monthId < now.month && _wajibYear <= now.year;
                    final isCurrent = monthId == now.month && _wajibYear == now.year;
                    final isLunas = !isBeforeReg && (anggota?.isMonthPaid(monthId, _wajibYear, now: now) ?? (isPast && !isTunggakan));

                    // Disabled condition:
                    // Bulan sebelum daftar, bulan yang sudah lunas (untuk start/single), atau sebelum bulan mulai untuk end month
                    final isDisabled = isBeforeReg ||
                        isLunas ||
                        (!isStart && _isBatchWajib && monthId < _wajibStartMonth);

                    return _buildMonthGridItem(
                      monthId: monthId,
                      monthName: monthName,
                      isSelected: isSelected,
                      isInBatchRange: isInBatchRange,
                      isTunggakan: isTunggakan,
                      isLunas: isLunas,
                      isBeforeReg: isBeforeReg,
                      isCurrent: isCurrent,
                      isDisabled: isDisabled,
                      onTap: () {
                        if (isBeforeReg) {
                          AppDialog.showInfo(
                            context,
                            title: 'Belum Terdaftar',
                            message: 'Bulan $monthName $_wajibYear tidak dapat dipilih karena Anda belum terdaftar sebagai anggota KSPPS PASTI pada periode tersebut.',
                            icon: Icons.info_outline_rounded,
                            primaryColor: const Color(0xFF64748B),
                          );
                          return;
                        }

                        if (isLunas) {
                          if (!_isBatchWajib) {
                            AppDialog.showInfo(
                              context,
                              title: 'Iuran Sudah Lunas',
                              message: 'Bulan $monthName $_wajibYear sudah lunas dibayar dan tidak perlu dibayar lagi.',
                              icon: Icons.verified_rounded,
                              primaryColor: const Color(0xFF0E7955),
                            );
                          } else if (isStart) {
                            AppDialog.showInfo(
                              context,
                              title: 'Bulan Sudah Lunas',
                              message: 'Bulan $monthName $_wajibYear sudah lunas dibayar. Silakan pilih bulan yang menunggak atau bulan berjalan/mendatang untuk memulai pembayaran batch.',
                              icon: Icons.verified_rounded,
                              primaryColor: const Color(0xFF0E7955),
                            );
                          } else {
                            AppDialog.showInfo(
                              context,
                              title: 'Iuran Sudah Lunas',
                              message: 'Bulan $monthName $_wajibYear sudah lunas dibayar.',
                              icon: Icons.verified_rounded,
                              primaryColor: const Color(0xFF0E7955),
                            );
                          }
                          return;
                        }

                        if (!isStart && _isBatchWajib && monthId < _wajibStartMonth) {
                          AppDialog.showInfo(
                            context,
                            title: 'Rentang Bulan Tidak Sesuai',
                            message: 'Bulan selesai tidak boleh lebih awal dari bulan mulai (${_months[_wajibStartMonth - 1]['name']}).',
                            icon: Icons.info_outline_rounded,
                            primaryColor: const Color(0xFFD97706),
                          );
                          return;
                        }

                        HapticFeedback.lightImpact();
                        setState(() {
                          if (!_isBatchWajib) {
                            _wajibStartMonth = monthId;
                          } else if (isStart) {
                            _wajibStartMonth = monthId;
                            if (_wajibEndMonth < monthId) {
                              _wajibEndMonth = monthId;
                            }
                          } else {
                            _wajibEndMonth = monthId;
                          }
                          _updateWajibAmount();
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem(const Color(0xFFEF4444), 'Menunggak'),
                    _buildLegendItem(Theme.of(context).colorScheme.primary, 'Dipilih'),
                    _buildLegendItem(const Color(0xFF475569), 'Lunas'),
                    _buildLegendItem(const Color(0xFF94A3B8), 'Belum Terdaftar'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildMonthGridItem({
    required int monthId,
    required String monthName,
    required bool isSelected,
    required bool isInBatchRange,
    required bool isTunggakan,
    required bool isLunas,
    required bool isBeforeReg,
    required bool isCurrent,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    Color bgColor = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF1E293B);

    if (isBeforeReg) {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF94A3B8);
    } else if (isLunas) {
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF64748B);
    } else if (isDisabled) {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFFCBD5E1);
    } else if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primary;
      borderColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (isInBatchRange) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF065F46);
    } else if (isTunggakan) {
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFDBA74);
      textColor = const Color(0xFF9A3412);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (isCurrent && !isSelected)
                    const Text(
                      'Bulan ini',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                ],
              ),
            ),
            // Status badge top-right
            if (isTunggakan && !isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tunggakan',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            else if (isBeforeReg && !isSelected)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Belum Terdaftar',
                    style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              )
            else if (isLunas && !isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Lunas',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              )
            else if (isSelected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // --- 3A. PAKET AKTIVASI ANGGOTA BARU (POKOK + WAJIB SEKALIGUS) ---
  Widget _buildPokokWajibSection() {
    final startMonthName = _months.firstWhere(
      (m) => m['id'] == _wajibStartMonth,
      orElse: () => {'name': 'Bulan $_wajibStartMonth'},
    )['name'];
    final int monthCount = _activationMonthCount;
    final int wajibSubtotal = monthCount * _wajibPerBulan;
    final int total = _calculateTotalActivation();
    final int sisaUntilDec = (12 - _wajibStartMonth + 1).clamp(1, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Paket Aktivasi Anggota Baru (Hemat Biaya Layanan)',
          desc:
              'Gabungan Simpanan Pokok (Rp 15.000) dan Simpanan Wajib dalam 1 transaksi agar status keanggotaan Anda langsung Aktif tanpa bayar biaya layanan 2 kali.',
          icon: Icons.how_to_reg_rounded,
          iconColor: const Color(0xFF0E7955),
          bgColor: const Color(0xFFECFDF5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Rincian Biaya Registrasi',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '1X BAYAR',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0E7955)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text('Simpanan Pokok (1x seumur hidup)', style: TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppCurrency.format(_pokokNominal),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _activationBatchUntilDec
                          ? 'Simpanan Wajib ($startMonthName - Des $_wajibYear)'
                          : 'Simpanan Wajib ($startMonthName $_wajibYear)',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppCurrency.format(wajibSubtotal),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              if (sisaUntilDec > 1) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      activeColor: const Color(0xFF0E7955),
                      value: _activationBatchUntilDec,
                      onChanged: (val) {
                        setState(() {
                          _activationBatchUntilDec = val ?? false;
                          _updateActivationAmount();
                        });
                      },
                      title: Text(
                        'Sekalian lunasi Wajib s/d Des $_wajibYear ($sisaUntilDec bulan)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      subtitle: Text(
                        'Tambahan ${AppCurrency.format(sisaUntilDec * _wajibPerBulan)} • Bebas iuran sampai akhir tahun',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 22, color: Color(0xFFE2E8F0)),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Aktivasi Keanggotaan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0E7955)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppCurrency.format(total),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0E7955)),
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
                  const Expanded(
                    child: Text('Nominal Simpanan Pokok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ),
                  const SizedBox(width: 8),
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

    // Bangun saran metode tunggal (hanya 1 pilihan terbaik sesuai permintaan)
    final _PaymentSuggestionItem primarySuggestion;

    if (_lastUsedMethodCode != null &&
        channels.any((c) => c.code.toLowerCase() == _lastUsedMethodCode!.toLowerCase())) {
      final ch = channels.firstWhere(
        (c) => c.code.toLowerCase() == _lastUsedMethodCode!.toLowerCase(),
      );
      primarySuggestion = _PaymentSuggestionItem(
        channel: ch,
        badgeText: 'Terakhir Digunakan',
        badgeIcon: Icons.history_rounded,
        badgeColor: const Color(0xFF0F766E),
      );
    } else {
      final qris = channels.cast<PaymentChannelModel?>().firstWhere(
            (c) => c?.code.toLowerCase() == 'qris',
            orElse: () => null,
          );
      if (qris != null) {
        primarySuggestion = _PaymentSuggestionItem(
          channel: qris,
          badgeText: 'Rekomendasi Cepat',
          badgeIcon: Icons.electric_bolt_rounded,
          badgeColor: const Color(0xFFDC2626),
        );
      } else {
        primarySuggestion = _PaymentSuggestionItem(
          channel: channels.first,
          badgeText: 'Paling Populer',
          badgeIcon: Icons.star_rounded,
          badgeColor: const Color(0xFF0F766E),
        );
      }
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
                              maxLines: 2,
                              softWrap: true,
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
                        maxLines: 2,
                        softWrap: true,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Instan 24 Jam',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                          Builder(
                            builder: (context) {
                              final currentFee = selectedChannel.calculateFee(_parsedAmount);
                              return Text(
                                currentFee > 0
                                    ? 'Biaya Layanan ${AppCurrency.format(currentFee)}'
                                    : 'Bebas Biaya Layanan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: currentFee > 0 ? const Color(0xFFB45309) : const Color(0xFF059669),
                                ),
                              );
                            },
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

        // Header Saran Rekomendasi (Hanya 1 Metode Sesuai Permintaan)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF0F766E)),
                SizedBox(width: 5),
                Text(
                  'SARAN METODE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showPaymentMethodSelector(context, channels),
              child: const Text(
                'Metode Lainnya',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1 Item Saran Rekomendasi Saja (Ringkas, Rapih & Tanpa Scroll Panjang)
        Builder(
          builder: (context) {
            final isSel = primarySuggestion.channel.code == _selectedPaymentMethod;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = primarySuggestion.channel.code;
                });
                StorageService.saveLastPaymentMethod(primarySuggestion.channel.code);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                    width: isSel ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSel
                          ? const Color(0xFF0F766E).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFDCFCE7)
                                  : primarySuggestion.badgeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  primarySuggestion.badgeIcon,
                                  size: 11,
                                  color: isSel ? const Color(0xFF15803D) : primarySuggestion.badgeColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    primarySuggestion.badgeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? const Color(0xFF15803D) : primarySuggestion.badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                primarySuggestion.channel.icon,
                                size: 18,
                                color: primarySuggestion.channel.tagColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  primarySuggestion.channel.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    color: isSel ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSel) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: Color(0xFF15803D)),
                            SizedBox(width: 3),
                            Text(
                              'Dipilih',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Gunakan',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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
                            maxLines: 2,
                            softWrap: true,
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
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final fee = ch.calculateFee(_parsedAmount);
                        final String feeText;
                        if (ch.feeType == 'conditional' && _parsedAmount == 0) {
                          feeText = '≤ 100k: ${AppCurrency.format(ch.feeBelowThreshold)} | > 100k: ${ch.feeAboveThresholdPercent}%';
                        } else if (fee > 0) {
                          feeText = 'Biaya Layanan ${AppCurrency.format(fee)}';
                        } else {
                          feeText = 'Bebas Biaya Layanan';
                        }
                        final isPaid = fee > 0 || (ch.feeType == 'conditional' && _parsedAmount == 0);

                        return Row(
                          children: [
                            Icon(
                              isPaid ? Icons.toll_rounded : Icons.check_circle_outline_rounded,
                              size: 11,
                              color: isPaid ? const Color(0xFFB45309) : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              feeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isPaid ? const Color(0xFFB45309) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        );
                      },
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
    final isDisabled = (_selectedType == 'simpanan_pokok' || _selectedType == 'simpanan_pokok_wajib') && isPokokPaid;
    final channels = context.watch<PaymentProvider>().activeChannels;
    final selectedChannel = channels.where((c) => c.code == _selectedPaymentMethod).firstOrNull;
    final int adminFee = selectedChannel?.calculateFee(_parsedAmount) ?? 0;
    final int totalPayment = _parsedAmount + adminFee;

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
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      if (adminFee > 0)
                        Text(
                          '+ Layanan ${AppCurrency.format(adminFee)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Gratis Layanan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppCurrency.format(totalPayment),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
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