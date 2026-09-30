import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../providers/profile_provider.dart';

class AddressDataScreen extends StatefulWidget {
  const AddressDataScreen({Key? key}) : super(key: key);

  @override
  State<AddressDataScreen> createState() => _AddressDataScreenState();
}

class _AddressDataScreenState extends State<AddressDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _alamatController;
  late TextEditingController _provinsiController;
  late TextEditingController _kabupatenKotaController;
  late TextEditingController _kecamatanController;
  late TextEditingController _kelurahanController;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    final anggota = profileProvider.profileData?.anggota;
    final user = profileProvider.profileData?.user;

    _alamatController = TextEditingController(text: anggota?.alamat ?? user?.anggota?.alamat ?? '');
    _provinsiController = TextEditingController(text: anggota?.provinsi ?? '');
    _kabupatenKotaController = TextEditingController(text: anggota?.kabupatenKota ?? '');
    _kecamatanController = TextEditingController(text: anggota?.kecamatan ?? '');
    _kelurahanController = TextEditingController(text: anggota?.kelurahan ?? '');
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _provinsiController.dispose();
    _kabupatenKotaController.dispose();
    _kecamatanController.dispose();
    _kelurahanController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final updateData = <String, dynamic>{
      if (_provinsiController.text.trim().isNotEmpty) 'provinsi': _provinsiController.text.trim(),
      if (_kabupatenKotaController.text.trim().isNotEmpty) 'kabupaten_kota': _kabupatenKotaController.text.trim(),
      if (_kecamatanController.text.trim().isNotEmpty) 'kecamatan': _kecamatanController.text.trim(),
      if (_kelurahanController.text.trim().isNotEmpty) 'kelurahan': _kelurahanController.text.trim(),
      if (_alamatController.text.trim().isNotEmpty) 'alamat': _alamatController.text.trim(),
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
              Expanded(child: Text('Alamat Domisili berhasil diperbarui!')),
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
          const PremiumHeader(title: 'Alamat Domisili', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoAlert('Pastikan alamat yang Anda masukkan sesuai dengan domisili tempat tinggal Anda saat ini untuk memudahkan korespodensi.'),
                    _buildSectionHeader('Alamat Domisili', Icons.home_work_outlined),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField('Alamat Lengkap (Jalan / RT / RW)', Icons.home_outlined, _alamatController, maxLines: 2, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Provinsi', Icons.map_outlined, _provinsiController, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Kabupaten / Kota', Icons.location_city_rounded, _kabupatenKotaController, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Kecamatan', Icons.apartment_rounded, _kecamatanController, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Kelurahan / Desa', Icons.signpost_outlined, _kelurahanController, enabled: !isUpdating),
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
    int maxLines = 1,
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
          maxLines: maxLines,
          enabled: enabled,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Masukkan $label',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF94A3B8), size: 18) : null,
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
