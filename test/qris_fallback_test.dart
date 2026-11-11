import 'dart:convert';
import 'dart:typed_data';
import 'package:digital_coop/features/payment/models/payment_model.dart';
import 'package:digital_coop/features/payment/providers/payment_provider.dart';
import 'package:digital_coop/features/payment/screens/native_qris_screen.dart';
import 'package:digital_coop/features/payment/widgets/doku_qris_web_bridge.dart';
import 'package:digital_coop/features/payment/widgets/qris_preparation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePaymentProvider extends PaymentProvider {
  PaymentStatusResponse? stubbedStatus;
  String? stubbedError;

  @override
  String? get errorMessage => stubbedError;

  @override
  Future<PaymentStatusResponse?> checkStatus(String orderId) async {
    return stubbedStatus;
  }

  @override
  Future<void> updatePendingPayment(SnapTokenResponse updated) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DokuQrPayloadParser', () {
    test('extracts valid EMVCo QRIS string from raw and JSON-escaped payloads', () {
      const sampleQr =
          '00020101021226670016COM.NOBUBANK.WWW01189360050300000879140214510111919000010303UMI51440014ID.CO.QRIS.WWW0215ID20261020568530303UMI52045499530336054061011105802ID5912KSPPS PASTI6009BANJARBAR61057071462070703A016304A1B2';
      final escapedJson = '{"qr_string":"${sampleQr.replaceAll('/', r'\/')}"}';

      expect(DokuQrPayloadParser.extractEmvQrString(sampleQr), equals(sampleQr));
      expect(DokuQrPayloadParser.extractEmvQrString(escapedJson), equals(sampleQr));
      expect(DokuQrPayloadParser.extractEmvQrString('invalid qr'), isNull);
    });

    test('decodes base64 PNG data URI and rejects tiny placeholders', () {
      final dummyBytes = Uint8List.fromList(List<int>.generate(120, (i) => i % 256));
      final dataUri = 'data:image/png;base64,${base64Encode(dummyBytes)}';

      final parsed = DokuQrPayloadParser.parseBridgeMessage(
        jsonEncode({'type': 'image', 'value': dataUri}),
      );
      expect(parsed, isNotNull);
      expect(parsed!.hasImageBytes, isTrue);
      expect(parsed.imageBytes, equals(dummyBytes));

      expect(DokuQrPayloadParser.decodeDataImageBytes('data:image/png;base64,AA=='), isNull);
    });

    test('parses image_url and unicode-escaped EMV strings while rejecting unsafe URLs', () {
      const sampleQr =
          '00020101021226670016COM.NOBUBANK/WWW01189360050300000879140214510111919000010303UMI51440014ID.CO.QRIS.WWW0215ID20261020568530303UMI52045499530336054061011105802ID5912KSPPS PASTI6009BANJARBAR61057071462070703A016304A1B2';
      final unicodeEscapedMsg = '{"type":"emv","value":"${sampleQr.replaceAll('/', r'\u002F')}"}';
      final parsedEmv = DokuQrPayloadParser.parseBridgeMessage(unicodeEscapedMsg);
      expect(parsedEmv, isNotNull);
      expect(parsedEmv!.hasQrString, isTrue);
      expect(parsedEmv.qrString, equals(sampleQr));

      final parsedImgUrl = DokuQrPayloadParser.parseBridgeMessage(
        jsonEncode({'type': 'image_url', 'value': 'https://checkout.doku.com/qris/qr-code.png'}),
      );
      expect(parsedImgUrl, isNotNull);
      expect(parsedImgUrl!.hasImageUrl, isTrue);
      expect(parsedImgUrl.imageUrl, equals('https://checkout.doku.com/qris/qr-code.png'));

      expect(
        DokuQrPayloadParser.parseBridgeMessage(
          jsonEncode({'type': 'image_url', 'value': 'javascript:alert(1)'}),
        ),
        isNull,
      );
    });

    test('detects DOKU finish URLs accurately', () {
      expect(
        DokuQrPayloadParser.isDokuFinishUrl('https://checkout.doku.com/finish?status=success'),
        isTrue,
      );
      expect(
        DokuQrPayloadParser.isDokuFinishUrl('https://checkout.doku.com/checkout-link-v2/abc'),
        isFalse,
      );
    });
  });

  group('NativeQrisScreen fallback behavior', () {
    testWidgets('renders native QrImageView when qrString is present', (tester) async {
      final provider = _FakePaymentProvider();
      const validQr =
          '00020101021226670016COM.NOBUBANK.WWW01189360050300000879140214510111919000010303UMI51440014ID.CO.QRIS.WWW0215ID20261020568530303UMI52045499530336054061011105802ID5912KSPPS PASTI6009BANJARBAR61057071462070703A016304A1B2';

      final response = SnapTokenResponse(
        orderId: 'QRIS-OK-001',
        snapToken: 'tok-ok',
        snapRedirectUrl: 'https://checkout.doku.com/checkout-link-v2/ok',
        nominal: 100000,
        nominalFormat: 'Rp 100.000',
        type: 'qris',
        status: 'pending',
        qrString: validQr,
        nmid: 'ID2026102056853',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: MaterialApp(
            home: NativeQrisScreen(paymentResponse: response),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Download QR'), findsOneWidget);
      expect(find.text('Salin Kode'), findsOneWidget);
      expect(find.text('QR Code belum tersedia langsung'), findsNothing);
    });

    testWidgets(
      'never displays broken "QR Code belum tersedia langsung" dead-end when snapRedirectUrl exists',
      (tester) async {
        final provider = _FakePaymentProvider();

        final response = SnapTokenResponse(
          orderId: 'QRIS-URL-ONLY-002',
          snapToken: 'tok-url',
          snapRedirectUrl: 'https://checkout.doku.com/checkout-link-v2/xyz',
          nominal: 100000,
          nominalFormat: 'Rp 100.000',
          type: 'qris',
          status: 'pending',
          qrString: null,
          nmid: 'ID2026102056853',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<PaymentProvider>.value(
            value: provider,
            child: MaterialApp(
              home: NativeQrisScreen(paymentResponse: response),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('QR Code belum tersedia langsung'), findsNothing);
        expect(find.text('Buka Halaman Bayar'), findsNothing);
        expect(find.text('Layar Penuh'), findsNothing);
        expect(find.text('Menyiapkan Kode QRIS'), findsOneWidget);
        expect(find.text('Muat Ulang QR'), findsOneWidget);
      },
    );

    testWidgets('shows generation error state cleanly when onGeneratePayment fails', (tester) async {
      final provider = _FakePaymentProvider()..stubbedError = 'Koneksi timeout ke server.';

      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: MaterialApp(
            home: NativeQrisScreen(
              onGeneratePayment: () async => null,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Koneksi timeout ke server.'), findsOneWidget);
      expect(find.text('Coba Generate Ulang'), findsOneWidget);
    });

    testWidgets('renders initialQrBytes immediately without skeleton wait', (tester) async {
      final provider = _FakePaymentProvider();
      final validPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );

      final response = SnapTokenResponse(
        orderId: 'QRIS-PRELOADED-003',
        snapToken: 'tok-pre',
        snapRedirectUrl: 'https://checkout.doku.com/checkout-link-v2/pre',
        nominal: 50000,
        nominalFormat: 'Rp 50.000',
        type: 'qris',
        status: 'pending',
        qrString: null,
        nmid: 'ID2026102056853',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: MaterialApp(
            home: NativeQrisScreen(
              paymentResponse: response,
              initialQrBytes: validPng,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Menyiapkan Kode QRIS'), findsNothing);
      expect(find.text('Download QR'), findsOneWidget);
    });
  });

  group('QrisPreparationHelper preload flow', () {
    testWidgets('shows preparation dialog and navigates to NativeQrisScreen once ready', (tester) async {
      final provider = _FakePaymentProvider();
      const validQr =
          '00020101021226670016COM.NOBUBANK.WWW01189360050300000879140214510111919000010303UMI51440014ID.CO.QRIS.WWW0215ID20261020568530303UMI52045499530336054061011105802ID5912KSPPS PASTI6009BANJARBAR61057071462070703A016304A1B2';

      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      QrisPreparationHelper.open(
                        context,
                        onGeneratePayment: () async {
                          await Future<void>.delayed(const Duration(milliseconds: 50));
                          return SnapTokenResponse(
                            orderId: 'QRIS-PRE-004',
                            snapToken: 'tok-pre-4',
                            snapRedirectUrl: 'https://checkout.doku.com/checkout-link-v2/pre4',
                            nominal: 100000,
                            nominalFormat: 'Rp 100.000',
                            type: 'qris',
                            status: 'pending',
                            qrString: validQr,
                            nmid: 'ID2026102056853',
                          );
                        },
                      );
                    },
                    child: const Text('Bayar QRIS'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Bayar QRIS'));
      await tester.pump();
      expect(find.text('Menyiapkan Kode QRIS...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Menyiapkan Kode QRIS...'), findsNothing);
      expect(find.text('Pembayaran QRIS'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('shows error modal cleanly if payment creation fails during preload', (tester) async {
      final provider = _FakePaymentProvider()..stubbedError = 'Server pembayaran sibuk.';

      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      QrisPreparationHelper.open(
                        context,
                        onGeneratePayment: () async => null,
                      );
                    },
                    child: const Text('Bayar QRIS'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Bayar QRIS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran QRIS Belum Siap'), findsOneWidget);
      expect(find.text('Server pembayaran sibuk.'), findsOneWidget);
    });
  });
}
