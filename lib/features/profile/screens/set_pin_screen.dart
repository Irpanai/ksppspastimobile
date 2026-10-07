import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/pin_service.dart';
import '../providers/profile_provider.dart';

enum PinFlowMode { setup, change }

class SetPinScreen extends StatefulWidget {
  final PinFlowMode? mode;

  const SetPinScreen({super.key, this.mode});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final PinService _pinService = PinService();

  late PinFlowMode _mode;
  int _currentStep = 0; // 0: Old/New, 1: New/Confirm, 2: Confirm (if change)
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

  int get _totalSteps => _mode == PinFlowMode.setup ? 2 : 3;

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
        // Change Mode: 0: Old PIN -> 1: New PIN -> 2: Confirm New PIN
        if (_currentStep == 0 && _oldPin.length < 6) {
          _oldPin += key;
          if (_oldPin.length == 6) {
            _currentStep = 1;
          }
        } else if (_currentStep == 1 && _newPin.length < 6) {
          _newPin += key;
          if (_newPin.length == 6) {
            if (_newPin == _oldPin) {
              _isError = true;
              _errorMessage = 'PIN baru tidak boleh sama dengan PIN lama.';
              _newPin = '';
            } else {
              _currentStep = 2;
            }
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
        Provider.of<ProfileProvider>(context, listen: false).updateHasPin(true);
        Provider.of<ProfileProvider>(context, listen: false).fetchProfileDetail(refresh: true);
        _showSuccessAndPop('PIN Berhasil Dibuat', 'PIN transaksi Anda telah aktif dan siap digunakan.');
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
        Provider.of<ProfileProvider>(context, listen: false).updateHasPin(true);
        Provider.of<ProfileProvider>(context, listen: false).fetchProfileDetail(refresh: true);
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
          ? 'Masukkan 6 digit angka untuk PIN keamanan transaksi'
          : 'Ketik ulang 6 digit PIN untuk konfirmasi';
    } else {
      if (_currentStep == 0) return 'Masukkan 6 digit PIN lama Anda untuk verifikasi';
      if (_currentStep == 1) return 'Masukkan 6 digit PIN baru yang Anda inginkan';
      return 'Ketik ulang 6 digit PIN baru untuk konfirmasi';
    }
  }

  IconData get _stepIcon {
    if (_mode == PinFlowMode.setup) {
      return _currentStep == 0 ? Icons.shield_outlined : Icons.check_circle_outline_rounded;
    } else {
      if (_currentStep == 0) return Icons.lock_open_rounded;
      if (_currentStep == 1) return Icons.lock_reset_rounded;
      return Icons.check_circle_outline_rounded;
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
            child: Column(
              children: [
                // Top Content Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),

                          // Step Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security, size: 14, color: Color(0xFF0E7955)),
                                const SizedBox(width: 6),
                                Text(
                                  'Langkah ${_currentStep + 1} dari $_totalSteps',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0E7955),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Icon Circle
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                            ),
                            child: Icon(
                              _stepIcon,
                              size: 32,
                              color: const Color(0xFF0E7955),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Title
                          Text(
                            _stepTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            _stepSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.3),
                          ),

                          const SizedBox(height: 24),

                          // PIN 6 Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              final isFilled = index < currentInput.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 7),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled ? const Color(0xFF0E7955) : Colors.transparent,
                                  border: Border.all(
                                    color: _isError
                                        ? Colors.red
                                        : (isFilled ? const Color(0xFF0E7955) : const Color(0xFFCBD5E1)),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 16),

                          // Loading / Error
                          if (_isLoading)
                            const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0E7955)),
                              ),
                            )
                          else if (_isError)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _errorMessage.isNotEmpty ? _errorMessage : 'PIN tidak sesuai.',
                                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 24),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // Keypad anchored to bottom
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['', '0', 'delete']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 68, height: 50);
        }

        if (key == 'delete') {
          return SizedBox(
            width: 68,
            height: 50,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _onDeletePress,
                borderRadius: BorderRadius.circular(24),
                child: const Center(
                  child: Icon(Icons.backspace_outlined, color: Color(0xFF475569), size: 24),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: 68,
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () => _onKeyPress(key),
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
