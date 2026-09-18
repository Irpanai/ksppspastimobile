import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/providers/dashboard_provider.dart';
import 'features/main_nav/screens/main_nav_screen.dart';
import 'features/savings/providers/savings_provider.dart';
import 'features/sijaka/providers/sijaka_provider.dart';

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
      title: 'KSPP PASTI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: darkGreen,
          surface: const Color(0xFFF8FAFC),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
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
