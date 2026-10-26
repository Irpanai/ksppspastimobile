import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum KycCameraMode {
  ktp,
  selfie,
}

class KycCameraScreen extends StatefulWidget {
  final KycCameraMode mode;

  const KycCameraScreen({
    super.key,
    required this.mode,
  });

  @override
  State<KycCameraScreen> createState() => _KycCameraScreenState();
}

class _KycCameraScreenState extends State<KycCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isTakingPicture = false;
  FlashMode _flashMode = FlashMode.off;
  bool _hasFlash = false;

  // Preview state after capture
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Tidak ada sensor kamera yang terdeteksi di perangkat ini.';
        });
        return;
      }

      CameraDescription? selectedCamera;

      if (widget.mode == KycCameraMode.selfie) {
        // Kunci HANYA kamera depan untuk selfie
        try {
          selectedCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
          );
        } catch (_) {
          // Jika tidak ada kamera depan khusus, gunakan kamera pertama
          selectedCamera = _cameras.first;
        }
      } else {
        // Kunci HANYA kamera belakang untuk KTP
        try {
          selectedCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
          );
        } catch (_) {
          selectedCamera = _cameras.first;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();

      // Cek dukungan flash pada kamera belakang
      if (widget.mode == KycCameraMode.ktp &&
          selectedCamera.lensDirection == CameraLensDirection.back) {
        _hasFlash = true;
      } else {
        _hasFlash = false;
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('KycCameraScreen init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Gagal mengakses kamera: $e\nPastikan izin kamera telah diberikan di pengaturan HP.';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized || !_hasFlash) return;

    try {
      final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _controller!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      HapticFeedback.mediumImpact();

      // Ambil foto
      final XFile photo = await _controller!.takePicture();

      // Matikan torch jika aktif
      if (_flashMode == FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.off);
        _flashMode = FlashMode.off;
      }

      setState(() {
        _capturedFile = photo;
        _isTakingPicture = false;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
      setState(() => _isTakingPicture = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedFile = null;
    });
  }

  void _confirmPicture() {
    if (_capturedFile != null) {
      Navigator.pop(context, File(_capturedFile!.path));
    }
  }

  Future<void> _fallbackImagePicker() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: widget.mode == KycCameraMode.selfie
            ? CameraDevice.front
            : CameraDevice.rear,
        imageQuality: 90,
      );
      if (file != null && mounted) {
        Navigator.pop(context, File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKtp = widget.mode == KycCameraMode.ktp;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          top: false,
          bottom: true,
          child: _capturedFile != null
              ? _buildPreviewUI(primaryColor, isKtp)
              : _buildCameraUI(primaryColor, isKtp),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 1. LIVE CAMERA VIEW DENGAN WIREFRAME OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildCameraUI(Color primaryColor, bool isKtp) {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isInitializing || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
            const SizedBox(height: 18),
            Text(
              isKtp ? 'Menyiapkan Kamera Belakang (KTP)...' : 'Menyiapkan Kamera Depan (Selfie)...',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return Stack(
          fit: StackFit.expand,
          children: [
            // A. Camera Live Preview
            Center(
              child: CameraPreview(_controller!),
            ),

            // B. Wireframe Cutout Overlay (KTP Kotak / Selfie Oval)
            CustomPaint(
              size: size,
              painter: KycOverlayPainter(
                mode: widget.mode,
                borderColor: primaryColor,
              ),
            ),

            // C. Top Controls & Guidance Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup Kamera',
                    ),
                  ),

                  // Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isKtp ? Icons.badge_outlined : Icons.face_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isKtp ? 'KAMERA BELAKANG • e-KTP' : 'KAMERA DEPAN • SELFIE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flash Torch Button (Hanya jika KTP & kamera belakang punya flash)
                  if (_hasFlash)
                    Container(
                      decoration: BoxDecoration(
                        color: _flashMode == FlashMode.torch
                            ? Colors.amber.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.torch
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: _flashMode == FlashMode.torch ? Colors.black : Colors.white,
                          size: 22,
                        ),
                        onPressed: _toggleFlash,
                        tooltip: 'Flash Senter',
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // D. Header Hint / Instructions
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      isKtp ? 'Posisikan e-KTP di Dalam Kotak' : 'Posisikan Wajah di Dalam Lingkaran',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKtp
                          ? 'Pastikan NIK, nama, dan foto terlihat terang tanpa pantulan cahaya'
                          : 'Lepas masker/kacamata & pastikan wajah berada di dalam bingkai',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // E. Bottom Shutter Controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shutter Button
                  GestureDetector(
                    onTap: _isTakingPicture ? null : _takePicture,
                    child: Container(
                      width: 82,
                      height: 82,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: _isTakingPicture
                            ? Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : Icon(
                                isKtp ? Icons.camera_alt_rounded : Icons.face_rounded,
                                color: primaryColor,
                                size: 34,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    isKtp ? 'Ketuk untuk foto e-KTP' : 'Ketuk untuk foto selfie',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 2. PRATINJAU HASIL FOTO (CONFIRM / RETAKE)
  // ─────────────────────────────────────────────
  Widget _buildPreviewUI(Color primaryColor, bool isKtp) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Display Captured Image
        Center(
          child: Image.file(
            File(_capturedFile!.path),
            fit: BoxFit.contain,
          ),
        ),

        // Semi-transparent top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isKtp ? 'Periksa Foto e-KTP' : 'Periksa Foto Selfie',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isKtp
                            ? 'Pastikan NIK dan nama terbaca jelas tanpa blur atau pantulan.'
                            : 'Pastikan wajah Anda terlihat terang dan jelas.',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Bar: Retake vs Confirm
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Retake Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retakePicture,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Foto Ulang',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _confirmPicture,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Gunakan Foto Ini',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 3. ERROR & FALLBACK STATE
  // ─────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_rounded, size: 54, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Akses Kamera Dibatasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Tidak dapat mengakses kamera perangkat.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fallbackImagePicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kamera Sistem'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: OVERLAY DENGAN HOLE CUTOUT & CORNER BRACKETS
// ─────────────────────────────────────────────────────────────────
class KycOverlayPainter extends CustomPainter {
  final KycCameraMode mode;
  final Color borderColor;

  KycOverlayPainter({
    required this.mode,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (mode == KycCameraMode.ktp) {
      // ── KTP WIREFRAME (CARD RATIO 1.585) ──
      final cardWidth = size.width * 0.88;
      final cardHeight = cardWidth / 1.585;
      final left = (size.width - cardWidth) / 2;
      final top = (size.height - cardHeight) / 2 - 20; // Sedikit ke atas agar seimbang dengan kontrol
      final cardRect = Rect.fromLTWH(left, top, cardWidth, cardHeight);
      final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(16));

      // Cutout mask using Path.combine
      final backgroundPath = Path()..addRect(fullRect);
      final cutoutPath = Path()..addRRect(cardRRect);
      final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

      canvas.drawPath(overlayPath, backgroundPaint);

      // Card border
      canvas.drawRRect(cardRRect, borderPaint);

      // Corner brackets (L-shape di 4 sudut)
      const cornerLength = 26.0;

      // Top-Left
      canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top + 14), cornerPaint);
      canvas.drawLine(Offset(left + 14, top), Offset(left + cornerLength, top), cornerPaint);

      // Top-Right
      final right = left + cardWidth;
      canvas.drawLine(Offset(right, top + cornerLength), Offset(right, top + 14), cornerPaint);
      canvas.drawLine(Offset(right - 14, top), Offset(right - cornerLength, top), cornerPaint);

      // Bottom-Left
      final bottom = top + cardHeight;
      canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom - 14), cornerPaint);
      canvas.drawLine(Offset(left + 14, bottom), Offset(left + cornerLength, bottom), cornerPaint);

      // Bottom-Right
      canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom - 14), cornerPaint);
      canvas.drawLine(Offset(right - 14, bottom), Offset(right - cornerLength, bottom), cornerPaint);

      // Subtle Photo Placeholder box inside KTP (Sisi Kiri/Kanan)
      final photoBoxWidth = cardWidth * 0.28;
      final photoBoxHeight = cardHeight * 0.65;
      final photoBoxRect = Rect.fromLTWH(
        right - photoBoxWidth - 14,
        top + (cardHeight - photoBoxHeight) / 2,
        photoBoxWidth,
        photoBoxHeight,
      );
      final photoBoxPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(RRect.fromRectAndRadius(photoBoxRect, const Radius.circular(8)), photoBoxPaint);

    } else {
      // ── SELFIE WIREFRAME (OVAL FACE GUIDE) ──
      final ovalWidth = size.width * 0.72;
      final ovalHeight = ovalWidth * 1.35;
      final center = Offset(size.width / 2, size.height * 0.44);
      final ovalRect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

      // Cutout mask
      final backgroundPath = Path()..addRect(fullRect);
      final cutoutPath = Path()..addOval(ovalRect);
      final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

      canvas.drawPath(overlayPath, backgroundPaint);

      // Oval border
      canvas.drawOval(ovalRect, borderPaint..strokeWidth = 2.5);

      // Subtle Glowing Head Silhouette indicator
      final glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0;
      canvas.drawOval(ovalRect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant KycOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.borderColor != borderColor;
  }
}