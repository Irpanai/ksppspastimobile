import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../providers/profile_provider.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _pekerjaanController;

  String? _selectedJenisKelamin;
  String? _selectedAgama;
  DateTime? _selectedTanggalLahir;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    final anggota = profileProvider.profileData?.anggota;

    _tempatLahirController = TextEditingController(text: anggota?.tempatLahir ?? '');
    _tanggalLahirController = TextEditingController(text: anggota?.tanggalLahir ?? '');
    _pekerjaanController = TextEditingController(text: anggota?.pekerjaan ?? '');

    _selectedJenisKelamin = anggota?.jenisKelamin ?? 'Laki-laki';
    _selectedAgama = anggota?.agama ?? 'Islam';

    if (anggota?.tanggalLahir != null && anggota!.tanggalLahir!.isNotEmpty) {
      try {
        _selectedTanggalLahir = DateTime.parse(anggota.tanggalLahir!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _pekerjaanController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalLahir() async {
    final initialDate = _selectedTanggalLahir ?? DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTanggalLahir = picked;
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitUpdate() async {
    final updateData = <String, dynamic>{
      if (_tempatLahirController.text.trim().isNotEmpty) 'tempat_lahir': _tempatLahirController.text.trim(),
      if (_tanggalLahirController.text.trim().isNotEmpty) 'tanggal_lahir': _tanggalLahirController.text.trim(),
      if (_selectedJenisKelamin != null) 'jenis_kelamin': _selectedJenisKelamin,
      if (_selectedAgama != null) 'agama': _selectedAgama,
      if (_pekerjaanController.text.trim().isNotEmpty) 'pekerjaan': _pekerjaanController.text.trim(),
    };

    final profileProvider = context.read<ProfileProvider>();
    final success = await profileProvider.updateProfile(updateData);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Data Pribadi berhasil diperbarui!')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(profileProvider.errorMessage ?? 'Gagal memperbarui profil')),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = context.watch<ProfileProvider>().isUpdating;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Data Pribadi (KYC)', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoAlert('Lengkapi data identitas (KYC) Anda untuk memenuhi standar operasional dan keamanan layanan KSPPS.'),
                    _buildSectionHeader('Data Pribadi (KYC)', Icons.assignment_ind_outlined),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField('Tempat Lahir', Icons.location_city_outlined, _tempatLahirController, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      InkWell(
                        onTap: isUpdating ? null : _pickTanggalLahir,
                        child: IgnorePointer(
                          child: _buildTextField(
                            'Tanggal Lahir',
                            Icons.calendar_today_outlined,
                            _tanggalLahirController,
                            hint: 'YYYY-MM-DD',
                            enabled: !isUpdating,
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildDropdownField(
                        label: 'Jenis Kelamin',
                        value: _selectedJenisKelamin,
                        items: ['Laki-laki', 'Perempuan'],
                        onChanged: isUpdating ? null : (val) => setState(() => _selectedJenisKelamin = val),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildDropdownField(
                        label: 'Agama',
                        value: _selectedAgama,
                        items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'],
                        onChanged: isUpdating ? null : (val) => setState(() => _selectedAgama = val),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Pekerjaan / Profesi', Icons.work_outline_rounded, _pekerjaanController, enabled: !isUpdating),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _submitUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
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
    bool enabled = true,
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
          enabled: enabled,
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

  Widget _buildDropdownField({
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: items.map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
}
