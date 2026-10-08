import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../savings/models/penarikan_model.dart';
import '../../savings/services/savings_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/pin_verification_dialog.dart';
import '../../../../shared/widgets/premium_header.dart';

class TarikSimpananScreen extends StatefulWidget {
  const TarikSimpananScreen({super.key});

  @override
  State<TarikSimpananScreen> createState() => _TarikSimpananScreenState();
}

class _TarikSimpananScreenState extends State<TarikSimpananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _savingsService = SavingsService();

  // Form Controllers
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _customBankController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _noteController = TextEditingController();

  String get _finalBankName {
    if (_bankNameController.text == 'Bank Lainnya') {
      return _customBankController.text.trim().isNotEmpty
          ? _customBankController.text.trim()
          : 'Bank Lainnya';
    }
    return _bankNameController.text.trim();
  }

  String _selectedSumber = 'simpanan_sukarela';
  bool _isLoading = false;

  // Riwayat State
  List<PenarikanItemModel> _riwayatList = [];
  PenarikanItemModel? _activePendingPengajuan;
  bool get _hasActivePending => _activePendingPengajuan != null;
  bool _isLoadingRiwayat = false;
  String? _riwayatError;

  final List<int> _presetNominals = [
    50000,
    100000,
    250000,
    500000,
    1000000,
    2000000,
  ];

  final List<String> _bankOptions = [
    'Bank Syariah Indonesia (BSI)',
    'Bank Central Asia (BCA)',
    'Bank Mandiri',
    'Bank Rakyat Indonesia (BRI)',
    'Bank Negara Indonesia (BNI)',
    'Bank Muamalat',
    'Bank Jateng',
    'Bank CIMB Niaga Syariah',
    'Bank Jago Syariah',
    'Permata Bank',
    'Bank Danamon',
    'Bank Lainnya',
  ];

  List<String> get _currentBankOptions {
    final list = List<String>.from(_bankOptions);
    final current = _bankNameController.text.trim();
    if (current.isNotEmpty && !list.contains(current) && current != 'Bank Lainnya') {
      list.insert(list.length - 1, current);
    }
    return list;
  }

  String _matchBankOption(String raw) {
    if (raw.trim().isEmpty) return 'Bank Syariah Indonesia (BSI)';

    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    for (final opt in _bankOptions) {
      if (opt.toLowerCase() == lower) return opt;
    }

    if (lower.contains('bsi') || lower.contains('syariah indonesia')) {
      return 'Bank Syariah Indonesia (BSI)';
    }
    if (lower.contains('bca') || lower.contains('central asia')) {
      return 'Bank Central Asia (BCA)';
    }
    if (lower.contains('mandiri')) {
      return 'Bank Mandiri';
    }
    if (lower.contains('bri') || lower.contains('rakyat indonesia')) {
      return 'Bank Rakyat Indonesia (BRI)';
    }
    if (lower.contains('bni') || lower.contains('negara indonesia')) {
      return 'Bank Negara Indonesia (BNI)';
    }
    if (lower.contains('muamalat')) {
      return 'Bank Muamalat';
    }
    if (lower.contains('jateng')) {
      return 'Bank Jateng';
    }
    if (lower.contains('cimb') || lower.contains('niaga')) {
      return 'Bank CIMB Niaga Syariah';
    }
    if (lower.contains('jago')) {
      return 'Bank Jago Syariah';
    }
    if (lower.contains('permata')) {
      return 'Permata Bank';
    }
    if (lower.contains('danamon')) {
      return 'Bank Danamon';
    }

    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _riwayatList.isEmpty) {
        _fetchRiwayat();
      }
    });

    // Populate bank info directly from profile and load pending status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRiwayat();
      _syncBankInfoFromProfile();
    });
  }

  Future<void> _syncBankInfoFromProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    var anggota = profileProvider.profileData?.anggota;
    var user = profileProvider.profileData?.user ?? authProvider.user;

    // Jika data rekening di profileData belum lengkap, fetch dari API profil
    if (anggota == null || anggota.namaBank == null || anggota.namaBank!.trim().isEmpty) {
      try {
        await profileProvider.fetchProfileDetail(refresh: true);
        if (mounted) {
          anggota = profileProvider.profileData?.anggota;
          user = profileProvider.profileData?.user ?? authProvider.user;
        }
      } catch (_) {}
    }

    // Fallback ke AuthProvider jika ada
    anggota ??= authProvider.user?.anggota;

    if (anggota != null && mounted) {
      final rawBank = anggota.namaBank?.trim() ?? '';
      final noRek = anggota.noRekening?.trim() ?? '';
      final atasNama = anggota.atasNamaRekening?.trim() ?? user?.name.trim() ?? '';

      if (rawBank.isNotEmpty) {
        final matched = _matchBankOption(rawBank);
        _bankNameController.text = matched;
        if (!_bankOptions.contains(matched)) {
          _customBankController.text = rawBank;
        }
      } else if (_bankNameController.text.isEmpty) {
        _bankNameController.text = 'Bank Syariah Indonesia (BSI)';
      }

      if (noRek.isNotEmpty) {
        _accountNoController.text = noRek;
      }
      if (atasNama.isNotEmpty) {
        _accountNameController.text = atasNama;
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    _customBankController.dispose();
    _accountNoController.dispose();
    _accountNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoadingRiwayat = true;
      _riwayatError = null;
    });

    try {
      final result = await _savingsService.getRiwayatPenarikan();
      if (mounted) {
        setState(() {
          _riwayatList = result.items;
          PenarikanItemModel? pending;
          if (result.activePending != null) {
            pending = result.activePending;
          } else {
            try {
              pending = _riwayatList.firstWhere((it) => it.isPending);
            } catch (_) {
              pending = null;
            }
          }
          _activePendingPengajuan = pending;
          _isLoadingRiwayat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _riwayatError = e.toString();
          _isLoadingRiwayat = false;
        });
      }
    }
  }

  void _submitTarik() async {
    final amount = _parsedAmount;
    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal penarikan adalah Rp 50.000'), backgroundColor: Colors.red),
      );
      return;
    }

    // 1. Cek apakah ada pengajuan aktif yang masih pending
    if (_hasActivePending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda masih memiliki pengajuan penarikan sebesar ${_activePendingPengajuan!.nominalFormat} yang sedang Menunggu Transfer. Mohon tunggu proses pencairan selesai.',
          ),
          backgroundColor: Colors.amber.shade900,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final dashboard = context.read<DashboardProvider>().dashboardData?.ringkasanSaldo;
    final realBalance = _selectedSumber == 'saldo_sijaka'
        ? (dashboard?.saldoBagihasilSijaka ?? 0)
        : (dashboard?.saldoSukarela ?? 0);

    final currentType = _selectedSumber == 'saldo_sijaka' ? 'bagihasil_sijaka' : 'sukarela';
    final pendingForSelected = _riwayatList
        .where((it) => it.isPending && it.jenisSimpanan == currentType)
        .fold<num>(0, (sum, it) => sum + it.nominal);

    final maxAvailable = realBalance > pendingForSelected ? realBalance - pendingForSelected : 0;

    if (amount > maxAvailable) {
      final String msg = pendingForSelected > 0
          ? 'Saldo tidak mencukupi. Saldo rekening: ${AppCurrency.format(realBalance)}, tertahan menunggu transfer: ${AppCurrency.format(pendingForSelected)}. Sisa bisa ditarik: ${AppCurrency.format(maxAvailable)}'
          : 'Saldo tidak mencukupi. Saldo tersedia: ${AppCurrency.format(realBalance)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    final finalBank = _finalBankName;
    if (finalBank.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama bank tujuan wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_accountNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor rekening tujuan wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_accountNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pemilik rekening tujuan wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    // Verifikasi PIN Transaksi 6 Digit
    final isPinValid = await PinVerificationDialog.show(
      context,
      title: 'Konfirmasi Penarikan',
      subtitle: 'Masukkan 6 digit PIN untuk mengajukan penarikan dana ${AppCurrency.format(amount)}',
    );

    if (!isPinValid) return;

    setState(() => _isLoading = true);

    try {
      await _savingsService.ajukanPenarikan(
        nominal: amount,
        jenisSimpanan: _selectedSumber == 'saldo_sijaka' ? 'bagihasil_sijaka' : 'sukarela',
        namaBank: finalBank,
        noRekening: _accountNoController.text.trim(),
        atasNama: _accountNameController.text.trim(),
        catatanAnggota: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      // Refresh data dashboard & riwayat
      if (mounted) {
        context.read<DashboardProvider>().fetchDashboard();
        _fetchRiwayat();
      }

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengajukan penarikan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Pengajuan Berhasil Dikirim', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Permohonan penarikan dana ${AppCurrency.format(_parsedAmount)} telah diteruskan ke tim Finance. Dana akan ditransfer secara manual ke rekening $_finalBankName (${_accountNoController.text}) Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _amountController.clear();
                        _noteController.clear();
                        _tabController.animateTo(1);
                        _fetchRiwayat();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Lihat Riwayat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7955),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Selesai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>().dashboardData?.ringkasanSaldo;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Penarikan Simpanan'),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0E7955),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0E7955),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Form Penarikan'),
                Tab(text: 'Riwayat Pengajuan'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Form Pengajuan
                _buildFormTab(dashboard),

                // TAB 2: Riwayat Pengajuan
                _buildRiwayatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTab(dynamic dashboard) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasActivePending) ...[
                  _buildPendingWarningCard(),
                  const SizedBox(height: 16),
                ],
                _buildBalanceBanner(dashboard),
                const SizedBox(height: 20),

                const Text('PILIH SUMBER DANA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        type: 'simpanan_sukarela',
                        title: 'Sirela (Sukarela)',
                        subtitle: 'Bebas tarik',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTypeCard(
                        type: 'saldo_sijaka',
                        title: 'Bagi Hasil Sijaka',
                        subtitle: 'Tarik Nisbah',
                        icon: Icons.monetization_on_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input Nominal
                const Text('Nominal Penarikan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Text('Rp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                            LengthLimitingTextInputFormatter(14),
                          ],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('*Minimum penarikan Rp 50.000', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 14),

                // Pilihan Cepat
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetNominals.map((nom) {
                    final isSelected = _parsedAmount == nom;
                    return InkWell(
                      onTap: () {
                        _amountController.text = AppCurrency.format(nom).replaceAll('Rp ', '');
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0E7955) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF0E7955) : const Color(0xFFE2E8F0)),
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
                ),
                const SizedBox(height: 24),

                // Metode Transfer Bank
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('REKENING TUJUAN PENCAIRAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 12, color: Color(0xFF0E7955)),
                          SizedBox(width: 4),
                          Text('Tersinkron Anggota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0E7955))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0E7955), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Transfer Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                Text('Data rekening diambil dari data keanggotaan Anda', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 14),

                      // Bank Dropdown / Text
                      const Text('Nama Bank Tujuan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _currentBankOptions.contains(_bankNameController.text)
                                ? _bankNameController.text
                                : null,
                            hint: Text(
                              _bankNameController.text.isNotEmpty ? _bankNameController.text : 'Pilih Bank Tujuan',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            isExpanded: true,
                            items: _currentBankOptions.map((bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _bankNameController.text = val;
                                  if (val != 'Bank Lainnya') {
                                    _customBankController.clear();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (_bankNameController.text == 'Bank Lainnya') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customBankController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Ketik nama bank lainnya...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // No Rekening
                      const Text('Nomor Rekening Tujuan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _accountNoController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 0.5),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 1234567890',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nama Pemilik
                      const Text('Nama Pemilik Rekening (Atas Nama) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _accountNameController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Nama lengkap sesuai buku tabungan',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Catatan
                      const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _noteController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Catatan untuk finance (opsional)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Bottom Bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Penarikan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      AppCurrency.format(_parsedAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading || _parsedAmount < 50000 || _hasActivePending ? null : _submitTarik,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasActivePending ? const Color(0xFF94A3B8) : const Color(0xFF0E7955),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _hasActivePending ? 'Menunggu Transfer' : 'Ajukan Sekarang',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab() {
    if (_isLoadingRiwayat) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0E7955)),
      );
    }

    if (_riwayatError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_riwayatError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchRiwayat,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E7955), foregroundColor: Colors.white),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_riwayatList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRiwayat,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Belum Ada Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              const Text(
                'Anda belum pernah membuat pengajuan penarikan dana simpanan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _riwayatList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _riwayatList[index];

          Color badgeBg = const Color(0xFFFFFBEB);
          Color badgeText = const Color(0xFFD97706);
          Color badgeBorder = const Color(0xFFFDE68A);

          if (item.isApproved) {
            badgeBg = const Color(0xFFECFDF5);
            badgeText = const Color(0xFF059669);
            badgeBorder = const Color(0xFFA7F3D0);
          } else if (item.isRejected) {
            badgeBg = const Color(0xFFFEF2F2);
            badgeText = const Color(0xFFDC2626);
            badgeBorder = const Color(0xFFFECACA);
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.kodeTransaksi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simpanan ${item.jenisSimpanan.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          item.nominalFormat,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.namaBank.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(item.noRekening, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace')),
                      ],
                    ),
                  ],
                ),
                if (item.catatanFinance != null && item.catatanFinance!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Catatan Finance: ${item.catatanFinance}',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isRejected ? const Color(0xFF991B1B) : const Color(0xFF166534),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 6),
                Text(
                  'Diajukan: ${item.tglPengajuan}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingWarningCard() {
    final pending = _activePendingPengajuan!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Sedang Diproses',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    Text(
                      'Menunggu transfer oleh finance',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text('Menunggu Transfer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Anda memiliki permohonan penarikan aktif sebesar ${pending.nominalFormat} (Kode: ${pending.kodeTransaksi}). Dana sedang dalam antrean transfer manual oleh tim Finance. Anda baru dapat mengajukan penarikan kembali setelah proses transfer selesai.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _tabController.animateTo(1),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat di Riwayat Pengajuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner(dynamic dashboard) {
    num realBalance = 0;
    String label = 'Saldo Sirela (Sukarela)';
    final String currentType = _selectedSumber == 'saldo_sijaka' ? 'bagihasil_sijaka' : 'sukarela';

    if (_selectedSumber == 'saldo_sijaka') {
      realBalance = dashboard?.saldoBagihasilSijaka ?? 0;
      label = 'Saldo Bagi Hasil (Nisbah)';
    } else {
      realBalance = dashboard?.saldoSukarela ?? 0;
      label = 'Saldo Sirela (Sukarela)';
    }

    final pendingAmount = _riwayatList
        .where((it) => it.isPending && it.jenisSimpanan == currentType)
        .fold<num>(0, (sum, it) => sum + it.nominal);
    final availableBalance = realBalance > pendingAmount ? realBalance - pendingAmount : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          )
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
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0E7955), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        AppCurrency.format(realBalance),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingAmount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pendingAmount > 0 ? const Color(0xFFFDE68A) : Colors.transparent,
                  ),
                ),
                child: Text(
                  pendingAmount > 0 ? 'Ada Tertahan' : 'Bisa Ditarik',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pendingAmount > 0 ? const Color(0xFFB45309) : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          if (pendingAmount > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tertahan (Menunggu Transfer):', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                Text(
                  '- ${AppCurrency.format(pendingAmount)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sisa Tersedia untuk Ditarik:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(
                  AppCurrency.format(availableBalance),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0E7955)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedSumber == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSumber = type),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0E7955).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0E7955) : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0E7955) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF0E7955) : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
}
