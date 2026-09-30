import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nikController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _alamatController;
  late TextEditingController _provinsiController;
  late TextEditingController _kabupatenKotaController;
  late TextEditingController _kecamatanController;
  late TextEditingController _kelurahanController;

  String? _selectedJenisKelamin;
  String? _selectedAgama;
  DateTime? _selectedTanggalLahir;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    final authUser = context.read<AuthProvider>().user;
    final anggota = profileProvider.profileData?.anggota;

    _nameController = TextEditingController(text: profileProvider.profileData?.user.name ?? authUser?.name ?? '');
    _emailController = TextEditingController(text: profileProvider.profileData?.user.email ?? authUser?.email ?? '');
    _phoneController = TextEditingController(text: anggota?.noHp ?? anggota?.noTelpon ?? authUser?.anggota?.noHp ?? '');
    _nikController = TextEditingController(text: anggota?.nik ?? anggota?.noKtp ?? authUser?.anggota?.nik ?? '');
    _tempatLahirController = TextEditingController(text: anggota?.tempatLahir ?? '');
    _tanggalLahirController = TextEditingController(text: anggota?.tanggalLahir ?? '');
    _pekerjaanController = TextEditingController(text: anggota?.pekerjaan ?? '');
    _alamatController = TextEditingController(text: anggota?.alamat ?? authUser?.anggota?.alamat ?? '');
    _provinsiController = TextEditingController(text: anggota?.provinsi ?? '');
    _kabupatenKotaController = TextEditingController(text: anggota?.kabupatenKota ?? '');
    _kecamatanController = TextEditingController(text: anggota?.kecamatan ?? '');
    _kelurahanController = TextEditingController(text: anggota?.kelurahan ?? '');

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _pekerjaanController.dispose();
    _alamatController.dispose();
    _provinsiController.dispose();
    _kabupatenKotaController.dispose();
    _kecamatanController.dispose();
    _kelurahanController.dispose();
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final nik = _nikController.text.trim();

    if (name.isEmpty) {
      _showWarning('Nama lengkap tidak boleh kosong');
      return;
    }

    final updateData = <String, dynamic>{
      'name': name,
      if (email.isNotEmpty) 'email': email,
      if (phone.isNotEmpty) ...{
        'no_hp': phone,
        'no_telpon': phone,
      },
      if (nik.isNotEmpty) ...{
        'nik': nik,
        'no_ktp': nik,
      },
      if (_tempatLahirController.text.trim().isNotEmpty) 'tempat_lahir': _tempatLahirController.text.trim(),
      if (_tanggalLahirController.text.trim().isNotEmpty) 'tanggal_lahir': _tanggalLahirController.text.trim(),
      if (_selectedJenisKelamin != null) 'jenis_kelamin': _selectedJenisKelamin,
      if (_selectedAgama != null) 'agama': _selectedAgama,
      if (_pekerjaanController.text.trim().isNotEmpty) 'pekerjaan': _pekerjaanController.text.trim(),
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
      // Refresh AuthProvider profile too
      context.read<AuthProvider>().fetchProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Data profil berhasil diperbarui!')),
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

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isUpdating = profileProvider.isUpdating;
    final user = profileProvider.profileData?.user ?? context.watch<AuthProvider>().user;
    final photoUrl = user?.fullProfilePhotoUrl ?? ApiConstants.resolveImageUrl(user?.profilePhotoUrl);
    final userName = user?.name ?? 'Nasabah';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Edit Data Profil'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar Card
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? Image.network(
                                      photoUrl,
                                      width: 95,
                                      height: 95,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(userName),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : _buildDefaultAvatar(userName),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Identitas Utama
                    _buildSectionHeader('Identitas & Akun', Icons.person_pin_rounded),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField('Nama Lengkap', Icons.person_outline, _nameController, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField('Email', Icons.email_outlined, _emailController, keyboardType: TextInputType.emailAddress, enabled: !isUpdating),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        'Nomor Handphone / WA',
                        Icons.phone_android_rounded,
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                        ],
                        enabled: !isUpdating,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        'NIK (16 Digit)',
                        Icons.badge_outlined,
                        _nikController,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                        ],
                        enabled: !isUpdating,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Section: Data Pribadi (KYC)
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
                    const SizedBox(height: 24),

                    // Section: Alamat Domisili
                    _buildSectionHeader('Alamat & Domisili', Icons.home_work_outlined),
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

                    // Submit Button
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          inputFormatters: [
            if (inputFormatters != null) ...inputFormatters,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength, maxLengthEnforcement: MaxLengthEnforcement.enforced),
          ],
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
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

  Widget _buildDefaultAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'N';
    return Container(
      width: 95,
      height: 95,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'N',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
