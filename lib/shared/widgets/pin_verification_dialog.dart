import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/services/pin_service.dart';
import '../../features/profile/screens/set_pin_screen.dart';

class PinVerificationDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const PinVerificationDialog({
    super.key,
    this.title = 'Masukkan PIN Transaksi',
    this.subtitle = 'Masukkan 6 digit PIN keamanan akun Anda',
  });

  /// Static helper to trigger PIN verification dialog
  static Future<bool> show(
    BuildContext context, {
    String title = 'Masukkan PIN Transaksi',
    String subtitle = 'Masukkan 6 digit PIN keamanan akun Anda',
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Jika user belum mengatur PIN, arahkan ke pembuatan PIN terlebih dahulu
    if (user != null && !user.hasPin) {
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0E7955)),
              SizedBox(width: 8),
              Text('PIN Belum Dibuat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Untuk keamanan transaksi finansial, Anda wajib membuat 6 digit PIN terlebih dahulu.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7955),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Buat PIN Sekarang'),
            ),
          ],
        ),
      );

      if (shouldCreate == true && context.mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const SetPinScreen()),
        );
        if (result != true) return false;
      } else {
        return false;
      }
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PinVerificationDialog(
        title: title,
        subtitle: subtitle,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final PinService _pinService = PinService();
  String _pin = '';
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = false;

  void _onKeyPress(String key) {
    if (_isLoading) return;
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _isError = false;
        _errorMessage = '';
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePress() {
    if (_isLoading) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final success = await _pinService.verifyPin(_pin);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.message;
          _pin = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Terjadi kesalahan. Coba lagi.';
          _pin = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: _isLoading ? null : () => Navigator.pop(context, false),
                child: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF0E7955)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 24),

            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFF0E7955) : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: _isError ? Colors.red : (isFilled ? const Color(0xFF0E7955) : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),
            if (_isLoading) ...[
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E7955)),
              ),
            ] else if (_isError) ...[
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'PIN yang Anda masukkan salah.',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 16),

            // Keypad
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  return const SizedBox.shrink(); // Empty space or biometric icon placeholder
                }
                if (index == 11) {
                  return InkWell(
                    onTap: _isLoading ? null : _onDeletePress,
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Icon(Icons.backspace_outlined, color: Color(0xFF475569), size: 24),
                    ),
                  );
                }
                final number = index == 10 ? '0' : '${index + 1}';
                return InkWell(
                  onTap: _isLoading ? null : () => _onKeyPress(number),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

