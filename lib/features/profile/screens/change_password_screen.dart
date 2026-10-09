import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../auth/screens/forgot_password_screen.dart';
import '../providers/profile_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _oldObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;

  void _submit() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showError('Mohon lengkapi semua kolom password.');
      return;
    }

    if (newPass.length < 6) {
      _showError('Password baru minimal 6 karakter.');
      return;
    }

    if (newPass != confirmPass) {
      _showError('Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final success = await profileProvider.changePassword(
      currentPassword: oldPass,
      password: newPass,
      passwordConfirmation: confirmPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccessAndPop();
    } else {
      _showError(profileProvider.errorMessage ?? 'Gagal mengubah password. Pastikan password lama sesuai.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Berhasil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Password akun Anda berhasil diubah.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7955),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0E7955), width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Ganti Password'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Password Lama',
                    controller: _oldPassController,
                    isObscure: _oldObscure,
                    onToggleObscure: () => setState(() => _oldObscure = !_oldObscure),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Lupa password lama?',
                          style: TextStyle(
                            color: Color(0xFF0E7955),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildTextField(
                    label: 'Password Baru',
                    controller: _newPassController,
                    isObscure: _newObscure,
                    onToggleObscure: () => setState(() => _newObscure = !_newObscure),
                  ),
                  _buildTextField(
                    label: 'Konfirmasi Password Baru',
                    controller: _confirmPassController,
                    isObscure: _confirmObscure,
                    onToggleObscure: () => setState(() => _confirmObscure = !_confirmObscure),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Simpan Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
