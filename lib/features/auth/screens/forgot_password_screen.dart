import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../../shared/widgets/pin_verification_dialog.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/auth_provider.dart';

enum ForgotPasswordStep {
  chooseMethod,     // Pemilihan metode untuk user yang login
  inputEmail,       // Step 1 Alur Email: Masukkan email
  inputOtp,         // Step 2 Alur Email: Masukkan 6 digit OTP
  inputNewPassword, // Step Form Ubah Password (Hanya muncul jika PIN/OTP terverifikasi)
  success,          // Tampilan berhasil
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.inputEmail;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;

  // Status Verifikasi PIN
  bool _isPinVerified = false;
  String? _verifiedPin;

  // Timer hitung mundur OTP
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        // User sedang login (diakses dari Halaman Profil / Keamanan Akun)
        _emailController.text = user.email;

        if (user.hasPin) {
          setState(() {
            _currentStep = ForgotPasswordStep.chooseMethod;
          });
        } else {
          setState(() {
            _currentStep = ForgotPasswordStep.inputEmail;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── POP-UP PIN VERIFIKASI LANGSUNG (TIDAK BERBENTUK FORMULIR) ──
  Future<void> _handleTriggerPinVerification() async {
    // Tampilkan pop-up dialog PIN
    final verifiedPin = await PinVerificationDialog.showForPin(
      context,
      title: 'Verifikasi PIN Transaksi',
      subtitle: 'Masukkan 6 digit PIN untuk membuka form ubah password',
    );

    if (!mounted) return;

    if (verifiedPin != null && verifiedPin.length == 6) {
      // PIN Benar: Buka form ubah password
      setState(() {
        _isPinVerified = true;
        _verifiedPin = verifiedPin;
        _currentStep = ForgotPasswordStep.inputNewPassword;
      });
    } else {
      // PIN Salah atau Dibatalkan:
      // Form ubah password TIDAK MUNCUL dan user tetap tidak bisa edit password
      setState(() {
        _isPinVerified = false;
        _verifiedPin = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Verifikasi PIN dibatalkan. Form ubah password tetap terkunci.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF475569),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Alur Kirim Kode OTP Email ──
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Silakan masukkan alamat email yang valid.');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final responseData = await authProvider.requestForgotPasswordOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (responseData != null) {
      _startResendTimer();
      setState(() {
        _currentStep = ForgotPasswordStep.inputOtp;
      });
    } else {
      _showError(authProvider.errorMessage ?? 'Gagal mengirim kode OTP. Periksa alamat email Anda.');
    }
  }

  // ── Alur Verifikasi Kode OTP Email ──
  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('Kode OTP harus terdiri dari 6 digit.');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = await authProvider.verifyResetOtp(email: email, otp: otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      setState(() {
        _isPinVerified = false;
        _currentStep = ForgotPasswordStep.inputNewPassword;
      });
    } else {
      _showError(authProvider.errorMessage ?? 'Kode OTP salah atau telah kadaluarsa.');
    }
  }

  // ── Simpan Password Baru (Baik via PIN maupun via Email OTP) ──
  Future<void> _handleSaveNewPassword() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.length < 6) {
      _showError('Password baru minimal harus 6 karakter.');
      return;
    }

    if (newPass != confirmPass) {
      _showError('Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);

    if (_isPinVerified && _verifiedPin != null) {
      // Simpan menggunakan otorisasi PIN Transaksi
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.resetPasswordWithPin(
        pin: _verifiedPin!,
        password: newPass,
        passwordConfirmation: confirmPass,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _currentStep = ForgotPasswordStep.success;
        });
      } else {
        _showError(profileProvider.errorMessage ?? 'Gagal memperbarui password akun.');
      }
    } else {
      // Simpan menggunakan otorisasi Email + OTP
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPasswordWithOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: newPass,
        passwordConfirmation: confirmPass,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _currentStep = ForgotPasswordStep.success;
        });
      } else {
        _showError(authProvider.errorMessage ?? 'Gagal mengatur ulang password.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          PremiumHeader(
            title: _currentStep == ForgotPasswordStep.success
                ? 'Selesai'
                : 'Lupa Password',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildCurrentStepWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case ForgotPasswordStep.chooseMethod:
        return _buildChooseMethodState();
      case ForgotPasswordStep.inputEmail:
        return _buildInputEmailState();
      case ForgotPasswordStep.inputOtp:
        return _buildInputOtpState();
      case ForgotPasswordStep.inputNewPassword:
        return _buildInputNewPasswordState();
      case ForgotPasswordStep.success:
        return _buildSuccessState();
    }
  }

