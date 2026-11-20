import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/screens/doku_webview_screen.dart';
import '../../payment/screens/native_payment_detail_screen.dart';
import '../../payment/widgets/qris_preparation_dialog.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/sijaka_model.dart';
import '../providers/sijaka_provider.dart';

class BankInfo {
  final String code;
  final String name;
  final String shortName;
  final Color primaryColor;
  final Color badgeBg;
  final String? svgAsset;
  final IconData icon;

  const BankInfo({
    required this.code,
    required this.name,
    required this.shortName,
    required this.primaryColor,
    required this.badgeBg,
    this.svgAsset,
    this.icon = Icons.account_balance_rounded,
  });
}

class SavedBankAccount {
  final String bankName;
  final String noRekening;
  final String atasNama;
  final bool isDefault;

  SavedBankAccount({
    required this.bankName,
    required this.noRekening,
    required this.atasNama,
    this.isDefault = false,
  });

  String get bankShortName {
    final lower = bankName.toLowerCase();
    if (lower.contains('bsi') || lower.contains('syariah indonesia')) return 'BSI';
    if (lower.contains('bca') || lower.contains('central asia')) return 'BCA';
    if (lower.contains('mandiri')) return 'Mandiri';
    if (lower.contains('bri') || lower.contains('rakyat indonesia')) return 'BRI';
    if (lower.contains('bni') || lower.contains('negara indonesia')) return 'BNI';
    if (lower.contains('muamalat')) return 'Muamalat';
    if (lower.contains('cimb')) return 'CIMB Niaga';
    if (lower.contains('danamon')) return 'Danamon';
    if (lower.contains('permata')) return 'Permata';
    return bankName;
  }
}

class SijakaSubmissionScreen extends StatefulWidget {
  const SijakaSubmissionScreen({super.key});

  @override
  State<SijakaSubmissionScreen> createState() => _SijakaSubmissionScreenState();
}

