import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/dashboard_provider.dart';
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
  final _accountNoController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedSumber = 'simpanan_sukarela';
  bool _isLoading = false;

  // Riwayat State
  List<PenarikanItemModel> _riwayatList = [];
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
    'BCA',
    'BRI',
    'BNI',
    'Mandiri',
    'BSI (Bank Syariah Indonesia)',
    'Bank Jateng',
    'CIMB Niaga',
    'Permata Bank',
    'Bank Danamon',
    'Bank Muamalat',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _riwayatList.isEmpty) {
        _fetchRiwayat();
      }
    });

    // Populate default bank info from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final anggota = user?.anggota;
      if (anggota != null) {
        if (anggota.namaBank != null && anggota.namaBank!.isNotEmpty) {
          _bankNameController.text = anggota.namaBank!;
        } else {
          _bankNameController.text = 'BCA';
        }
        if (anggota.noRekening != null && anggota.noRekening!.isNotEmpty) {
          _accountNoController.text = anggota.noRekening!;
        }
        if (anggota.atasNamaRekening != null && anggota.atasNamaRekening!.isNotEmpty) {
          _accountNameController.text = anggota.atasNamaRekening!;
        } else if (user != null) {
          _accountNameController.text = user.name;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
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

    final dashboard = context.read<DashboardProvider>().dashboardData?.ringkasanSaldo;
    final maxBalance = _selectedSumber == 'saldo_sijaka'
        ? (dashboard?.saldoBagihasilSijaka ?? 0)
        : (dashboard?.saldoSukarela ?? 0);

    if (amount > maxBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo tidak mencukupi. Saldo tersedia: ${AppCurrency.format(maxBalance)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bankNameController.text.trim().isEmpty) {
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

    // 1. Verifikasi PIN Transaksi 6 Digit
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
        namaBank: _bankNameController.text.trim(),
        noRekening: _accountNoController.text.trim(),
        atasNama: _accountNameController.text.trim(),
        catatanAnggota: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      // Refresh data
      if (mounted) {
        context.read<DashboardProvider>().fetchDashboard();
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
                'Permohonan penarikan dana ${AppCurrency.format(_parsedAmount)} telah diteruskan ke tim Finance. Dana akan ditransfer secara manual ke rekening ${_bankNameController.text} (${_accountNoController.text}) Anda.',
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
                            value: _bankOptions.contains(_bankNameController.text) ? _bankNameController.text : null,
                            hint: Text(_bankNameController.text.isNotEmpty ? _bankNameController.text : 'Pilih Bank Tujuan', style: const TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: _bankOptions.map((bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _bankNameController.text = val);
                              }
                            },
                          ),
                        ),
                      ),
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
                  onPressed: _isLoading || _parsedAmount < 50000 ? null : _submitTarik,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7955),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ajukan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildBalanceBanner(dynamic dashboard) {
    num activeBalance = 0;
    String label = 'Saldo Sirela (Sukarela)';

    if (_selectedSumber == 'saldo_sijaka') {
      activeBalance = dashboard?.saldoBagihasilSijaka ?? 0;
      label = 'Saldo Bagi Hasil (Nisbah)';
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
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0E7955), size: 20),
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
            child: const Text('Bisa Ditarik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          )
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
