import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/app_dialog.dart';

class KycImageNormalizationService {
  static const MethodChannel _channel = MethodChannel('com.ksppspasti.mobile/kyc_image');

  /// Menormalkan orientasi EXIF dan menerapkan cermin horizontal untuk kamera depan
  /// agar hasil tangkapan selfie konsisten dengan pratinjau cermin saat memotret,
  /// serta mendukung crop landscape e-KTP dan rotasi 90 derajat.
  static Future<String> normalizeCapturedPhoto({
    required String path,
    required bool mirrorHorizontal,
    bool cropToKtpLandscape = false,
    int rotateDegrees = 0,
    double targetAspectRatio = 1.585,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return path;
    }

    try {
      final args = <String, dynamic>{
        'path': path,
        'mirrorHorizontal': mirrorHorizontal,
      };
      if (cropToKtpLandscape) {
        args['cropToKtpLandscape'] = true;
      }
      if (rotateDegrees != 0) {
        args['rotateDegrees'] = rotateDegrees;
      }
      if ((targetAspectRatio - 1.585).abs() > 0.001) {
        args['targetAspectRatio'] = targetAspectRatio;
      }

      final normalized = await _channel.invokeMethod<String>(
        'normalizeCapturedPhoto',
        args,
      );
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    } catch (e) {
      debugPrint('KycImageNormalizationService fallback to raw path: $e');
    }
    return path;
  }
}

enum KycCameraMode {
  ktp,
  selfie,
}

class KycCameraScreen extends StatefulWidget {
  final KycCameraMode mode;
  @visibleForTesting
  final File? initialCapturedFile;

