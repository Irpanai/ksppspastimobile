import 'dart:io';
import 'dart:ui' as ui;

import 'package:digital_coop/features/auth/screens/kyc_camera_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _createValidTestPngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 10, 10),
    Paint()..color = const Color(0xFF0E7955),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(10, 10);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KycImageNormalizationService', () {
    const channel = MethodChannel('com.ksppspasti.mobile/kyc_image');

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('passes cropToKtpLandscape and rotateDegrees flags for KTP landscape normalization',
        () async {
      final calls = <MethodCall>[];
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return '/tmp/KYC_NORM_ktp_landscape.jpg';
      });

      final ktpResult = await KycImageNormalizationService.normalizeCapturedPhoto(
        path: '/tmp/raw_ktp.jpg',
        mirrorHorizontal: false,
        cropToKtpLandscape: true,
      );
      expect(ktpResult, '/tmp/KYC_NORM_ktp_landscape.jpg');
      expect(calls.single.method, 'normalizeCapturedPhoto');
      expect(calls.single.arguments, <String, dynamic>{
        'path': '/tmp/raw_ktp.jpg',
        'mirrorHorizontal': false,
        'cropToKtpLandscape': true,
      });

      calls.clear();
      final rotateResult = await KycImageNormalizationService.normalizeCapturedPhoto(
        path: '/tmp/raw_ktp.jpg',
        mirrorHorizontal: false,
        rotateDegrees: 90,
      );
      expect(rotateResult, '/tmp/KYC_NORM_ktp_landscape.jpg');
      expect(calls.single.arguments, <String, dynamic>{
        'path': '/tmp/raw_ktp.jpg',
        'mirrorHorizontal': false,
        'rotateDegrees': 90,
      });
    });
  });

  group('KycCameraScreen preview & Foto Ulang layout', () {
    late Directory tempDir;
    late File originalFile;
    late File flippedFile;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('kyc_preview_test_');
      final pngBytes = await _createValidTestPngBytes();
      originalFile = File('${tempDir.path}/selfie_orig.png')..writeAsBytesSync(pngBytes);
      flippedFile = File('${tempDir.path}/selfie_flip.png')..writeAsBytesSync(pngBytes);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'), null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
        'Selfie preview renders equal-height single-line Foto Ulang & Gunakan Foto Ini buttons and supports Balik flip on 360px',
        variant: TargetPlatformVariant.only(TargetPlatform.android),
        (tester) async {
      final channelCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'),
              (call) async {
        channelCalls.add(call);
        return flippedFile.path;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'), null));

      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.15),
              ),
              child: KycCameraScreen(
                mode: KycCameraMode.selfie,
                initialCapturedFile: originalFile,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Periksa Foto Selfie'), findsOneWidget);
      expect(find.text('Balik'), findsOneWidget);

      final retakeFinder = find.text('Foto Ulang');
      final confirmFinder = find.text('Gunakan Foto Ini');
      expect(retakeFinder, findsOneWidget);
      expect(confirmFinder, findsOneWidget);

      final retakeButtonBox = tester.getSize(find.byType(OutlinedButton));
      final confirmButtonBox = tester.getSize(find.byType(ElevatedButton));
      expect(retakeButtonBox.height, closeTo(48.0, 0.5));
      expect(confirmButtonBox.height, closeTo(48.0, 0.5));

      final retakeText = tester.renderObject(retakeFinder);
      final confirmText = tester.renderObject(confirmFinder);
      expect(retakeText.paintBounds.height, lessThan(30));
      expect(confirmText.paintBounds.height, lessThan(30));

      expect(find.byKey(ValueKey(originalFile.path)), findsOneWidget);

      await tester.tap(find.text('Balik'));
      await tester.pumpAndSettle();

      expect(channelCalls, hasLength(1));
      expect(channelCalls.single.arguments['mirrorHorizontal'], isTrue);
      expect(find.byKey(ValueKey(flippedFile.path)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KTP preview renders Putar 90 button, omits Balik toggle, and avoids overflow on 360px', (tester) async {
      final channelCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'),
              (call) async {
        channelCalls.add(call);
        return flippedFile.path;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'), null));

      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: KycCameraScreen(
            mode: KycCameraMode.ktp,
            initialCapturedFile: originalFile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Periksa Foto e-KTP'), findsOneWidget);
      expect(find.text('Putar'), findsOneWidget);
      expect(find.text('Balik'), findsNothing);
      expect(find.text('Foto Ulang'), findsOneWidget);
      expect(find.text('Gunakan Foto Ini'), findsOneWidget);

      await tester.tap(find.text('Putar'));
      await tester.pumpAndSettle();

      expect(channelCalls, hasLength(1));
      expect(channelCalls.single.arguments['rotateDegrees'], 90);
      expect(find.byKey(ValueKey(flippedFile.path)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KTP preview in landscape orientation (780x360) renders compactly without overflow', (tester) async {
      final channelCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'),
              (call) async {
        channelCalls.add(call);
        return flippedFile.path;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.ksppspasti.mobile/kyc_image'), null));

      tester.view.physicalSize = const Size(780, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: KycCameraScreen(
            mode: KycCameraMode.ktp,
            initialCapturedFile: originalFile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Periksa Foto e-KTP'), findsOneWidget);
      expect(find.text('Putar'), findsOneWidget);
      expect(find.text('Foto Ulang'), findsOneWidget);
      expect(find.text('Gunakan Foto Ini'), findsOneWidget);

      final retakeBox = tester.getSize(find.byType(OutlinedButton));
      final confirmBox = tester.getSize(find.byType(ElevatedButton));
      expect(retakeBox.height, closeTo(40.0, 0.5));
      expect(confirmBox.height, closeTo(40.0, 0.5));

      await tester.tap(find.text('Putar'));
      await tester.pumpAndSettle();

      expect(channelCalls, hasLength(1));
      expect(channelCalls.single.arguments['rotateDegrees'], 90);
      expect(tester.takeException(), isNull);
    });
  });
}
