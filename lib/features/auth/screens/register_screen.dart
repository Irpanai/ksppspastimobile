import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../main_nav/screens/main_nav_screen.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCabang = 'Pusat';
  bool _isObscure1 = true;
  bool _isObscure2 = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final name = _nameController.text.trim();
    final nik = _nikController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showWarning('Silakan masukkan nama lengkap sesuai KTP.');
      return;
    }

    if (nik.length != 16) {
      _showWarning('NIK harus berjumlah 16 digit angka.');
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showWarning('Silakan masukkan nomor handphone yang valid (min. 10 digit).');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showWarning('Silakan masukkan format alamat email yang valid.');
      return;
    }

    if (password.length < 6) {
      _showWarning('Password minimal harus 6 karakter.');
      return;
    }

    if (password != confirmPassword) {
      _showWarning('Konfirmasi password tidak cocok.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: confirmPassword,
      nik: nik,
      noHp: phone,
      alamat: address.isNotEmpty ? address : null,
      cabang: _selectedCabang,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Pendaftaran berhasil! Selamat datang di KSPPS PASTI.', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      _showError(authProvider.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Anggota Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Text
              const Text(
                'Bergabunglah bersama KSPPS PASTI.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data diri Anda di bawah ini untuk membuka rekening simpanan syariah secara instan.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Form Fields
              _buildLabel('Nama Lengkap (Sesuai KTP) *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Contoh: Budi Santoso',
                icon: Icons.person_outline_rounded,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Nomor Induk Kependudukan (NIK 16 Digit) *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nikController,
                hint: '3301xxxxxxxxxxxx',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                maxLength: 16,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                ],
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Nomor Handphone / WhatsApp *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hint: '081234567890',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                ],
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Alamat Email Aktif *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'nasabah@domain.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Password Akun *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Min. 6 karakter',
                icon: Icons.lock_outline_rounded,
                isObscure: _isObscure1,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(_isObscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Konfirmasi Password *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Ulangi password',
                icon: Icons.lock_outline_rounded,
                isObscure: _isObscure2,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(_isObscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Alamat Domisili (Opsional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hint: 'Jl. Pemuda No. 10, Semarang',
                icon: Icons.location_on_outlined,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Cabang Pendaftaran'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCabang,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                    items: ['Pusat', 'Semarang Barat', 'Kudus', 'Solo'].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          'Cabang $val',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      );
                    }).toList(),
                    onChanged: isLoading ? null : (v) {
                      if (v != null) setState(() => _selectedCabang = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Sudah punya akun? ',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Masuk di sini',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool isObscure = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        inputFormatters: [
          if (inputFormatters != null) ...inputFormatters,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength, maxLengthEnforcement: MaxLengthEnforcement.enforced),
        ],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
            letterSpacing: isObscure ? 2 : 0,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
