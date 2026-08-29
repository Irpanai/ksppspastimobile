import 'package:flutter/material.dart';
import '../../main_nav/screens/main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Slider state: true = Masuk, false = Daftar
  bool _isLogin = true;

  // Login Controllers
  final _loginIdController = TextEditingController();
  final _loginPinController = TextEditingController();
  bool _loginObscure = true;

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regNikController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regObscure = true;

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPinController.dispose();
    _regNameController.dispose();
    _regNikController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavScreen()),
    );
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
                      Theme.of(context).colorScheme.primary, // Using true green
                      Theme.of(context).colorScheme.secondary, // Using deep green
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
                          _isLogin ? 'Silakan masuk untuk melanjutkan.' : 'Lengkapi data Anda untuk mendaftar.',
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
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('ID Anggota'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _loginIdController,
          hint: 'Masukkan ID Anggota',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        _buildLabel('PIN Transaksi'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _loginPinController,
          hint: '••••••',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
          isObscure: _loginObscure,
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
            child: Text('Lupa PIN?', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
                onPressed: _submit,
                icon: Icon(Icons.fingerprint_rounded, color: Theme.of(context).colorScheme.primary, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  child: const Text('Masuk Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        
        _buildLabel('Buat PIN Transaksi (6 Digit)'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _regPasswordController,
          hint: '••••••',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
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
              // Automatically switch to login on success
              setState(() => _isLogin = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
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
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontWeight: FontWeight.normal, letterSpacing: isObscure ? 4 : 0),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
