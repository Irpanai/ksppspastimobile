import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'features/main_nav/screens/main_nav_screen.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
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
  const DigitalCoopApp({Key? key}) : super(key: key);

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
          background: const Color(0xFFF8FAFC), // Light clean background
        ),
        fontFamily: 'Roboto', 
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
