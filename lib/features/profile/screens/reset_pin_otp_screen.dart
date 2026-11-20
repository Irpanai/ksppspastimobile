import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/pin_service.dart';
import '../providers/profile_provider.dart';

class ResetPinOtpScreen extends StatefulWidget {
  final bool autoSendOtp;

  const ResetPinOtpScreen({
    super.key,
    this.autoSendOtp = false,
  });

  @override
  State<ResetPinOtpScreen> createState() => _ResetPinOtpScreenState();
}

class _ResetPinOtpScreenState extends State<ResetPinOtpScreen> {
  final PinService _pinService = PinService();

  int _step = 0; // 0: Minta OTP, 1: Masukkan OTP & PIN Baru
  String _targetEmail = '';

  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';

  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      _targetEmail = email;
    }

    if (widget.autoSendOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendOtp();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() => _countdownSeconds = 0);
      } else {
        setState(() => _countdownSeconds--);
      }
    });
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final res = await _pinService.requestForgotPinOtp();
      final masked = res['email']?.toString() ?? _targetEmail;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 1;
        _targetEmail = masked;
      });
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isResend
                      ? 'Kode OTP baru telah dikirim ke $masked'
                      : 'Kode OTP telah dikirim ke email $masked',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0E7955),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Gagal mengirim kode OTP. Pastikan koneksi internet stabil.';
      });
    }
  }

  Future<void> _handleSubmitReset() async {
    final otp = _otpController.text.trim();
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _isError = true;
        _errorMessage = 'Kode OTP harus terdiri dari 6 angka.';
      });
      return;
    }

    if (pin.length != 6) {
      setState(() {
        _isError = true;
        _errorMessage = 'PIN baru harus terdiri dari 6 digit angka.';
      });
      return;
    }

    if (pin != confirm) {
      setState(() {
        _isError = true;
        _errorMessage = 'Konfirmasi PIN baru tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final success = await _pinService.resetPinWithOtp(
        otp: otp,
        pin: pin,
        pinConfirmation: confirm,
      );

      if (!mounted) return;

      if (success) {
        Provider.of<AuthProvider>(context, listen: false).updateHasPin(true);
        Provider.of<ProfileProvider>(context, listen: false).updateHasPin(true);
        Provider.of<ProfileProvider>(context, listen: false).fetchProfileDetail(refresh: true);

        AppDialog.showSuccess(
          context,
          title: 'PIN Berhasil Dibuat Ulang',
          message:
              'PIN transaksi baru Anda telah aktif dan blokir keamanan akun telah dibuka kembali. Anda dapat bertransaksi kembali dengan aman.',
          buttonText: 'Selesai',
          barrierDismissible: false,
          onConfirm: () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          },
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Gagal mereset PIN. Silakan periksa kembali kode OTP Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          PremiumHeader(
            title: 'Reset PIN Transaksi',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _step == 0 ? _buildStepSendOtp() : _buildStepInputOtpAndNewPin(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 0: Tampilan Informasi & Tombol Kirim Kode OTP
  // ─────────────────────────────────────────────────────────────
  Widget _buildStepSendOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: Color(0xFF0E7955),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Atur Ulang PIN Transaksi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'PIN transaksi Anda terblokir atau Anda lupa PIN lama? Kami akan mengirimkan 6 digit kode OTP verifikasi ke email terdaftar Anda.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Card Info Email Terdaftar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_outlined, color: Color(0xFF0E7955), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Penerima OTP',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _targetEmail.isNotEmpty ? _targetEmail : 'Email terdaftar pada akun Anda',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_isError) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 16),

        // TOMBOL UTAMA: KIRIM KODE OTP KE EMAIL
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _handleSendOtp(),
            icon: _isLoading
                ? const SizedBox.shrink()
                : const Icon(Icons.send_rounded, size: 18),
            label: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Kirim Kode OTP ke Email',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7955),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Kembali',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 1: Masukkan Kode OTP & Input PIN Baru 6 Digit
  // ─────────────────────────────────────────────────────────────
  Widget _buildStepInputOtpAndNewPin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Info
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 32,
                  color: Color(0xFF0E7955),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Verifikasi OTP & Buat PIN',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan 6 digit kode OTP yang dikirim ke $_targetEmail',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // INPUT 1: KODE OTP
        const Text(
          'KODE OTP EMAIL (6 DIGIT)',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 10, color: Color(0xFF0E7955)),
          decoration: InputDecoration(
            hintText: '••••••',
            hintStyle: const TextStyle(fontSize: 22, letterSpacing: 10, color: Color(0xFFCBD5E1)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.8)),
          ),
        ),

        const SizedBox(height: 10),

        // Baris Kirim Ulang OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tidak menerima kode?',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (_countdownSeconds > 0)
              Text(
                'Kirim ulang dalam ${_countdownSeconds}s',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              )
            else
              InkWell(
                onTap: _isLoading ? null : () => _handleSendOtp(isResend: true),
                child: const Text(
                  'Kirim Ulang OTP',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0E7955), fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 20),

        // INPUT 2: PIN BARU
        const Text(
          'PIN BARU (6 DIGIT ANGKA)',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: _obscurePin,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: '6 digit angka PIN baru',
            hintStyle: const TextStyle(fontSize: 13, letterSpacing: 0, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0E7955), size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.8)),
          ),
        ),

        const SizedBox(height: 16),

        // INPUT 3: KONFIRMASI PIN BARU
        const Text(
          'KONFIRMASI PIN BARU',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPinController,
          keyboardType: TextInputType.number,
          obscureText: _obscureConfirmPin,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Ketik ulang 6 digit PIN baru',
            hintStyle: const TextStyle(fontSize: 13, letterSpacing: 0, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0E7955), size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
              onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.8)),
          ),
        ),

        const SizedBox(height: 18),

        if (_isError) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 12),

        // TOMBOL SUBMIT RESET PIN
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmitReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7955),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Simpan PIN Baru & Buka Blokir',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
            label: const Text(
              'Ganti Alamat Email / Minta Ulang OTP',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
