import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/history/providers/history_provider.dart';
import 'features/home/providers/dashboard_provider.dart';
import 'features/main_nav/screens/main_nav_screen.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/payment/providers/payment_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/promo/providers/promo_provider.dart';
import 'features/savings/providers/savings_provider.dart';
import 'features/sijaka/providers/sijaka_provider.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize date formatting locale
  await initializeDateFormatting('id_ID', null);
  // Initialize local preferences storage
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => SijakaProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PromoProvider()..fetchPromos()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..fetchNotifications()),
      ],
      child: const DigitalCoopApp(),
    ),
  );
}

// Simple State Management for the App
class AppState extends ChangeNotifier {
  bool _isBalanceVisible = true;
  bool get isBalanceVisible => _isBalanceVisible;

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }
}

class DigitalCoopApp extends StatelessWidget {
  const DigitalCoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Primary Colors - Matching KSPP SYARIAH PASTI Logo
    const Color primaryGreen = Color(0xFF388E3C); // Vibrant Green (from "KSPP SYARIAH")
    const Color darkGreen = Color(0xFF1B5E20);    // Deep Forest Green (from "PASTI")

    return MaterialApp(
      title: 'Si Hijau by INTIRA',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const ClampingScrollPhysics(),
        overscroll: false,
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: darkGreen,
          surface: const Color(0xFFF8FAFC),
        ),
        fontFamily: 'Roboto',
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          contentTextStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Decides whether to show LoginScreen or MainNavScreen based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.initial:
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF388E3C),
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const MainNavScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.authenticating:
        return const LoginScreen();
    }
  }
}