  // ── 1. PILIH METODE (PIN Langsung Pop Up vs Email OTP) ──
  Widget _buildChooseMethodState() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7955).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 56, color: Color(0xFF0E7955)),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Pemulihan Password',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Verifikasi keamanan akun ${user?.name ?? ''} terlebih dahulu sebelum mengubah password:',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // Opsi 1: Reset Cepat via PIN Transaksi (Bentuk Pop Up)
        _buildMethodCard(
          icon: Icons.pin_outlined,
          title: 'Verifikasi PIN Transaksi',
          subtitle: 'Masukkan 6 digit PIN Anda melalui pop-up keamanan untuk membuka form ubah password.',
          badge: 'Instan & Cepat',
          badgeColor: const Color(0xFF10B981),
          onTap: _handleTriggerPinVerification,
        ),

        const SizedBox(height: 16),

        // Opsi 2: Reset via Email OTP
        _buildMethodCard(
          icon: Icons.mail_outline_rounded,
          title: 'Kirim Kode ke Email',
          subtitle: 'Kirim 6 digit kode OTP verifikasi ke ${user?.email ?? 'email terdaftar'}.',
          onTap: () {
            setState(() {
              _currentStep = ForgotPasswordStep.inputEmail;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E7955).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0E7955), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor ?? const Color(0xFF0E7955)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ── 2. INPUT EMAIL ──
  Widget _buildInputEmailState() {
    final authUser = Provider.of<AuthProvider>(context, listen: false).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7955).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 56, color: Color(0xFF0E7955)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Atur Ulang Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan alamat email yang terdaftar pada akun Anda. Kami akan mengirimkan 6 digit kode OTP verifikasi.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        const SizedBox(height: 28),
        const Text(
          'Alamat Email',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'nama@email.com',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.5)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7955),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Kirim Kode OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        if (authUser != null && authUser.hasPin) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _handleTriggerPinVerification,
              icon: const Icon(Icons.pin_outlined, size: 18, color: Color(0xFF0E7955)),
              label: const Text('Buka Pop-up PIN Transaksi', style: TextStyle(color: Color(0xFF0E7955), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  // ── 3. INPUT OTP EMAIL (6 DIGIT) ──
  Widget _buildInputOtpState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7955).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_unread_outlined, size: 56, color: Color(0xFF0E7955)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verifikasi Kode OTP',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            children: [
              const TextSpan(text: 'Masukkan 6 digit kode verifikasi yang telah kami kirimkan ke '),
              TextSpan(
                text: _emailController.text,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Kode OTP (6 Digit)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '------',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak menerima kode? ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            if (_resendCountdown > 0)
              Text('Kirim ulang ($_resendCountdown s)', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))
            else
              GestureDetector(
                onTap: _isLoading ? null : _handleSendOtp,
                child: const Text('Kirim Ulang', style: TextStyle(fontSize: 13, color: Color(0xFF0E7955), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7955),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Verifikasi OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── 4. FORM UBAH PASSWORD BARU (HANYA MUNCUL JIKA PIN BENAR / OTP BENAR) ──
  Widget _buildInputNewPasswordState() {
    // Validasi pengaman: jika PIN belum terverifikasi dan bukan via OTP valid, jangan tampilkan form!
    if (!_isPinVerified && _otpController.text.length != 6) {
      return _buildChooseMethodState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7955).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, size: 56, color: Color(0xFF0E7955)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Text(
                  _isPinVerified ? 'PIN Transaksi Terverifikasi' : 'Kode OTP Terverifikasi',
                  style: const TextStyle(color: Color(0xFF0E7955), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buat Password Baru',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          _isPinVerified
              ? 'PIN transaksi Anda valid. Silakan buat password baru akun Anda.'
              : 'Verifikasi berhasil. Silakan tentukan password baru akun Anda.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        const SizedBox(height: 28),
        _buildPasswordField(
          label: 'Password Baru',
          controller: _newPassController,
          obscureText: _newObscure,
          onToggle: () => setState(() => _newObscure = !_newObscure),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Konfirmasi Password Baru',
          controller: _confirmPassController,
          obscureText: _confirmObscure,
          onToggle: () => setState(() => _confirmObscure = !_confirmObscure),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSaveNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7955),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Simpan Password Baru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── 5. STATE BERHASIL ──
  Widget _buildSuccessState() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 28),
          const Text(
            'Password Berhasil Diubah',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Text(
            user != null
                ? 'Password akun Anda telah berhasil diperbarui. Anda dapat langsung menggunakannya saat masuk berikutnya.'
                : 'Password akun Anda telah berhasil diperbarui. Silakan masuk menggunakan password baru Anda.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7955),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(user != null ? 'Kembali ke Profil' : 'Kembali ke Login', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Minimal 6 karakter',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
