import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isError = false;
  bool _isLoading = false;

  void _onKeyPress(String key) {
    if ((_isConfirming ? _confirmPin.length : _pin.length) < 6) {
      setState(() {
        if (_isConfirming) {
          _confirmPin += key;
        } else {
          _pin += key;
        }
        _isError = false;
      });
      
      if (_isConfirming && _confirmPin.length == 6) {
        _verifyAndSubmit();
      } else if (!_isConfirming && _pin.length == 6) {
        setState(() => _isConfirming = true);
      }
    }
  }

  void _onDeletePress() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirming && _confirmPin.isEmpty) {
        _isConfirming = false; // Go back to first PIN entry
      }
      _isError = false;
    });
  }

  void _verifyAndSubmit() async {
    if (_pin != _confirmPin) {
      setState(() {
        _isError = true;
        _confirmPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi PIN tidak cocok, silakan coba lagi.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi API set PIN
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSuccessAndPop();
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
              const Text('PIN Berhasil Diatur', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('PIN Anda berhasil disimpan dan sudah aktif untuk transaksi selanjutnya.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Atur PIN'),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(_isConfirming ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded, size: 64, color: const Color(0xFF0E7955)),
                  const SizedBox(height: 24),
                  Text(
                    _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Transaksi',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isConfirming ? 'Masukkan kembali PIN yang Anda buat' : 'Masukkan 6 digit angka untuk PIN keamanan',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 48),

                  // PIN Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < currentPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFF0E7955) : Colors.transparent,
                          border: Border.all(
                            color: _isError ? Colors.red : (isFilled ? const Color(0xFF0E7955) : const Color(0xFFCBD5E1)),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(color: Color(0xFF0E7955)),
                  ],

                  const Spacer(),

                  // Keypad
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 24,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index == 9) return const SizedBox.shrink();
                        if (index == 11) {
                          return InkWell(
                            onTap: _isLoading ? null : _onDeletePress,
                            borderRadius: BorderRadius.circular(24),
                            child: const Center(
                              child: Icon(Icons.backspace_outlined, color: Color(0xFF475569)),
                            ),
                          );
                        }
                        final number = index == 10 ? '0' : '${index + 1}';
                        return InkWell(
                          onTap: _isLoading ? null : () => _onKeyPress(number),
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Text(
                              number,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                        );
                      },
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
