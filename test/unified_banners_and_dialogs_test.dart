import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_coop/features/payment/widgets/payment_preparation_dialog.dart';
import 'package:digital_coop/shared/widgets/app_dialog.dart';
import 'package:digital_coop/shared/widgets/dashboard_alert_banner.dart';
import 'package:digital_coop/features/home/widgets/wajib_simpanan_modal_dialog.dart';

void main() {
  testWidgets(
    'DashboardAlertBanner Lihat and Bayar cards share identical icon circle and sturdy CTA button dimensions',
    (tester) async {
      bool tappedPending = false;
      bool tappedTunggakan = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DashboardAlertBanner.amber(
                  key: const Key('banner_pending'),
                  title: 'Menunggu Pembayaran',
                  subtitle: 'QRIS Nasional • Rp 100.000',
                  actionLabel: 'Lihat',
                  icon: Icons.timer_outlined,
                  onActionTap: () => tappedPending = true,
                ),
                DashboardAlertBanner.amber(
                  key: const Key('banner_tunggakan'),
                  title: 'Perhatian: Status Menunggak',
                  subtitle: 'Ada 1 bulan Simpanan Wajib belum dibayar.',
                  actionLabel: 'Bayar',
                  icon: Icons.warning_amber_rounded,
                  onActionTap: () => tappedTunggakan = true,
                ),
                DashboardAlertBanner.emerald(
                  key: const Key('banner_pokok'),
                  title: 'Kewajiban: Simpanan Pokok',
                  subtitle: 'Anda diwajibkan membayar Simpanan Pokok awal.',
                  actionLabel: 'Bayar',
                  icon: Icons.priority_high_rounded,
                  onActionTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final pendingSize = tester.getSize(find.byKey(const Key('banner_pending')));
      final tunggakanSize = tester.getSize(find.byKey(const Key('banner_tunggakan')));
      final pokokSize = tester.getSize(find.byKey(const Key('banner_pokok')));

      expect(pendingSize.width, tunggakanSize.width);
      expect(pendingSize.height, tunggakanSize.height);
      expect(tunggakanSize.height, pokokSize.height);

      final lihatSize = tester.getSize(find.text('Lihat'));
      final bayarBtnFinder = find.text('Bayar').first;
      expect(tester.getSize(bayarBtnFinder).height, lihatSize.height);

      final pendingInk = tester.widget<Ink>(
        find.descendant(of: find.byKey(const Key('banner_pending')), matching: find.byType(Ink)),
      );
      final tunggakanInk = tester.widget<Ink>(
        find.descendant(of: find.byKey(const Key('banner_tunggakan')), matching: find.byType(Ink)),
      );
      expect(
        (pendingInk.decoration as BoxDecoration).borderRadius,
        (tunggakanInk.decoration as BoxDecoration).borderRadius,
      );

      final buttonConstrainedBoxes = find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.minWidth == 64 &&
            w.constraints.minHeight == 34,
      );
      expect(buttonConstrainedBoxes, findsNWidgets(3));
      for (final elem in buttonConstrainedBoxes.evaluate()) {
        expect(elem.size!.height, greaterThanOrEqualTo(34));
        expect(elem.size!.width, greaterThanOrEqualTo(64));
      }

      await tester.tap(find.text('Lihat'));
      await tester.tap(find.text('Bayar').first);
      expect(tappedPending, isTrue);
      expect(tappedTunggakan, isTrue);
    },
  );

  testWidgets('AppDialog error, warning, info, success, custom, and floating toast render cleanly without overflow', (tester) async {
    bool confirmedSuccess = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppDialog.showError(
                    context,
                    title: 'Terjadi Kesalahan',
                    message: 'Koneksi bermasalah saat menghubungi server.',
                  ),
                  child: const Text('Show Error'),
                ),
                ElevatedButton(
                  onPressed: () => AppDialog.showInfo(
                    context,
                    title: 'Informasi Penting',
                    message: 'Simpanan Pokok sudah lunas.',
                    customContent: const Text('Detail Tambahan'),
                  ),
                  child: const Text('Show Info'),
                ),
                ElevatedButton(
                  onPressed: () => AppDialog.showSuccess(
                    context,
                    title: 'Berhasil',
                    message: 'Data disimpan.',
                    secondaryButtonText: 'Riwayat',
                    onSecondaryPressed: () {},
                    onConfirm: () => confirmedSuccess = true,
                  ),
                  child: const Text('Show Success'),
                ),
                ElevatedButton(
                  onPressed: () => AppDialog.showCustom(
                    context,
                    icon: Icons.access_time_filled_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconBorderColor: const Color(0xFFFDE68A),
                    title: 'Menunggu Pembayaran',
                    message: 'Selesaikan pembayaran Anda.',
                    primaryButtonText: 'Tutup',
                    primaryButtonColor: const Color(0xFFD97706),
                    onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                  child: const Text('Show Custom'),
                ),
                ElevatedButton(
                  onPressed: () => AppDialog.showFloatingToast(
                    context,
                    message: 'Nomor VA berhasil disalin',
                  ),
                  child: const Text('Show Toast'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error'));
    await tester.pumpAndSettle();
    expect(find.text('Terjadi Kesalahan'), findsOneWidget);
    expect(find.text('Mengerti'), findsOneWidget);
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    expect(find.text('Terjadi Kesalahan'), findsNothing);

    await tester.tap(find.text('Show Info'));
    await tester.pumpAndSettle();
    expect(find.text('Informasi Penting'), findsOneWidget);
    expect(find.text('Detail Tambahan'), findsOneWidget);
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Success'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(confirmedSuccess, isTrue);

    await tester.tap(find.text('Show Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu Pembayaran'), findsNothing);

    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    expect(find.text('Nomor VA berhasil disalin'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('WajibSimpananModalDialog matches unified 26px radius modal shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WajibSimpananModalDialog.show(context),
              child: const Text('Open Wajib Modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Wajib Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Aktivasi Keanggotaan'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final shape = dialog.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(26));
  });

  testWidgets('AppDialog.showShell wraps content inside solid white 26px card shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppDialog.showShell(
                context: context,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Menyiapkan Pembayaran...'),
                ),
              ),
              child: const Text('Open Shell'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Shell'));
    await tester.pumpAndSettle();

    expect(find.text('Menyiapkan Pembayaran...'), findsOneWidget);

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Menyiapkan Pembayaran...'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.borderRadius, BorderRadius.circular(26));
  });

  testWidgets('PaymentPreparationHelper.run renders unified PaymentPreparationCard inside 26px white shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                PaymentPreparationHelper.run<void>(
                  context: context,
                  accentColor: const Color(0xFF00A39D),
                  task: () => Future<void>.delayed(const Duration(milliseconds: 50)),
                );
              },
              child: const Text('Start Prep'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start Prep'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(PaymentPreparationCard), findsOneWidget);
    expect(find.text('Menyiapkan Pembayaran...'), findsOneWidget);
    expect(find.text('Menghubungkan ke server pembayaran...'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentPreparationCard), findsNothing);
  });
}
