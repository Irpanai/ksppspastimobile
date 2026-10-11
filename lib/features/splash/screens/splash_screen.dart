import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pra-muat logo ke memori GPU selagi video berputar agar langsung muncul instan tanpa loading di layar login
    precacheImage(const AssetImage('assets/images/logo-kspps-pasti.png'), context);
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _controller.setLooping(false);

      // Pada browser / Web, autoplay dengan suara diblokir browser, sehingga di-mute
      if (kIsWeb) {
        await _controller.setVolume(0.0);
      } else {
        await _controller.setVolume(1.0);
      }

      await _controller.play();

      // Listener untuk memantau kapan video selesai berputar
      _controller.addListener(_videoListener);

      // Fallback timer jika video gagal memicu durasi selesai
      final duration = _controller.value.duration;
      final safetyTimeout = duration > Duration.zero 
          ? duration + const Duration(milliseconds: 600)
          : const Duration(seconds: 5);

      _fallbackTimer = Timer(safetyTimeout, _navigateToNextScreen);
    } catch (e, stack) {
      debugPrint('Error playing splash video: $e');
      debugPrint('$stack');
      // Jika terjadi error saat memuat video, langsung lanjut setelah 2 detik
      _fallbackTimer = Timer(const Duration(seconds: 2), _navigateToNextScreen);
    }
  }

  void _videoListener() {
    if (!mounted || _hasNavigated) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (duration > Duration.zero && position >= duration) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    _controller.removeListener(_videoListener);

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
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1B5E20),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1B5E20), // Background hijau tua identik tema aplikasi
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            // Tombol Lewati (Skip) di pojok kanan atas
            Positioned(
              top: 48,
              right: 20,
              child: SafeArea(
                child: TextButton(
                  onPressed: _navigateToNextScreen,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.25),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
