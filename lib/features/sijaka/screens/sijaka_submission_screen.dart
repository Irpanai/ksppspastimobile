import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/screens/midtrans_webview_screen.dart';
import '../models/sijaka_model.dart';
import '../providers/sijaka_provider.dart';

class SijakaSubmissionScreen extends StatefulWidget {
  const SijakaSubmissionScreen({super.key});

  @override
  State<SijakaSubmissionScreen> createState() => _SijakaSubmissionScreenState();
}

class _SijakaSubmissionScreenState extends State<SijakaSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _ahliWarisNamaController = TextEditingController();
  final TextEditingController _ahliWarisHubunganCustomController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _noRekController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();
  final TextEditingController _ktpController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  SijakaProdukItem? _selectedProduct;
  String _selectedMetodeBagiHasil = 'Setiap Bulan';
  String _selectedHubungan = 'Pasangan (Suami/Istri)';
  bool _agreed = false;
  int _rawNominal = 1000000;

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
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _ahliWarisNamaController.dispose();
    _ahliWarisHubunganCustomController.dispose();
    _bankController.dispose();
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

  Future<void> _loadProducts() async {
    final provider = context.read<SijakaProvider>();
    await provider.fetchProdukList();

    if (mounted && provider.produkList.isNotEmpty) {
      setState(() {
        if (_selectedProduct == null) {
          // Default to product with 6 or 12 months or first available
          _selectedProduct = provider.produkList.firstWhere(
            (p) => p.tenorBulan == 6 || p.tenorBulan == 12,
            orElse: () => provider.produkList.first,
          );
          if (_rawNominal < _selectedProduct!.minimalSetoran) {
            _formatAndSetNominal(_selectedProduct!.minimalSetoran.toInt());
          }
        }
      });
    }
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

  Future<void> _submitPengajuan() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih produk Sijaka terlebih dahulu.')),
      );
      return;
    }

    if (_rawNominal < _selectedProduct!.minimalSetoran) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal minimal untuk ${_selectedProduct!.namaProduk} adalah ${_selectedProduct!.formattedMinimalSetoran}.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap menyetujui syarat & ketentuan akad.')),
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
        metodePenyerahanBagihasil: _selectedMetodeBagiHasil,
      );

      if (!mounted) return;

      if (snapResponse != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MidtransWebViewScreen(snapResponse: snapResponse),
          ),
        );
      } else if (paymentProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Pengajuan Sijaka'),
          Expanded(
            child: Consumer<SijakaProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingProduk && provider.produkList.isEmpty) {
                  return _buildLoadingSkeleton();
                }

                if (provider.produkError != null && provider.produkList.isEmpty) {
                  return _buildErrorState(provider.produkError!);
                }

                final produkList = provider.produkList;
                if (produkList.isEmpty) {
                  return _buildEmptyState();
                }

                _selectedProduct ??= produkList.first;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        _buildProductSelectionSection(produkList),
                        const SizedBox(height: 24),
                        _buildSimulationSection(),
                        const SizedBox(height: 24),
                        _buildNominalInputSection(),
                        const SizedBox(height: 20),
                        _buildMetodeBagiHasilSection(),
                        const SizedBox(height: 20),
                        _buildPencairanSection(),
                        const SizedBox(height: 20),
                        _buildAhliWarisSection(),
                        const SizedBox(height: 24),
                        _buildTermsAndConditions(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
            color: const Color(0xFF166534).withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.15),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF166534)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF166534).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF166534)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${product.tenorBulan}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                product.namaProduk,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '${product.persenNisbahBulanan}% / bln',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isSelected
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Min. Setoran: ${product.formattedMinimalSetoran}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (product.persenNisbahTotal > 0) ...[
                                const Text(' • ',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                  'Total: ${product.persenNisbahTotal}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? const Color(0xFF166534)
                          : const Color(0xFFCBD5E1),
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
      subtitle:
          'Minimal penempatan: ${_selectedProduct?.formattedMinimalSetoran ?? "Rp 100.000"}',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  'Nominal kurang dari minimal penempatan (${_selectedProduct?.formattedMinimalSetoran})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
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
            physics: const BouncingScrollPhysics(),
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
                        color: isSelected
                            ? const Color(0xFF166534)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF166534)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        AppCurrency.format(preset),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
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

  Widget _buildMetodeBagiHasilSection() {
    return _buildSectionCard(
      title: 'Penyaluran Bagi Hasil',
      subtitle: 'Pilih bagaimana bagi hasil Sijaka Anda disalurkan',
      icon: Icons.sync_alt_rounded,
      child: Column(
        children: [
          _buildMetodeOption(
            title: 'Setiap Bulan (Direkomendasikan)',
            subtitle:
                'Bagi hasil ditransfer secara otomatis ke rekening Anda setiap bulannya.',
            value: 'Setiap Bulan',
          ),
          const SizedBox(height: 10),
          _buildMetodeOption(
            title: 'Saat Jatuh Tempo',
            subtitle:
                'Bagi hasil diakumulasikan dan dicairkan bersamaan dengan modal pokok di akhir masa tenor.',
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
            color: isSelected
                ? const Color(0xFF166534)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF166534)
                  : const Color(0xFF94A3B8),
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
                      color: isSelected
                          ? const Color(0xFF166534)
                          : const Color(0xFF1E293B),
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

  Widget _buildPencairanSection() {
    return _buildSectionCard(
      title: 'Informasi Rekening Pencairan',
      subtitle: 'Tujuan transfer pencairan Sijaka (Bagi hasil & Pokok)',
      icon: Icons.account_balance_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSijakaTextField('Nama Bank', _bankController, hint: 'Contoh: BCA / Mandiri / BSI'),
          const SizedBox(height: 14),
          _buildSijakaTextField('Nomor Rekening', _noRekController, hint: 'Contoh: 1234567890', isNumber: true),
          const SizedBox(height: 14),
          _buildSijakaTextField('Atas Nama (Pemilik Rekening)', _atasNamaController, hint: 'Sesuai buku tabungan'),
        ],
      ),
    );
  }

  Widget _buildAhliWarisSection() {
    return _buildSectionCard(
      title: 'Informasi Ahli Waris',
      subtitle: 'Data penerima manfaat jika terjadi hal-hal tak terduga',
      icon: Icons.family_restroom_rounded,
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
          _buildSijakaTextField('No. KTP / Passport (Opsional)', _ktpController, hint: 'Nomor identitas ahli waris', isNumber: true),
          const SizedBox(height: 14),
          _buildSijakaTextField('No. HP Ahli Waris', _hpController, hint: 'Contoh: 08123456789', isNumber: true),
          const SizedBox(height: 14),
          _buildSijakaTextField('Alamat Email (Opsional)', _emailController, hint: 'Email aktif ahli waris'),
          const SizedBox(height: 14),
          _buildSijakaTextField('Alamat Tinggal', _alamatController, hint: 'Alamat lengkap', maxLines: 3),
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
                  child: Text(opt, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
            color: const Color(0xFF166534).withOpacity(0.25),
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
                  color: Colors.white.withOpacity(0.12),
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
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
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
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.verified_user_outlined,
                  color: Color(0xFF86EFAC), size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Akad Mudharabah Muthlaqah sesuai syariah Islam & fatwa DSN MUI.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ),
            ],
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
              children: [
                const Text(
                  'Persetujuan Akad & Ketentuan Sijaka',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
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

  Widget _buildSubmitButton() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final isLoading = paymentProvider.isCreatingToken;
        final isValid = _agreed &&
            _selectedProduct != null &&
            _rawNominal >= _selectedProduct!.minimalSetoran;

        return ElevatedButton(
          onPressed: (isValid && !isLoading) ? _submitPengajuan : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF166534),
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isValid ? 3 : 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Lanjut ke Pembayaran Midtrans',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
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
          const SizedBox(height: 18),
          child,
        ],
      ),
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
