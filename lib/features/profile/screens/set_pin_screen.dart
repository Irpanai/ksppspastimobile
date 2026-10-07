import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/pin_service.dart';

enum PinFlowMode { setup, change }

class SetPinScreen extends StatefulWidget {
  final PinFlowMode? mode;

  const SetPinScreen({super.key, this.mode});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final PinService _pinService = PinService();

  // Mode: 0 for setup (new -> confirm), 1 for change (old -> new -> confirm)
  late PinFlowMode _mode;

  int _currentStep = 0; // 0: Old (if change) or New (if setup), 1: New (if change) or Confirm, 2: Confirm (if change)
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';

  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasPin = authProvider.user?.hasPin ?? false;
    _mode = widget.mode ?? (hasPin ? PinFlowMode.change : PinFlowMode.setup);
  }

  String get _currentPinInput {
    if (_mode == PinFlowMode.setup) {
      return _currentStep == 0 ? _newPin : _confirmPin;
    } else {
      if (_currentStep == 0) return _oldPin;
      if (_currentStep == 1) return _newPin;
      return _confirmPin;
    }
  }

  void _onKeyPress(String key) {
    if (_isLoading) return;

    setState(() {
      _isError = false;
      _errorMessage = '';

      if (_mode == PinFlowMode.setup) {
        if (_currentStep == 0 && _newPin.length < 6) {
          _newPin += key;
          if (_newPin.length == 6) {
            _currentStep = 1;
          }
        } else if (_currentStep == 1 && _confirmPin.length < 6) {
          _confirmPin += key;
          if (_confirmPin.length == 6) {
            _submitSetupPin();
          }
        }
      } else {
        // Change Mode
        if (_currentStep == 0 && _oldPin.length < 6) {
          _oldPin += key;
          if (_oldPin.length == 6) {
            _currentStep = 1;
          }
        } else if (_currentStep == 1 && _newPin.length < 6) {
          _newPin += key;
          if (_newPin.length == 6) {
            _currentStep = 2;
          }
        } else if (_currentStep == 2 && _confirmPin.length < 6) {
          _confirmPin += key;
          if (_confirmPin.length == 6) {
            _submitChangePin();
          }
        }
      }
    });
  }

  void _onDeletePress() {
    if (_isLoading) return;

    setState(() {
      _isError = false;
      _errorMessage = '';

      if (_mode == PinFlowMode.setup) {
        if (_currentStep == 1) {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          } else {
            _currentStep = 0;
          }
        } else if (_currentStep == 0 && _newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      } else {
        if (_currentStep == 2) {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          } else {
            _currentStep = 1;
          }
        } else if (_currentStep == 1) {
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          } else {
            _currentStep = 0;
          }
        } else if (_currentStep == 0 && _oldPin.isNotEmpty) {
          _oldPin = _oldPin.substring(0, _oldPin.length - 1);
        }
      }
    });
  }

  void _submitSetupPin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _isError = true;
        _errorMessage = 'Konfirmasi PIN tidak cocok.';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _pinService.setupPin(
        pin: _newPin,
        pinConfirmation: _confirmPin,
      );

      if (success && mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateHasPin(true);
        _showSuccessAndPop('PIN Berhasil Dibuat', 'PIN transaksi Anda telah aktif dan dapat digunakan untuk keamanan transaksi.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.message;
          _confirmPin = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal menyimpan PIN. Silakan coba lagi.';
          _confirmPin = '';
          _isLoading = false;
        });
      }
    }
  }

  void _submitChangePin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _isError = true;
        _errorMessage = 'Konfirmasi PIN baru tidak cocok.';
        _confirmPin = '';
      });
      return;
    }

    if (_oldPin == _newPin) {
      setState(() {
        _isError = true;
        _errorMessage = 'PIN baru tidak boleh sama dengan PIN lama.';
        _newPin = '';
        _confirmPin = '';
        _currentStep = 1;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _pinService.changePin(
        oldPin: _oldPin,
        newPin: _newPin,
        newPinConfirmation: _confirmPin,
      );

      if (success && mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateHasPin(true);
        _showSuccessAndPop('PIN Berhasil Diperbarui', 'PIN transaksi Anda telah berhasil diperbarui.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.message;
          _isLoading = false;
          if (e.message.toLowerCase().contains('lama')) {
            _oldPin = '';
            _newPin = '';
            _confirmPin = '';
            _currentStep = 0;
          } else {
            _confirmPin = '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal memperbarui PIN. Silakan coba lagi.';
          _confirmPin = '';
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessAndPop(String title, String message) {
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
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7955),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    if (_mode == PinFlowMode.setup) {
      return _currentStep == 0 ? 'Buat PIN Transaksi' : 'Konfirmasi PIN';
    } else {
      if (_currentStep == 0) return 'Masukkan PIN Lama';
      if (_currentStep == 1) return 'Masukkan PIN Baru';
      return 'Konfirmasi PIN Baru';
    }
  }

  String get _stepSubtitle {
    if (_mode == PinFlowMode.setup) {
      return _currentStep == 0
          ? 'Masukkan 6 digit angka untuk PIN keamanan'
          : 'Ketik ulang 6 digit PIN untuk konfirmasi';
    } else {
      if (_currentStep == 0) return 'Masukkan 6 digit PIN lama Anda';
      if (_currentStep == 1) return 'Masukkan 6 digit PIN baru yang Anda inginkan';
      return 'Ketik ulang 6 digit PIN baru untuk konfirmasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _currentPinInput;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          PremiumHeader(
            title: _mode == PinFlowMode.setup ? 'Buat PIN' : 'Ubah PIN',
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Icon(
                      _currentStep > 0 ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                      size: 48,
                      color: const Color(0xFF0E7955),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _stepTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _stepSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // PIN Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < currentInput.length;
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

                  const SizedBox(height: 16),
                  if (_isLoading) ...[
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0E7955)),
                    ),
                  ] else if (_isError) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage.isNotEmpty ? _errorMessage : 'PIN tidak sesuai.',
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                              child: Icon(Icons.backspace_outlined, color: Color(0xFF475569), size: 28),
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

