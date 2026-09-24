import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:digital_coop/main.dart';
import 'package:digital_coop/features/auth/providers/auth_provider.dart';
import 'package:digital_coop/features/history/providers/history_provider.dart';
import 'package:digital_coop/features/home/providers/dashboard_provider.dart';
import 'package:digital_coop/features/savings/providers/savings_provider.dart';
import 'package:digital_coop/features/sijaka/providers/sijaka_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final dashboardProvider = DashboardProvider();
    final savingsProvider = SavingsProvider();
    final sijakaProvider = SijakaProvider();
    final historyProvider = HistoryProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
          ChangeNotifierProvider<SavingsProvider>.value(value: savingsProvider),
          ChangeNotifierProvider<SijakaProvider>.value(value: sijakaProvider),
          ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
        ],
        child: const DigitalCoopApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(DigitalCoopApp), findsOneWidget);
  });
}