class _SijakaSubmissionScreenState extends State<SijakaSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _ahliWarisNamaController = TextEditingController();
  final TextEditingController _ahliWarisHubunganCustomController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _bankCustomController = TextEditingController();
  final TextEditingController _noRekController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();
  final TextEditingController _ktpController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  // Multi-step state: 0: Produk, 1: Rekening, 2: Lainnya, 3: Review
  int _currentStep = 0;

  SijakaProdukItem? _selectedProduct;
  String _selectedMetodeBagiHasil = 'Setiap Bulan';
  String _selectedHubungan = 'Pasangan (Suami/Istri)';
  bool _agreed = false;
  int _rawNominal = 1000000;
  bool _isProfileSynced = false;

  // Rekening state
  bool _isRekeningBaru = false;
  int _selectedSavedAccountIndex = 0;
  String _selectedBankCode = 'BSI';
  bool _saveNewAccount = true;
  final List<SavedBankAccount> _savedAccounts = [];

  static const List<BankInfo> _bankList = [
    BankInfo(
      code: 'BSI',
      name: 'Bank Syariah Indonesia (BSI)',
      shortName: 'BSI',
      primaryColor: Color(0xFF00A39D),
      badgeBg: Color(0xFFE0F7F6),
      svgAsset: 'assets/banks/bsi.svg',
    ),
    BankInfo(
      code: 'BCA',
      name: 'Bank Central Asia (BCA)',
      shortName: 'BCA',
      primaryColor: Color(0xFF005BAC),
      badgeBg: Color(0xFFE6F0FA),
      svgAsset: 'assets/banks/bca.svg',
    ),
    BankInfo(
      code: 'MANDIRI',
      name: 'Bank Mandiri',
      shortName: 'Mandiri',
      primaryColor: Color(0xFF003D79),
      badgeBg: Color(0xFFE8EEF5),
      svgAsset: 'assets/banks/mandiri.svg',
    ),
    BankInfo(
      code: 'BRI',
      name: 'Bank Rakyat Indonesia (BRI)',
      shortName: 'BRI',
      primaryColor: Color(0xFF00529C),
      badgeBg: Color(0xFFE6EEF7),
      svgAsset: 'assets/banks/bri.svg',
    ),
    BankInfo(
      code: 'BNI',
      name: 'Bank Negara Indonesia (BNI)',
      shortName: 'BNI',
      primaryColor: Color(0xFFE55300),
      badgeBg: Color(0xFFFDEEE6),
      svgAsset: 'assets/banks/bni.svg',
    ),
    BankInfo(
      code: 'MUAMALAT',
      name: 'Bank Muamalat',
      shortName: 'Muamalat',
      primaryColor: Color(0xFF79247E),
      badgeBg: Color(0xFFF3E7F4),
    ),
    BankInfo(
      code: 'CIMB',
      name: 'Bank CIMB Niaga Syariah',
      shortName: 'CIMB Niaga',
      primaryColor: Color(0xFFED1B24),
      badgeBg: Color(0xFFFDE8E9),
      svgAsset: 'assets/banks/cimb.svg',
    ),
    BankInfo(
      code: 'DANAMON',
      name: 'Bank Danamon',
      shortName: 'Danamon',
      primaryColor: Color(0xFFFF5A00),
      badgeBg: Color(0xFFFFF0E6),
      svgAsset: 'assets/banks/danamon.svg',
    ),
    BankInfo(
      code: 'PERMATA',
      name: 'Bank Permata',
      shortName: 'Permata',
      primaryColor: Color(0xFF008D45),
      badgeBg: Color(0xFFE6F5EC),
    ),
    BankInfo(
      code: 'LAINNYA',
      name: 'Bank Lainnya',
      shortName: 'Lainnya',
      primaryColor: Color(0xFF475569),
      badgeBg: Color(0xFFF1F5F9),
      icon: Icons.account_balance_outlined,
    ),
  ];

  final List<String> _hubunganOptions = [
    'Pasangan (Suami/Istri)',
    'Anak',
    'Orang Tua',
    'Saudara Kandung',
    'Keluarga Lainnya',
  ];

  final List<int> _quickPresets = [
    1000000,
    5000000,
    10000000,
    25000000,
    50000000,
  ];

  @override
  void initState() {
    super.initState();
    _formatAndSetNominal(_rawNominal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nominalController.dispose();
    _ahliWarisNamaController.dispose();
    _ahliWarisHubunganCustomController.dispose();
    _bankController.dispose();
    _bankCustomController.dispose();
    _noRekController.dispose();
    _atasNamaController.dispose();
    _ktpController.dispose();
    _hpController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _formatAndSetNominal(int value) {
    _rawNominal = value;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    _nominalController.text = formatter.format(value).trim();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProducts(),
      _loadProfileData(),
    ]);
  }

  Future<void> _loadProducts() async {
    final provider = context.read<SijakaProvider>();
    await provider.fetchProdukList();

    final activeList = provider.activeProdukList;
    if (mounted && activeList.isNotEmpty) {
      setState(() {
        if (_selectedProduct == null || !_selectedProduct!.isActive) {
          _selectedProduct = activeList.firstWhere(
            (p) => p.tenorBulan == 6 || p.tenorBulan == 12,
            orElse: () => activeList.first,
          );
          if (_rawNominal < _selectedProduct!.minimalSetoran) {
            _formatAndSetNominal(_selectedProduct!.minimalSetoran.toInt());
          }
        }
      });
    }
  }

  Future<void> _loadProfileData() async {
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profileData == null) {
      await profileProvider.fetchProfileDetail();
    }
    final anggota = profileProvider.profileData?.anggota;
    final user = profileProvider.profileData?.user;

    if (mounted && anggota != null) {
      setState(() {
        // 1. Sync Data Ahli Waris
        if (_ahliWarisNamaController.text.isEmpty && (anggota.namaAhliWaris?.isNotEmpty ?? false)) {
          _ahliWarisNamaController.text = anggota.namaAhliWaris!;
        }
        if (_ktpController.text.isEmpty && (anggota.nikAhliWaris?.isNotEmpty ?? false)) {
          _ktpController.text = anggota.nikAhliWaris!;
        }
        if (_hpController.text.isEmpty && (anggota.noHpAhliWaris?.isNotEmpty ?? false)) {
          _hpController.text = anggota.noHpAhliWaris!;
        }
        if (_emailController.text.isEmpty && (anggota.emailAhliWaris?.isNotEmpty ?? false)) {
          _emailController.text = anggota.emailAhliWaris!;
        }
        if (_alamatController.text.isEmpty && (anggota.alamatAhliWaris?.isNotEmpty ?? false)) {
          _alamatController.text = anggota.alamatAhliWaris!;
        }
        if (anggota.hubunganAhliWaris != null && anggota.hubunganAhliWaris!.isNotEmpty) {
          if (_hubunganOptions.contains(anggota.hubunganAhliWaris)) {
            _selectedHubungan = anggota.hubunganAhliWaris!;
          } else {
            _selectedHubungan = 'Keluarga Lainnya';
            _ahliWarisHubunganCustomController.text = anggota.hubunganAhliWaris!;
          }
        }

        // 2. Sync Rekening Tersimpan dari Profil
        final existingBank = anggota.namaBank ?? '';
        final existingNoRek = anggota.noRekening ?? '';
        final existingAtasNama = anggota.atasNamaRekening ?? (user?.name ?? '');

        if (existingBank.isNotEmpty && existingNoRek.isNotEmpty) {
          final alreadyHas = _savedAccounts.any((a) => a.noRekening == existingNoRek);
          if (!alreadyHas) {
            _savedAccounts.add(SavedBankAccount(
              bankName: existingBank,
              noRekening: existingNoRek,
              atasNama: existingAtasNama,
              isDefault: true,
            ));
          }
        }

        if (_savedAccounts.isNotEmpty) {
          _selectedSavedAccountIndex = 0;
          _bankController.text = _savedAccounts[0].bankName;
          _noRekController.text = _savedAccounts[0].noRekening;
          _atasNamaController.text = _savedAccounts[0].atasNama;
          _isRekeningBaru = false;
        } else {
          _isRekeningBaru = true;
          if (_bankController.text.isEmpty) {
            _bankController.text = _bankList.first.name;
            _selectedBankCode = _bankList.first.code;
          }
          if (_atasNamaController.text.isEmpty) {
            _atasNamaController.text = user?.name ?? '';
          }
        }

        _isProfileSynced = true;
      });
    }
  }

  BankInfo _findBankInfo(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('bsi') || lower.contains('syariah indonesia')) {
      return _bankList[0];
    } else if (lower.contains('bca') || lower.contains('central asia')) {
      return _bankList[1];
    } else if (lower.contains('mandiri')) {
      return _bankList[2];
    } else if (lower.contains('bri') || lower.contains('rakyat indonesia')) {
      return _bankList[3];
    } else if (lower.contains('bni') || lower.contains('negara indonesia')) {
      return _bankList[4];
    } else if (lower.contains('muamalat')) {
      return _bankList[5];
    } else if (lower.contains('cimb')) {
      return _bankList[6];
    } else if (lower.contains('danamon')) {
      return _bankList[7];
    } else if (lower.contains('permata')) {
      return _bankList[8];
    }
    return _bankList.last;
  }

  void _onNominalChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean) ?? 0;
    setState(() {
      _rawNominal = parsed;
    });
  }

  DateTime _getEstimatedMaturityDate(int tenorBulan) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + tenorBulan, now.day);
  }

  String get _finalHubunganAhliWaris {
    if (_selectedHubungan == 'Keluarga Lainnya' &&
        _ahliWarisHubunganCustomController.text.trim().isNotEmpty) {
      return _ahliWarisHubunganCustomController.text.trim();
    }
    return _selectedHubungan;
  }

  String get _finalBankName {
    if (_isRekeningBaru) {
      if (_selectedBankCode == 'LAINNYA') {
        return _bankCustomController.text.trim().isNotEmpty
            ? _bankCustomController.text.trim()
            : 'Bank Lainnya';
      }
      final matched = _bankList.firstWhere(
        (b) => b.code == _selectedBankCode,
        orElse: () => _bankList.first,
      );
      return matched.name;
    } else {
      if (_savedAccounts.isNotEmpty && _selectedSavedAccountIndex < _savedAccounts.length) {
        return _savedAccounts[_selectedSavedAccountIndex].bankName;
      }
      return _bankController.text.trim();
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _validateStep0() {
    if (_selectedProduct == null) {
      AppDialog.showWarning(
        context,
        title: 'Pilih Produk Sijaka',
        message: 'Silakan pilih produk Sijaka terlebih dahulu sebelum melanjutkan.',
      );
      return false;
    }

    if (_rawNominal < _selectedProduct!.minimalSetoran) {
      AppDialog.showWarning(
        context,
        title: 'Nominal Belum Mencukupi',
        message:
            'Nominal minimal untuk ${_selectedProduct!.namaProduk} adalah ${_selectedProduct!.formattedMinimalSetoran}.',
      );
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_isRekeningBaru) {
      final bankName = _finalBankName;
      if (bankName.isEmpty || (_selectedBankCode == 'LAINNYA' && _bankCustomController.text.trim().isEmpty)) {
        AppDialog.showWarning(
          context,
          title: 'Nama Bank Diperlukan',
          message: 'Silakan pilih atau ketik nama bank pencairan.',
        );
        return false;
      }
      if (_noRekController.text.trim().isEmpty) {
        AppDialog.showWarning(
          context,
          title: 'Nomor Rekening Diperlukan',
          message: 'Silakan masukkan nomor rekening bank pencairan Anda.',
        );
        return false;
      }
      if (_atasNamaController.text.trim().isEmpty) {
        AppDialog.showWarning(
          context,
          title: 'Nama Pemilik Rekening Diperlukan',
          message: 'Silakan masukkan nama pemilik rekening (atas nama).',
        );
        return false;
      }

      // Save to saved accounts list if requested
      if (_saveNewAccount) {
        final newNoRek = _noRekController.text.trim();
        final alreadyIn = _savedAccounts.any((a) => a.noRekening == newNoRek);
        if (!alreadyIn) {
          _savedAccounts.add(SavedBankAccount(
            bankName: bankName,
            noRekening: newNoRek,
            atasNama: _atasNamaController.text.trim(),
          ));
        }
      }
      _bankController.text = bankName;
    } else {
      if (_savedAccounts.isEmpty) {
        AppDialog.showWarning(
          context,
          title: 'Pilih Rekening',
          message: 'Silakan gunakan tab Rekening Baru untuk memasukkan data rekening Anda.',
        );
        return false;
      }
      final selectedAcc = _savedAccounts[_selectedSavedAccountIndex];
      _bankController.text = selectedAcc.bankName;
      _noRekController.text = selectedAcc.noRekening;
      _atasNamaController.text = selectedAcc.atasNama;
    }
    return true;
  }

  bool _validateStep2() {
    if (_ahliWarisNamaController.text.trim().isEmpty) {
      AppDialog.showWarning(
        context,
        title: 'Data Ahli Waris Diperlukan',
        message: 'Silakan masukkan nama lengkap ahli waris atau penerima kuasa.',
      );
      return false;
    }
    if (_hpController.text.trim().isEmpty) {
      AppDialog.showWarning(
        context,
        title: 'Nomor HP Diperlukan',
        message: 'Silakan masukkan nomor handphone ahli waris yang dapat dihubungi.',
      );
      return false;
    }
    return true;
  }

  void _onNextStep() {
    if (_currentStep == 0) {
      if (_validateStep0()) _goToStep(1);
    } else if (_currentStep == 1) {
      if (_validateStep1()) _goToStep(2);
    } else if (_currentStep == 2) {
      if (_validateStep2()) _goToStep(3);
    }
  }

  void _onPrevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _submitPengajuan() async {
    if (!_validateStep0()) {
      _goToStep(0);
      return;
    }
    if (!_validateStep1()) {
      _goToStep(1);
      return;
    }
    if (!_validateStep2()) {
      _goToStep(2);
      return;
    }

    if (!_agreed) {
      AppDialog.showWarning(
        context,
        title: 'Persetujuan Akad Diperlukan',
        message: 'Harap centang persetujuan syarat & ketentuan akad Mudharabah sebelum melanjutkan.',
      );
      return;
    }

    final paymentProvider = context.read<PaymentProvider>();

    try {
      final snapResponse = await paymentProvider.createPayment(
        type: 'pembukaan_sijaka',
        nominal: _rawNominal,
        sijakaProdukId: _selectedProduct!.id,
        namaAhliWaris: _ahliWarisNamaController.text.trim().isNotEmpty
            ? _ahliWarisNamaController.text.trim()
            : null,
        hubunganAhliWaris: _ahliWarisNamaController.text.trim().isNotEmpty
            ? _finalHubunganAhliWaris
            : null,
        nikAhliWaris: _ktpController.text.trim().isNotEmpty
            ? _ktpController.text.trim()
            : null,
        namaBank: _bankController.text.trim().isNotEmpty
            ? _bankController.text.trim()
            : null,
        noRekening: _noRekController.text.trim().isNotEmpty
            ? _noRekController.text.trim()
            : null,
        atasNamaRekening: _atasNamaController.text.trim().isNotEmpty
            ? _atasNamaController.text.trim()
            : null,
        metodePenyerahanBagihasil: _selectedMetodeBagiHasil,
      );

      if (!mounted) return;

      if (snapResponse != null) {
        if (snapResponse.isDirectQris) {
          await QrisPreparationHelper.open(
            context,
            existingPayment: snapResponse,
            forceStatusCheckForExisting: false,
          );
        } else {
          final Widget targetScreen = snapResponse.isDirectVa
              ? NativePaymentDetailScreen(paymentResponse: snapResponse)
              : DokuWebViewScreen(paymentResponse: snapResponse);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => targetScreen,
            ),
          );
        }
      } else if (paymentProvider.errorMessage != null) {
        AppDialog.showError(
          context,
          title: 'Gagal Mengajukan Sijaka',
          message: paymentProvider.errorMessage!,
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Terjadi Kesalahan',
          message: 'Gagal memproses pengajuan Sijaka: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _onPrevStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: 'Pengajuan Sijaka',
              onBackPressed: () {
                if (_currentStep > 0) {
                  _onPrevStep();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            _buildStepProgressBar(),
            Expanded(
              child: Consumer<SijakaProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingProduk && provider.activeProdukList.isEmpty) {
                    return _buildLoadingSkeleton();
                  }

                  if (provider.produkError != null && provider.activeProdukList.isEmpty) {
                    return _buildErrorState(provider.produkError!);
                  }

                  final activeProdukList = provider.activeProdukList;
                  if (activeProdukList.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (_selectedProduct == null || !_selectedProduct!.isActive) {
                    _selectedProduct = activeProdukList.firstWhere(
                      (p) => p.tenorBulan == 6 || p.tenorBulan == 12,
                      orElse: () => activeProdukList.first,
                    );
                  }

                  return SafeArea(
                    top: false,
                    bottom: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildCurrentStepContent(activeProdukList),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, _) {
            return _buildBottomNavigationBar(paymentProvider);
          },
        ),
      ),
    );
  }

  // ==========================================
  // TOP STEP PROGRESS BAR & TABS (FLOATING MINIMALIST)
  // ==========================================
  Widget _buildStepProgressBar() {
    final progressValue = (_currentStep + 1) / 4;
    final progressPercent = (progressValue * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Pengajuan • Bagian ${_currentStep + 1} dari 4',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF166534)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTabItem(
                stepIndex: 0,
                title: 'Produk',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildTabItem(
                stepIndex: 1,
                title: 'Rekening',
                icon: Icons.account_balance_outlined,
              ),
              _buildTabItem(
                stepIndex: 2,
                title: 'Lainnya',
                icon: Icons.person_add_alt_1_outlined,
              ),
              _buildTabItem(
                stepIndex: 3,
                title: 'Review',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int stepIndex,
    required String title,
    required IconData icon,
  }) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (stepIndex <= _currentStep) {
            _goToStep(stepIndex);
          } else if (stepIndex == 1 && _validateStep0()) {
            _goToStep(1);
          } else if (stepIndex == 2 && _validateStep0() && _validateStep1()) {
            _goToStep(2);
          } else if (stepIndex == 3 && _validateStep0() && _validateStep1() && _validateStep2()) {
            _goToStep(3);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF0FDF4) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isActive
                        ? const Color(0xFF166534)
                        : (isCompleted
                            ? const Color(0xFF166534)
                            : const Color(0xFF94A3B8)),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF166534),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF166534)
                      : (isCompleted
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8)),
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 3),
                Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP CONTENT SWITCHER
  // ==========================================
  Widget _buildCurrentStepContent(List<SijakaProdukItem> activeProdukList) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Produk(activeProdukList);
      case 1:
        return _buildStep1Rekening();
      case 2:
        return _buildStep2Lainnya();
      case 3:
      default:
        return _buildStep3Review();
    }
  }

  // ==========================================
  // TAB 0: PRODUK & SIMULASI
  // ==========================================
  Widget _buildStep0Produk(List<SijakaProdukItem> activeProdukList) {
    return Column(
      key: const ValueKey('step_0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 20),
        _buildProductSelectionSection(activeProdukList),
        const SizedBox(height: 20),
        _buildNominalInputSection(),
        const SizedBox(height: 20),
        _buildSimulationSection(),
      ],
    );
  }

  // ==========================================
  // TAB 1: REKENING & METODE BAGI HASIL
  // ==========================================
  Widget _buildStep1Rekening() {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Rekening Pencairan & Bagi Hasil',
          subtitle: 'Pilih rekening untuk penyaluran bagi hasil dan pencairan modal',
          icon: Icons.account_balance_rounded,
          trailingBadge: _isProfileSynced ? _buildSyncBadge('Tersinkron Profil') : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Buttons (Rekening Tersimpan vs Rekening Baru)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isRekeningBaru = false;
                            if (_savedAccounts.isNotEmpty) {
                              final acc = _savedAccounts[_selectedSavedAccountIndex];
                              _bankController.text = acc.bankName;
                              _noRekController.text = acc.noRekening;
                              _atasNamaController.text = acc.atasNama;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isRekeningBaru ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: !_isRekeningBaru
                                ? Border.all(color: const Color(0xFF166534), width: 1.2)
                                : null,
                            boxShadow: !_isRekeningBaru
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Rekening Tersimpan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: !_isRekeningBaru ? FontWeight.bold : FontWeight.w500,
                              color: !_isRekeningBaru ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isRekeningBaru = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isRekeningBaru ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _isRekeningBaru
                                ? Border.all(color: const Color(0xFF166534), width: 1.2)
                                : null,
                            boxShadow: _isRekeningBaru
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Rekening Baru',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _isRekeningBaru ? FontWeight.bold : FontWeight.w500,
                              color: _isRekeningBaru ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // View based on toggle
              if (!_isRekeningBaru) ...[
                if (_savedAccounts.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'Belum Ada Rekening Tersimpan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tambahkan rekening baru Anda untuk menerima pencairan & bagi hasil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isRekeningBaru = true),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Gunakan Rekening Baru'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF166534),
                            side: const BorderSide(color: Color(0xFF166534)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // List of saved bank accounts (Matching Image 2)
                  Column(
                    children: List.generate(_savedAccounts.length, (idx) {
                      final acc = _savedAccounts[idx];
                      final isSelected = _selectedSavedAccountIndex == idx;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSavedAccountIndex = idx;
                              _bankController.text = acc.bankName;
                              _noRekController.text = acc.noRekening;
                              _atasNamaController.text = acc.atasNama;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF166534) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildBankLogoBadge(acc.bankName, size: 42, fontSize: 9.5),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${acc.bankShortName} — ${acc.noRekening}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: isSelected ? const Color(0xFF166534) : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        acc.atasNama,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? const Color(0xFF166534) : const Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 8),
                // Info callout from Image 2
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bagi hasil akan ditransfer ke rekening bank yang didaftarkan sesuai ketentuan produk.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Dropdown Pilihan Bank dengan Logo
                const Text(
                  'Pilih Bank Pencairan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBankCode,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      items: _bankList.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank.code,
                          child: Row(
                            children: [
                              _buildBankLogoBadge(bank.name, size: 28, fontSize: 8),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  bank.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBankCode = val;
                            final bank = _bankList.firstWhere((b) => b.code == val);
                            if (val != 'LAINNYA') {
                              _bankController.text = bank.name;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedBankCode == 'LAINNYA') ...[
                  const SizedBox(height: 14),
                  _buildSijakaTextField(
                    'Ketik Nama Bank Lainnya',
                    _bankCustomController,
                    hint: 'Contoh: Bank BJB Syariah',
                  ),
                ],
                const SizedBox(height: 14),
                _buildSijakaTextField(
                  'Nomor Rekening Bank Pencairan',
                  _noRekController,
                  hint: 'Contoh: 7148297890',
                  isNumber: true,
                ),
                const SizedBox(height: 14),
                _buildSijakaTextField(
                  'Nama Pemilik Rekening (Atas Nama)',
                  _atasNamaController,
                  hint: 'Sesuai yang tertera di buku tabungan',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _saveNewAccount,
                        onChanged: (val) => setState(() => _saveNewAccount = val ?? true),
                        activeColor: const Color(0xFF166534),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Simpan rekening ini di daftar Rekening Tersimpan',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildMetodeBagiHasilSection(),
      ],
    );
  }

  // ==========================================
  // TAB 2: LAINNYA (AHLI WARIS)
  // ==========================================
  Widget _buildStep2Lainnya() {
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAhliWarisSection(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.shield_outlined, size: 20, color: Color(0xFF166534)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data ahli waris ini bersifat mengikat demi perlindungan hak dan kepatuhan syariah akad Mudharabah KSPPS PASTI jika terjadi uzur syar\'i.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: REVIEW & KONFIRMASI
  // ==========================================
  Widget _buildStep3Review() {
    final product = _selectedProduct;
    final tenor = product?.tenorBulan ?? 12;
    final persenBulanan = product?.persenNisbahBulanan ?? 0;
    final persenTotal = product?.persenNisbahTotal ?? 0;

    final estimasiBulanan = (_rawNominal * persenBulanan) / 100;
    final totalBagiHasil = persenTotal > 0
        ? (_rawNominal * persenTotal) / 100
        : estimasiBulanan * tenor;
    final totalAkhirTenor = _rawNominal + totalBagiHasil;
    final jatuhTempoDate = _getEstimatedMaturityDate(tenor);

    final finalBank = _finalBankName;
    final finalNoRek = _noRekController.text.trim();
    final finalAtasNama = _atasNamaController.text.trim();

    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Review
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Review & Konfirmasi Pengajuan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Periksa kembali seluruh rincian pengajuan Sijaka sebelum melanjutkan ke pembayaran.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1. Review Produk & Tenor
        _buildReviewCard(
          title: 'Produk & Jangka Waktu',
          icon: Icons.grid_view_rounded,
          onEdit: () => _goToStep(0),
          children: [
            _buildReviewRow('Program Sijaka', product?.namaProduk ?? '-', isBold: true),
            _buildReviewRow('Tenor Simpanan', '$tenor Bulan'),
            _buildReviewRow('Nisbah Bagi Hasil', '$persenBulanan% / bulan', valueColor: const Color(0xFF166534), isBold: true),
            _buildReviewRow(
              'Estimasi Jatuh Tempo',
              AppDateFormatter.formatIndoFull(DateFormat('yyyy-MM-dd').format(jatuhTempoDate)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Review Nominal & Bagi Hasil
        _buildReviewCard(
          title: 'Nominal & Proyeksi Bagi Hasil',
          icon: Icons.payments_rounded,
          onEdit: () => _goToStep(0),
          children: [
            _buildReviewRow('Nominal Penempatan', AppCurrency.format(_rawNominal), isBold: true),
            _buildReviewRow('Estimasi Nisbah / Bulan', AppCurrency.format(estimasiBulanan), valueColor: const Color(0xFF166534)),
            _buildReviewRow('Estimasi Total Bagi Hasil', AppCurrency.format(totalBagiHasil), valueColor: const Color(0xFF166534), isBold: true),
            const Divider(height: 16, thickness: 0.8),
            _buildReviewRow(
              'Total Dana di Akhir Tenor',
              AppCurrency.format(totalAkhirTenor),
              isBold: true,
              valueColor: const Color(0xFF1E293B),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Review Rekening Pencairan
        _buildReviewCard(
          title: 'Rekening Pencairan & Bagi Hasil',
          icon: Icons.account_balance_rounded,
          onEdit: () => _goToStep(1),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBankLogoBadge(finalBank, size: 38, fontSize: 8.5),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finalBank,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No. Rekening: $finalNoRek',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Text(
                        'Atas Nama: $finalAtasNama',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildReviewRow('Penyaluran Bagi Hasil', _selectedMetodeBagiHasil, isBold: true),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Review Ahli Waris
        _buildReviewCard(
          title: 'Informasi Ahli Waris',
          icon: Icons.family_restroom_rounded,
          onEdit: () => _goToStep(2),
          children: [
            _buildReviewRow('Nama Lengkap', _ahliWarisNamaController.text, isBold: true),
            _buildReviewRow('Hubungan', _finalHubunganAhliWaris),
            _buildReviewRow('Nomor Kontak (HP)', _hpController.text),
            if (_ktpController.text.isNotEmpty)
              _buildReviewRow('No. KTP / NIK', _ktpController.text),
            if (_alamatController.text.isNotEmpty)
              _buildReviewRow('Alamat', _alamatController.text),
          ],
        ),
        const SizedBox(height: 18),

        // Persetujuan Akad
        _buildTermsAndConditions(),
      ],
    );
  }

  // ==========================================
  // REVIEW CARD WIDGETS
  // ==========================================
  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF166534)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_outlined, size: 13, color: Color(0xFF166534)),
                      SizedBox(width: 4),
                      Text(
                        'Ubah',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar(PaymentProvider paymentProvider) {
    final isLoading = paymentProvider.isCreatingToken;
    final isFinalStep = _currentStep == 3;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _onPrevStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 6,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (isFinalStep ? (_agreed ? _submitPengajuan : null) : _onNextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: (isFinalStep && !_agreed) ? 0 : 2,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFinalStep ? 'Lanjut Pembayaran' : 'Lanjutkan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isFinalStep ? Icons.lock_outline_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BANK BADGE HELPER
  // ==========================================
  Widget _buildBankLogoBadge(String bankName, {double size = 42, double fontSize = 11}) {
    final bank = _findBankInfo(bankName);
    final isCompact = size <= 34;

    Widget badgeContent;
    if (bank.svgAsset != null) {
      badgeContent = Padding(
        padding: EdgeInsets.all(isCompact ? 3.0 : 4.0),
        child: SvgPicture.asset(
          bank.svgAsset!,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bank.shortName,
              style: TextStyle(
                color: bank.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      );
    } else if (isCompact) {
      badgeContent = Padding(
        padding: const EdgeInsets.all(2.5),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            bank.shortName,
            style: TextStyle(
              color: bank.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              letterSpacing: -0.2,
            ),
          ),
        ),
      );
    } else {
      badgeContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 3.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                bank.icon,
                size: size * 0.38,
                color: bank.primaryColor,
              ),
              const SizedBox(height: 1),
              Text(
                bank.shortName,
                style: TextStyle(
                  color: bank.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  letterSpacing: -0.3,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: bank.svgAsset != null ? size * 1.2 : size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bank.svgAsset != null ? Colors.white : bank.badgeBg,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        border: Border.all(
          color: bank.svgAsset != null
              ? const Color(0xFFE2E8F0)
              : bank.primaryColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: bank.svgAsset != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: badgeContent,
    );
  }

  // ==========================================
  // SHARED FORM SECTIONS (REUSED FROM PREVIOUS)
  // ==========================================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF166534), Color(0xFF15803D), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Simpanan Berjangka (Sijaka)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Investasi syariah dengan nisbah bagi hasil transparan, amanah & menguntungkan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionSection(List<SijakaProdukItem> produkList) {
    return _buildSectionCard(
      title: 'Pilih Produk & Tenor',
      subtitle: 'Tersedia ${produkList.length} pilihan program Sijaka aktif',
      icon: Icons.grid_view_rounded,
      child: Column(
        children: produkList.map((product) {
          final isSelected = _selectedProduct?.id == product.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedProduct = product;
                  if (_rawNominal < product.minimalSetoran) {
                    _formatAndSetNominal(product.minimalSetoran.toInt());
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF166534) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF166534).withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF166534) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${product.tenorBulan}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Bulan',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                              height: 1.1,
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
                          Text(
                            product.namaProduk,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF166534) : const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            softWrap: true,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFBBF7D0),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${product.persenNisbahBulanan}% / bln',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                              if (product.persenNisbahTotal > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Total: ${product.persenNisbahTotal}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? const Color(0xFF166534) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: isSelected ? const Color(0xFF166534) : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Min. Setoran: ${product.formattedMinimalSetoran}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? const Color(0xFF15803D) : Colors.grey.shade600,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF166534) : const Color(0xFFCBD5E1),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNominalInputSection() {
    final minSetoran = _selectedProduct?.minimalSetoran ?? 100000;
    final isBelowMin = _rawNominal < minSetoran;

    return _buildSectionCard(
      title: 'Nominal Penempatan Modal',
      subtitle: 'Minimal penempatan: ${_selectedProduct?.formattedMinimalSetoran ?? "Rp 100.000"}',
      icon: Icons.payments_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBelowMin ? Colors.red.shade400 : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Rp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      _onNominalChanged(val);
                      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (clean.isNotEmpty) {
                        final parsed = int.parse(clean);
                        final formatted = NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: '',
                          decimalDigits: 0,
                        ).format(parsed).trim();

                        if (formatted != val) {
                          _nominalController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                if (_rawNominal > 0)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _formatAndSetNominal(0);
                      });
                    },
                  ),
              ],
            ),
          ),
          if (isBelowMin) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Nominal kurang dari minimal penempatan (${_selectedProduct?.formattedMinimalSetoran})',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Pilihan Nominal Cepat:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: _quickPresets.map((preset) {
                final isSelected = _rawNominal == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _formatAndSetNominal(preset);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF166534) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF166534) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        AppCurrency.format(preset),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSection() {
    final product = _selectedProduct;
    final tenor = product?.tenorBulan ?? 12;
    final persenBulanan = product?.persenNisbahBulanan ?? 0;
    final persenTotal = product?.persenNisbahTotal ?? 0;

    final estimasiBulanan = (_rawNominal * persenBulanan) / 100;
    final totalBagiHasil = persenTotal > 0
        ? (_rawNominal * persenTotal) / 100
        : estimasiBulanan * tenor;
    final totalAkhirTenor = _rawNominal + totalBagiHasil;
    final jatuhTempoDate = _getEstimatedMaturityDate(tenor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF166534), Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF86EFAC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Simulasi Proyeksi Bagi Hasil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Nisbah / Bulan',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppCurrency.format(estimasiBulanan),
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$persenBulanan% / bln',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: Colors.white24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Bagi Hasil',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppCurrency.format(totalBagiHasil),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${persenTotal > 0 ? "$persenTotal%" : "${persenBulanan * tenor}%"} total ($tenor bln)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Dana di Akhir Tenor:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                AppCurrency.format(totalAkhirTenor),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi Jatuh Tempo:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                AppDateFormatter.formatIndoFull(
                  DateFormat('yyyy-MM-dd').format(jatuhTempoDate),
                ),
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetodeBagiHasilSection() {
    return _buildSectionCard(
      title: 'Penyaluran Bagi Hasil',
      subtitle: 'Pilih bagaimana bagi hasil Sijaka Anda disalurkan',
      icon: Icons.sync_alt_rounded,
      child: Column(
        children: [
          _buildMetodeOption(
            title: 'Setiap Bulan (Direkomendasikan)',
            subtitle: 'Bagi hasil ditransfer secara otomatis ke rekening Anda setiap bulannya.',
            value: 'Setiap Bulan',
          ),
          const SizedBox(height: 10),
          _buildMetodeOption(
            title: 'Saat Jatuh Tempo',
            subtitle: 'Bagi hasil diakumulasikan dan dicairkan bersamaan dengan modal pokok di akhir masa tenor.',
            value: 'Saat Jatuh Tempo',
          ),
        ],
      ),
    );
  }

  Widget _buildMetodeOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedMetodeBagiHasil == value;
    return InkWell(
      onTap: () => setState(() => _selectedMetodeBagiHasil = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF166534) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF166534) : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF166534) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAhliWarisSection() {
    return _buildSectionCard(
      title: 'Informasi Ahli Waris',
      subtitle: 'Data penerima manfaat jika terjadi hal-hal tak terduga',
      icon: Icons.family_restroom_rounded,
      trailingBadge: _isProfileSynced ? _buildSyncBadge('Tersinkron Profil') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSijakaTextField('Nama Lengkap Ahli Waris', _ahliWarisNamaController, hint: 'Contoh: Siti Aisyah'),
          const SizedBox(height: 14),
          _buildSijakaDropdownField(
            label: 'Hubungan Ahli Waris',
            value: _selectedHubungan,
            items: _hubunganOptions,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedHubungan = val);
              }
            },
          ),
          if (_selectedHubungan == 'Keluarga Lainnya') ...[
            const SizedBox(height: 14),
            _buildSijakaTextField('Sebutkan hubungan', _ahliWarisHubunganCustomController, hint: 'Misal: Paman/Bibi'),
          ],
          const SizedBox(height: 14),
          _buildSijakaTextField('No. KTP / Passport', _ktpController, hint: 'Nomor identitas ahli waris', isNumber: true),
          const SizedBox(height: 14),
          _buildSijakaTextField('No. HP Ahli Waris', _hpController, hint: 'Contoh: 08123456789', isNumber: true),
          const SizedBox(height: 14),
          _buildSijakaTextField('Alamat Email', _emailController, hint: 'Email aktif ahli waris'),
          const SizedBox(height: 14),
          _buildSijakaTextField('Alamat Tinggal', _alamatController, hint: 'Alamat lengkap', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildSyncBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_rounded, size: 12, color: Color(0xFF166534)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _agreed,
              onChanged: (val) => setState(() => _agreed = val ?? false),
              activeColor: const Color(0xFF166534),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Persetujuan Akad & Ketentuan Sijaka',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Saya menyetujui syarat & ketentuan pembukaan rekening Simpanan Berjangka (Sijaka) KSPPS PASTI dengan akad Mudharabah Mutlaqah dan bersedia mematuhi seluruh AD/ART Koperasi.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailingBadge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF166534)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ?trailingBadge,
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSijakaTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          textCapitalization: maxLines > 1 ? TextCapitalization.sentences : TextCapitalization.words,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF166534), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSijakaDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: items.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF166534)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat produk Sijaka...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade700, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Produk Sijaka',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<SijakaProvider>().fetchProdukList(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined,
                  color: Colors.amber.shade700, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Produk Sijaka Aktif',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saat ini belum ada produk simpanan berjangka yang aktif untuk pengajuan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<SijakaProvider>().fetchProdukList(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
