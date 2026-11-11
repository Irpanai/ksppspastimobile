import 'package:digital_coop/core/services/app_launch_service.dart';
import 'package:digital_coop/core/widgets/in_app_update_dialog.dart';
import 'package:digital_coop/features/notification/models/notification_model.dart';
import 'package:digital_coop/features/notification/providers/notification_provider.dart';
import 'package:digital_coop/features/notification/services/notification_service.dart';
import 'package:digital_coop/features/profile/screens/data_consent_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationService extends NotificationService {
  bool shouldFailDelete = false;
  final List<NotificationModel> _serverItems;

  _FakeNotificationService(List<NotificationModel> initialItems)
      : _serverItems = List.of(initialItems);

  @override
  Future<NotificationListResponse> getNotifications({String? filter}) async {
    final unread = _serverItems.where((n) => !n.isRead).length;
    return NotificationListResponse(
      unreadCount: unread,
      notifications: List.of(_serverItems),
    );
  }

  @override
  Future<int> deleteNotification(int id) async {
    if (shouldFailDelete) {
      throw Exception('Simulasi gagal menghapus di server');
    }
    _serverItems.removeWhere((n) => n.id == id);
    return _serverItems.where((n) => !n.isRead).length;
  }
}

void main() {
  testWidgets(
    'InAppUpdateDialog keeps Nanti Saja inside Dialog card on compact phone screen without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool dismissed = false;
      final updateInfo = AppUpdateInfo(
        latestVersion: '1.0.9',
        latestBuildNumber: 10,
        currentVersion: '1.0.8',
        currentBuildNumber: 9,
        forceUpdate: false,
        title: 'Pembaruan Tersedia',
        message:
            'Versi 1.0.9 KSPPS PASTI telah tersedia dengan tampilan QRIS langsung di halaman pembayaran tanpa redirect, ukuran QR yang lebih proporsional, serta jadwal tayang & format tanggal Info & Promo yang lebih rapi.',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.ksppspasti.mobile',
        releaseNotes: [
          'Pembayaran QRIS tampil langsung di aplikasi sejak awal tanpa halaman tunggu/redirect',
          'Tampilan kode QR dalam bingkai yang lebih proporsional dan mudah dipindai',
          'Penjadwalan tanggal mulai & berakhir Info & Promo dengan format tanggal Indonesia (11 Nov 2026)',
          'Peningkatan stabilitas tampilan Info & Promo serta transaksi pembayaran mobile',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.25),
            ),
            child: Scaffold(
              body: InAppUpdateDialog(
                updateInfo: updateInfo,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final dialogRect = tester.getRect(find.byType(Dialog));
      final updateButtonRect = tester.getRect(find.text('Perbarui di Google Play'));
      final laterTextFinder = find.text('Nanti Saja');
      expect(laterTextFinder, findsOneWidget);

      final laterRect = tester.getRect(laterTextFinder);
      expect(updateButtonRect.bottom, lessThanOrEqualTo(dialogRect.bottom));
      expect(laterRect.top, greaterThanOrEqualTo(dialogRect.top));
      expect(laterRect.bottom, lessThanOrEqualTo(dialogRect.bottom));
      expect(laterRect.left, greaterThanOrEqualTo(dialogRect.left));
      expect(laterRect.right, lessThanOrEqualTo(dialogRect.right));

      await tester.tap(laterTextFinder);
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    },
  );

  testWidgets(
    'DataConsentScreen displays concise Kebijakan Data header without ellipsis truncation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DataConsentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Kebijakan Data');
      expect(titleFinder, findsOneWidget);
      expect(find.text('Kebijakan & Persetujuan Data'), findsNothing);

      final paragraph = tester.renderObject<RenderParagraph>(titleFinder);
      expect(paragraph.didExceedMaxLines, isFalse);
    },
  );

  test('AppLaunchService reads native shouldSkipSplash channel on Android and fails safe', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.ksppspasti.mobile/app_lifecycle');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await AppLaunchService.shouldSkipSplash(), isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'shouldSkipSplash') return true;
      return false;
    });
    expect(await AppLaunchService.shouldSkipSplash(), isTrue);

    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ERR', message: 'unavailable');
    });
    expect(await AppLaunchService.shouldSkipSplash(), isFalse);
  });

  test('NotificationProvider deleteNotification rolls back on error and removes cleanly on success', () async {
    final unreadNotif = NotificationModel(
      id: 101,
      title: 'Pembayaran Menunggu',
      message: 'Silakan selesaikan pembayaran',
      type: 'payment',
      isRead: false,
      timeAgo: 'Baru saja',
    );
    final readNotif = NotificationModel(
      id: 102,
      title: 'Selamat Datang',
      message: 'Akun aktif',
      type: 'account',
      isRead: true,
      timeAgo: '1 hari lalu',
    );

    final fakeService = _FakeNotificationService([unreadNotif, readNotif]);
    final provider = NotificationProvider(service: fakeService);

    await provider.fetchNotifications(refresh: true);
    expect(provider.notifications.map((n) => n.id).toList(), [101, 102]);
    expect(provider.unreadCount, 1);

    // Gagal di server -> item harus kembali ke posisi semula & unreadCount pulih
    fakeService.shouldFailDelete = true;
    final failedResult = await provider.deleteNotification(unreadNotif);
    expect(failedResult, isFalse);
    expect(provider.notifications.map((n) => n.id).toList(), [101, 102]);
    expect(provider.unreadCount, 1);

    // Berhasil di server -> terhapus permanen dan refresh tetap bersih
    fakeService.shouldFailDelete = false;
    final okResult = await provider.deleteNotification(unreadNotif);
    expect(okResult, isTrue);
    expect(provider.notifications.map((n) => n.id).toList(), [102]);
    expect(provider.unreadCount, 0);

    await provider.fetchNotifications(refresh: true);
    expect(provider.notifications.map((n) => n.id).toList(), [102]);
  });
}