  const KycCameraScreen({
    super.key,
    required this.mode,
    this.initialCapturedFile,
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
  bool _isFlippingPreview = false;
  bool _isRotatingPreview = false;
  bool _isFrontCamera = false;
  FlashMode _flashMode = FlashMode.off;
  bool _hasFlash = false;

  // Preview state after capture
  XFile? _capturedFile;
  final Set<String> _generatedTempPaths = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.mode == KycCameraMode.ktp) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    if (widget.initialCapturedFile != null) {
      _isInitializing = false;
      _isFrontCamera = widget.mode == KycCameraMode.selfie;
      _capturedFile = XFile(widget.initialCapturedFile!.path);
    } else {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _deleteTempFileIfOwned(String? path) async {
    if (path == null || !_generatedTempPaths.remove(path)) return;
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
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
      _isFrontCamera = selectedCamera.lensDirection == CameraLensDirection.front;

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

      // Selaraskan orientasi EXIF & hilangkan perbedaan cerminan antara preview kamera depan dan file hasil.
      // Untuk KTP: otomatis potong (crop) ke mode landscape kartu (~1.585:1, sekira 4:3 s.d 16:9).
      final normalizedPath = await KycImageNormalizationService.normalizeCapturedPhoto(
        path: photo.path,
        mirrorHorizontal: _isFrontCamera,
        cropToKtpLandscape: widget.mode == KycCameraMode.ktp,
        targetAspectRatio: 1.585,
      );
      if (normalizedPath != photo.path) {
        _generatedTempPaths.add(normalizedPath);
      }

      if (!mounted) return;
      setState(() {
        _capturedFile = XFile(normalizedPath);
        _isTakingPicture = false;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (!mounted) return;
      setState(() => _isTakingPicture = false);
      AppDialog.showError(
        context,
        title: 'Gagal Mengambil Foto',
        message: 'Tidak dapat memotret menggunakan kamera: $e',
      );
    }
  }

  Future<void> _rotatePreviewImage() async {
    if (_capturedFile == null || _isRotatingPreview) return;
    final previousPath = _capturedFile!.path;
    setState(() => _isRotatingPreview = true);
    try {
      final rotatedPath = await KycImageNormalizationService.normalizeCapturedPhoto(
        path: previousPath,
        mirrorHorizontal: false,
        rotateDegrees: 90,
      );
      if (!mounted) return;
      if (rotatedPath != previousPath) {
        _generatedTempPaths.add(rotatedPath);
        setState(() {
          _capturedFile = XFile(rotatedPath);
        });
        await _deleteTempFileIfOwned(previousPath);
      }
    } finally {
      if (mounted) {
        setState(() => _isRotatingPreview = false);
      }
    }
  }

  Future<void> _flipPreviewImage() async {
    if (_capturedFile == null || _isFlippingPreview) return;
    final previousPath = _capturedFile!.path;
    setState(() => _isFlippingPreview = true);
    try {
      final flippedPath = await KycImageNormalizationService.normalizeCapturedPhoto(
        path: previousPath,
        mirrorHorizontal: true,
      );
      if (!mounted) return;
      if (flippedPath != previousPath) {
        _generatedTempPaths.add(flippedPath);
        setState(() {
          _capturedFile = XFile(flippedPath);
        });
        await _deleteTempFileIfOwned(previousPath);
      }
    } finally {
      if (mounted) {
        setState(() => _isFlippingPreview = false);
      }
    }
  }

  void _retakePicture() {
    final oldPath = _capturedFile?.path;
    setState(() {
      _capturedFile = null;
    });
    _deleteTempFileIfOwned(oldPath);
  }

  void _confirmPicture() {
    if (_capturedFile != null) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
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
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        Navigator.pop(context, File(file.path));
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Kamera Tidak Tersedia',
          message: 'Gagal membuka kamera perangkat: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKtp = widget.mode == KycCameraMode.ktp;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildShutterButton(Color primaryColor, bool isKtp, {double size = 82}) {
    return GestureDetector(
      onTap: _isTakingPicture ? null : _takePicture,
      child: Container(
        width: size,
        height: size,
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
                    width: size * 0.35,
                    height: size * 0.35,
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : Icon(
                  isKtp ? Icons.camera_alt_rounded : Icons.face_rounded,
                  color: primaryColor,
                  size: size * 0.42,
                ),
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
        final isLandscape = size.width > size.height;

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

            // C. Top Controls Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 12),
              left: 16,
              right: isLandscape ? 100 : 16,
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
                      onPressed: () {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                        ]);
                        Navigator.pop(context);
                      },
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

            // D. Hint / Instructions
            if (isLandscape)
              Positioned(
                bottom: 12,
                left: 16,
                right: 100,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      isKtp
                          ? 'Posisikan e-KTP di dalam kotak • NIK, nama & foto terlihat jelas'
                          : 'Posisikan wajah di dalam lingkaran',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
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

            // E. Shutter Controls: Samping Kanan saat Landscape (ergonomis jempol), Bawah saat Portrait
            if (isLandscape)
              Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShutterButton(primaryColor, isKtp, size: 74),
                      const SizedBox(height: 8),
                      Text(
                        isKtp ? 'Foto e-KTP' : 'Foto Selfie',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShutterButton(primaryColor, isKtp, size: 82),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.biggest.width > constraints.biggest.height;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Display Captured Image
            Center(
              child: Image.file(
                File(_capturedFile!.path),
                key: ValueKey(_capturedFile!.path),
                fit: BoxFit.contain,
              ),
            ),

            // Semi-transparent top bar
            Positioned(
              top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 16),
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: isLandscape ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: primaryColor,
                      size: isLandscape ? 20 : 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isKtp ? 'Periksa Foto e-KTP' : 'Periksa Foto Selfie',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 13 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isLandscape) ...[
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
                        ],
                      ),
                    ),
                    if (isKtp) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _isRotatingPreview ? null : _rotatePreviewImage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isRotatingPreview
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 17),
                                const SizedBox(width: 5),
                                const Text(
                                  'Putar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _isFlippingPreview ? null : _flipPreviewImage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isFlippingPreview
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.flip_rounded, color: Colors.white, size: 17),
                                const SizedBox(width: 5),
                                const Text(
                                  'Balik',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Bar: Retake vs Confirm
            Positioned(
              bottom: isLandscape ? 10 : 20,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(isLandscape ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Retake Button
                    Expanded(
                      flex: 9,
                      child: SizedBox(
                        height: isLandscape ? 40 : 48,
                        child: OutlinedButton(
                          onPressed: _isFlippingPreview ? null : _retakePicture,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.10),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Foto Ulang',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Confirm Button
                    Expanded(
                      flex: 12,
                      child: SizedBox(
                        height: isLandscape ? 40 : 48,
                        child: ElevatedButton(
                          onPressed: _isFlippingPreview ? null : _confirmPicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Gunakan Foto Ini',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ],
                            ),
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
      },
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
      final double cardWidth;
      final double cardHeight;
      final double left;
      final double top;

      if (size.width > size.height) {
        // Landscape Mode:
        // Layar horizontal HP (misal 780x360 atau 840x390).
        // Berikan ruang untuk tombol rana/shutter di kanan (~100px).
        final availableWidth = size.width - 100;
        final maxHeight = size.height * 0.74;

        if (maxHeight * 1.585 <= availableWidth * 0.90) {
          cardHeight = maxHeight;
          cardWidth = cardHeight * 1.585;
        } else {
          cardWidth = availableWidth * 0.90;
          cardHeight = cardWidth / 1.585;
        }
        left = (availableWidth - cardWidth) / 2 + 8;
        top = (size.height - cardHeight) / 2;
      } else {
        // Portrait Mode (fallback)
        cardWidth = size.width * 0.88;
        cardHeight = cardWidth / 1.585;
        left = (size.width - cardWidth) / 2;
        top = (size.height - cardHeight) / 2 - 20; // Sedikit ke atas agar seimbang dengan kontrol
      }
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