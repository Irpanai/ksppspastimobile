import 'package:flutter/material.dart';

class PinVerificationDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const PinVerificationDialog({
    super.key,
    this.title = 'Masukkan PIN',
    this.subtitle = 'Masukkan 6 digit PIN akun Anda',
  });

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const PinVerificationDialog(),
    );
    return result ?? false;
  }

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String _pin = '';
  bool _isError = false;

  void _onKeyPress(String key) {
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _isError = false;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() async {
    // Simulasi verifikasi PIN
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Anggap "123456" sebagai PIN dummy yang benar (karena belum ada setting PIN di backend)
    if (_pin == '123456') {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        setState(() {
          _isError = true;
          _pin = '';
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
                onTap: () => Navigator.pop(context, false),
                child: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ),
            const Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFF0E7955)),
            const SizedBox(height: 16),
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
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
                    color: isFilled ? const Color(0xFF0E7955) : const Color(0xFFE2E8F0),
                    border: Border.all(
                      color: _isError ? Colors.red : (isFilled ? const Color(0xFF0E7955) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                );
              }),
            ),
            
            if (_isError) ...[
              const SizedBox(height: 12),
              const Text('PIN salah. Silakan coba lagi.', style: TextStyle(color: Colors.red, fontSize: 13)),
            ] else ...[
              const SizedBox(height: 12),
              const Text('PIN Default: 123456', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic)),
            ],
            
            const SizedBox(height: 32),
            
            // Keypad
            Flexible(
              child: GridView.builder(
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
                  if (index == 9) return const SizedBox.shrink(); // Kosong di kiri bawah
                  if (index == 11) {
                    return InkWell(
                      onTap: _onDeletePress,
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Icon(Icons.backspace_outlined, color: Color(0xFF475569)),
                      ),
                    );
                  }
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onKeyPress(number),
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
