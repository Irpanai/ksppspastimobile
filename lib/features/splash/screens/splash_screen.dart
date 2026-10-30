import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../main.dart';
import '../services/splash_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  SplashConfig? _activeConfig;
  File? _imageFile;
  bool _isInitialized = false;
  bool _isImageSplash = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pra-muat logo ke memori GPU selagi splash berputar agar langsung muncul instan di layar login
    precacheImage(const AssetImage('assets/images/logo-kspps-pasti.png'), context);
  }

  Future<void> _initSplash() async {
    // 1. Cek apakah ada splash kustom aktif di penyimpanan lokal (Cache HP)
    _activeConfig = await SplashService.getActiveLocalConfig();

    // 2. Sinkronkan pembaruan splash terbaru dari CMS Admin di latar belakang
    unawaited(SplashService.syncSplashWithServer());

    if (!mounted) return;

    // 3. Muat media splash (Gambar atau Video)
    if (_activeConfig != null && _activeConfig!.mediaType == 'image' && _activeConfig!.filePath != null) {
      _initImageSplash(_activeConfig!);
    } else {
      await _initVideoSplash(_activeConfig);
    }
  }

  void _initImageSplash(SplashConfig config) {
    setState(() {
      _isImageSplash = true;
      _imageFile = File(config.filePath!);
      _isInitialized = true;
    });

    // Timer durasi untuk splash gambar
    final duration = Duration(seconds: config.durationSeconds > 0 ? config.durationSeconds : 4);
    _fallbackTimer = Timer(duration, _navigateToNextScreen);
  }

  Future<void> _initVideoSplash(SplashConfig? config) async {
    try {
      if (config != null && config.filePath != null && await File(config.filePath!).exists()) {
        // Putar video dari cache lokal yang diunduh dari CMS Admin
        _controller = VideoPlayerController.file(File(config.filePath!));
      } else {
        // Fallback ke video aset bawaan aplikasi
        _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
      }

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _isImageSplash = false;
      });

      _controller!.setLooping(false);

      if (kIsWeb) {
        await _controller!.setVolume(0.0);
      } else {
        await _controller!.setVolume(1.0);
      }

      await _controller!.play();

      _controller!.addListener(_videoListener);

      // Fallback timer jika video gagal memicu durasi selesai
      final duration = _controller!.value.duration;
      final safetyTimeout = duration > Duration.zero
          ? duration + const Duration(milliseconds: 600)
          : Duration(seconds: config?.durationSeconds ?? 5);

      _fallbackTimer = Timer(safetyTimeout, _navigateToNextScreen);
    } catch (e, stack) {
      debugPrint('Error playing splash video: $e\n$stack');
      _fallbackTimer = Timer(const Duration(seconds: 2), _navigateToNextScreen);
    }
  }

  void _videoListener() {
    if (!mounted || _hasNavigated || _controller == null) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration > Duration.zero && position >= duration) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _activeConfig?.backgroundColor ?? const Color(0xFF1B5E20);
    final isSkippable = _activeConfig?.isSkippable ?? true;
    final fitMode = _activeConfig?.fitMode ?? 'cover';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Konten Media Splash
            if (_isInitialized)
              if (_isImageSplash && _imageFile != null)
                SizedBox.expand(
                  child: Image.file(
                    _imageFile!,
                    fit: fitMode == 'contain' ? BoxFit.contain : BoxFit.cover,
                  ),
                )
              else if (_controller != null && _controller!.value.isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: fitMode == 'contain' ? BoxFit.contain : BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              else
                const SizedBox.shrink()
            else
              const SizedBox.shrink(),

            // Tombol Lewati (Skip) di pojok kanan atas
            if (isSkippable)
              Positioned(
                top: 48,
                right: 20,
                child: SafeArea(
                  child: TextButton(
                    onPressed: _navigateToNextScreen,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}