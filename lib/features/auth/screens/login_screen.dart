import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main_nav/screens/main_nav_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Slider state: true = Masuk, false = Daftar
  bool _isLogin = true;

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regNikController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regObscure = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regNikController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Silakan masukkan email Anda.', style: TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B), // Amber for warning
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 16, right: 16),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Silakan masukkan password akun Anda.', style: TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B), // Amber for warning
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 16, right: 16),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      // Tampilkan popup sukses di tengah
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
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
                  const SizedBox(height: 24),
                  const Text('Login Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang kembali,\n${authProvider.user?.name ?? 'Nasabah'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Simpan referensi Navigator karena widget akan di-unmount oleh AuthWrapper
      final nav = Navigator.of(context, rootNavigator: true);

      // Tunggu sebentar agar animasi popup terlihat
      await Future.delayed(const Duration(milliseconds: 1000));

      // Tutup dialog secara eksplisit menggunakan referensi Navigator
      nav.pop();
      
      // Catatan: Tidak perlu Navigator.pushAndRemoveUntil ke MainNavScreen di sini
      // karena AuthWrapper di main.dart otomatis mengubah route ke MainNavScreen 
      // ketika AuthStatus berubah menjadi authenticated.
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Gagal login. Silakan periksa kembali email & password Anda.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444), // Red for error
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 16, right: 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Header Section (Premium Photorealistic Design)
            Container(
              height: 380,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        // Logo Section
                        Center(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Image.asset(
                              'web/logo-kspps-pasti.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _isLogin ? 'Selamat Datang\nKembali!' : 'Bergabung\nBersama Kami!',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Silakan masuk dengan akun nasabah Anda.' : 'Lengkapi data Anda untuk mendaftar.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Interactive Slider and Forms
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Slider (Masuk / Daftar)
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: _isLogin
                                    ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Masuk',
                                style: TextStyle(
                                  color: _isLogin ? Colors.white : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_isLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: !_isLogin
                                    ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Daftar',
                                style: TextStyle(
                                  color: !_isLogin ? Colors.white : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Switcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutQuint,
                    switchOutCurve: Curves.easeInQuint,
                    child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email Nasabah'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _loginEmailController,
          hint: 'nasabah@ksppspasti.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
        ),
        const SizedBox(height: 24),

        _buildLabel('Password'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _loginPasswordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.visiblePassword,
          isObscure: _loginObscure,
          enabled: !isLoading,
          suffixIcon: IconButton(
            icon: Icon(_loginObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
            onPressed: () => setState(() => _loginObscure = !_loginObscure),
          ),
        ),
        
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Lupa Password?', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: isLoading ? null : _submitLogin,
                icon: Icon(Icons.fingerprint_rounded, color: Theme.of(context).colorScheme.primary, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Masuk Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nama Lengkap (Sesuai KTP)'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _regNameController,
          hint: 'Masukkan nama lengkap',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        
        _buildLabel('Nomor Induk Kependudukan'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _regNikController,
          hint: '16 digit NIK',
          icon: Icons.credit_card_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),

        _buildLabel('Nomor Handphone'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _regPhoneController,
          hint: '081234567890',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        
        _buildLabel('Password Akun'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _regPasswordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isObscure: _regObscure,
          suffixIcon: IconButton(
            icon: Icon(_regObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
            onPressed: () => setState(() => _regObscure = !_regObscure),
          ),
        ),
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isLogin = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pendaftaran berhasil diajukan! Silakan login.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
            child: const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
            letterSpacing: isObscure ? 2 : 0,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
