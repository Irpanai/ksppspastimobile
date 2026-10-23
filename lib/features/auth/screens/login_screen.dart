import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo-kspps-pasti.png'), context);
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty) {
      AppDialog.showWarning(
        context,
        title: 'Data Belum Lengkap',
        message: 'Silakan masukkan alamat email akun Anda.',
      );
      return;
    }

    if (password.isEmpty) {
      AppDialog.showWarning(
        context,
        title: 'Data Belum Lengkap',
        message: 'Silakan masukkan password akun Anda.',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
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
                  const SizedBox(height: 20),
                  const Text(
                    'Login Berhasil!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang kembali,\n${authProvider.user?.name ?? "Nasabah"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final nav = Navigator.of(context, rootNavigator: true);
      await Future.delayed(const Duration(milliseconds: 1000));
      nav.pop();
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Gagal login. Silakan periksa kembali email & password Anda.';
      AppDialog.showError(
        context,
        title: 'Gagal Masuk',
        message: errorMsg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section with Lush Gradient & Balanced Presence
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
                            child: Column(
                              children: [
                                // Logo Card (Enlarged for prominent brand presence)
                                Container(
                                  height: 82,
                                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.10),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo-kspps-pasti.png',
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Selamat Datang Kembali!',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Akses layanan simpanan & pembiayaan syariah',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main Form Area
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Segmented Switch (Masuk / Daftar)
                            Container(
                              height: 46,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF2F7),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Form Fields
                            _buildLoginForm(),
                          ],
                        ),
                      ),

                      // Bottom Group: Registration Link & Security Badge
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Column(
                          children: [
                            // Belum punya akun? Daftar Sekarang
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Belum memiliki akun nasabah? ',
                                  style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Trust & Security Notice
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Terdaftar & Diawasi Kementerian Koperasi & UKM RI',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email Nasabah'),
        const SizedBox(height: 7),
        _buildTextField(
          controller: _loginEmailController,
          hint: 'nasabah@ksppspasti.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),

        _buildLabel('Password'),
        const SizedBox(height: 7),
        _buildTextField(
          controller: _loginPasswordController,
          hint: 'Masukkan password akun',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.visiblePassword,
          isObscure: _loginObscure,
          enabled: !isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(() => _loginObscure = !_loginObscure),
          ),
        ),

        // Lupa Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lupa Password?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Tombol Masuk Sekarang (Ikon dihilangkan sesuai permintaan user)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              shadowColor: primaryColor.withValues(alpha: 0.3),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Text(
                    'Masuk Sekarang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
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
        color: enabled ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        ),
      ),
    );
  }
}