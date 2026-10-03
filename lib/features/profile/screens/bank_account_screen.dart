import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../providers/profile_provider.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _noRekController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();
  bool _isInitialized = false;

  final List<String> _popularBanks = [
    'Bank Syariah Indonesia (BSI)',
    'Bank Central Asia (BCA)',
    'Bank Mandiri',
    'Bank Rakyat Indonesia (BRI)',
    'Bank Negara Indonesia (BNI)',
    'Bank Muamalat',
    'Bank CIMB Niaga Syariah',
    'Bank Jago Syariah',
    'Bank Lainnya',
  ];

  String _selectedBank = 'Bank Syariah Indonesia (BSI)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFormValues();
    });
  }

  void _initFormValues() {
    if (_isInitialized) return;
    final profileProvider = context.read<ProfileProvider>();
    final anggota = profileProvider.profileData?.anggota;
    final user = profileProvider.profileData?.user;

    if (anggota != null) {
      final existingBank = anggota.namaBank ?? '';
      _noRekController.text = anggota.noRekening ?? '';
      _atasNamaController.text = anggota.atasNamaRekening ?? (user?.name ?? '');

      if (existingBank.isNotEmpty) {
        if (_popularBanks.contains(existingBank)) {
          _selectedBank = existingBank;
          _bankController.text = existingBank;
        } else {
          _selectedBank = 'Bank Lainnya';
          _bankController.text = existingBank;
        }
      } else {
        _bankController.text = _selectedBank;
      }

      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final finalBankName = _selectedBank == 'Bank Lainnya'
        ? _bankController.text.trim()
        : _selectedBank;

    final updateData = <String, dynamic>{
      'nama_bank': finalBankName,
      'no_rekening': _noRekController.text.trim(),
      'atas_nama_rekening': _atasNamaController.text.trim(),
    };

    final success = await profileProvider.updateProfile(updateData);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Data Rekening Bank berhasil disimpan!'),
            ],
          ),
          backgroundColor: const Color(0xFF166534),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Gagal menyimpan data rekening bank.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bankController.dispose();
    _noRekController.dispose();
    _atasNamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Rekening Bank', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoAlert('Pastikan rekening bank atas nama Anda sendiri sesuai dengan KTP yang terdaftar untuk keperluan pencairan simpanan.'),
                    _buildSectionHeader('Data Rekening Bank', Icons.account_balance_wallet_outlined),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildDropdownBankField(),
                      if (_selectedBank == 'Bank Lainnya') ...[
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildTextField('Nama Bank Kustom', Icons.account_balance_rounded, _bankController, hint: 'Tulis nama bank lengkap'),
                      ],
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Nomor Rekening', Icons.numbers_rounded, _noRekController, hint: 'Contoh: 1234567890', isNumber: true),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Atas Nama (Pemilik Rekening)', Icons.person_outline_rounded, _atasNamaController, hint: 'Sesuai buku tabungan / KTP'),
                    ]),
                    const SizedBox(height: 40),
                    Consumer<ProfileProvider>(
                      builder: (context, profileProvider, _) {
                        final isUpdating = profileProvider.isUpdating;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isUpdating ? null : _saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: isUpdating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Simpan Rekening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBankField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Bank',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _popularBanks.contains(_selectedBank) ? _selectedBank : 'Bank Lainnya',
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _popularBanks.map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBank = val;
                    if (val != 'Bank Lainnya') {
                      _bankController.text = val;
                    } else {
                      _bankController.clear();
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoAlert(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    String? hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) => value == null || value.trim().isEmpty ? 'Harap diisi' : null,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint ?? 'Masukkan $label',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
