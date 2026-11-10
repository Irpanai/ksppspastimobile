import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/data_consent_modal.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsRegister;

  const LoginScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loginObscure = true;
  late bool _isLogin;
  late final Widget _registerScreen;
  bool _canUseBiometric = false;
  bool _hasAgreedDataConsent = false;

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.initialIsRegister;
    _checkBiometricAvailability();
    // Instantiate register screen once so that all form state (KTP, selfie, controllers, etc.)
    // is permanently retained in memory when switching between Masuk and Daftar.
    _registerScreen = RegisterScreen(
      isEmbedded: true,
      onSwitchToLogin: () => _switchTab(true),
    );
  }

  Future<void> _checkBiometricAvailability() async {
    final canAuth = await BiometricService.canCheckBiometrics();
    final isSupported = await BiometricService.isDeviceSupported();
    final isEnabled = await StorageService.isBiometricEnabled();
    final credentials = await StorageService.getBiometricCredentials();
    final savedToken = await StorageService.getToken();

    final hasStored = (credentials != null &&
            credentials['email'] != null &&
            credentials['email']!.isNotEmpty &&
            credentials['password'] != null &&
            credentials['password']!.isNotEmpty) ||
        (savedToken != null && savedToken.isNotEmpty);

    if (mounted) {
      setState(() {
        // Tombol biometrik HANYA muncul jika:
        // 1. HP mendukung sensor biometrik
        // 2. User telah mengaktifkan login biometrik di pengaturan/profil
        // 3. Ada akun yang tersimpan untuk diautentikasi
        _canUseBiometric = (canAuth || isSupported) && isEnabled && hasStored;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final credentials = await StorageService.getBiometricCredentials();
    final savedToken = await StorageService.getToken();

    final hasStored = (credentials != null &&
            credentials['email'] != null &&
            credentials['email']!.isNotEmpty &&
            credentials['password'] != null &&
            credentials['password']!.isNotEmpty) ||
        (savedToken != null && savedToken.isNotEmpty);

    if (!hasStored) {
      if (mounted) {
        AppDialog.showWarning(
          context,
          title: 'Akun Belum Terhubung',
          message: 'Silakan masuk menggunakan Email & Password terlebih dahulu untuk menghubungkan sidik jari Anda.',
        );
      }
      return;
    }

    final authenticated = await BiometricService.authenticate(
      localizedReason: 'Pindai sidik jari Anda untuk masuk ke KSPPS PASTI',
    );
    if (!authenticated) return;

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithBiometrics();
    if (!success && mounted) {
      AppDialog.showError(
        context,
        title: 'Sesi Telah Berakhir',
        message: 'Silakan masukkan Email dan Password Anda untuk memperbarui sesi login sidik jari.',
      );
    }
  }

  Future<void> _switchTab(bool isLogin) async {
    if (_isLogin == isLogin) return;
    FocusScope.of(context).unfocus();

    // Sebelum beralih ke form pendaftaran, tampilkan persetujuan pemrosesan data pribadi (UU PDP)
    if (!isLogin && !_hasAgreedDataConsent) {
      final agreed = await DataConsentModal.show(context);
      if (!agreed) {
        return; // Pengguna membatalkan, tetap di tab login
      }
      _hasAgreedDataConsent = true;
    }

    if (!mounted) return;
    setState(() => _isLogin = isLogin);
    if (isLogin) {
      _checkBiometricAvailability();
    }
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo-kspps-pasti.png'), context);
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _scrollController.dispose();
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
        barrierDismissible: true,
        builder: (dialogContext) {
          return GestureDetector(
            onTap: () {
              if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () {
                  if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                              Navigator.of(dialogContext, rootNavigator: true).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      }
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
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
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
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
                    child: Column(
                      children: [
                        // Centered Logo Card (Prominent & Clean, No back button)
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: Text(
                            _isLogin ? 'Selamat Datang Kembali!' : 'Daftar Anggota Baru',
                            key: ValueKey<bool>(_isLogin),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Ringkas dan 1 baris rapi sesuai permintaan user
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: Text(
                            _isLogin
                                ? 'Akses simpanan & pembiayaan syariah'
                                : 'Buka rekening syariah mudah & aman',
                            key: ValueKey<String>(_isLogin ? 'sub_login' : 'sub_reg'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Segmented Slider Switch (Masuk / Daftar)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    children: [
                      // Smooth Sliding Pill Animation
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          heightFactor: 1.0,
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
                          ),
                        ),
                      ),

                      // Interactive Text Buttons
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _switchTab(true),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 260),
                                  style: TextStyle(
                                    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                    color: _isLogin ? Colors.white : const Color(0xFF64748B),
                                    fontWeight: _isLogin ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  child: const Text('Masuk'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _switchTab(false),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 260),
                                  style: TextStyle(
                                    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                    color: !_isLogin ? Colors.white : const Color(0xFF64748B),
                                    fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  child: const Text('Daftar'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content Area: In-place smooth transition between Login and Register while retaining 100% of Form state
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Login Form Area
                  Visibility(
                    visible: _isLogin,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: false,
                    child: IgnorePointer(
                      ignoring: !_isLogin,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        opacity: _isLogin ? 1.0 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLoginForm(),
                              const SizedBox(height: 24),

                              // Switch to Register Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Belum punya akun? ',
                                    style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                                  ),
                                  GestureDetector(
                                    onTap: () => _switchTab(false),
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
                              Center(
                                child: Container(
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Register Form Area (KTP, Selfie, Cabang, Form fields state is preserved completely)
                  Visibility(
                    visible: !_isLogin,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: false,
                    child: IgnorePointer(
                      ignoring: _isLogin,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        opacity: !_isLogin ? 1.0 : 0.0,
                        child: _registerScreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

        // Tombol Masuk Sekarang
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

        // Quick Biometric Login (Khusus Sidik Jari, hanya muncul jika user telah mengaktifkannya)
        if (_canUseBiometric) ...[
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'atau masuk instan',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _handleBiometricLogin,
              borderRadius: BorderRadius.circular(16),
              splashColor: primaryColor.withValues(alpha: 0.12),
              highlightColor: primaryColor.withValues(alpha: 0.06),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 24,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masuk dengan Sidik Jari',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Sentuh sensor sidik jari untuk login cepat',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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