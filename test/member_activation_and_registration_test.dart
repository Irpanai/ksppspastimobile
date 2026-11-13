import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_coop/features/auth/providers/auth_provider.dart';
import 'package:digital_coop/features/auth/screens/register_screen.dart';
import 'package:digital_coop/features/home/providers/dashboard_provider.dart';
import 'package:digital_coop/features/payment/models/payment_channel_model.dart';
import 'package:digital_coop/features/payment/providers/payment_provider.dart';
import 'package:digital_coop/features/payment/screens/native_payment_detail_screen.dart';
import 'package:digital_coop/features/payment/screens/top_up_screen.dart';
import 'package:digital_coop/features/payment/widgets/payment_preparation_dialog.dart';
import 'package:digital_coop/features/profile/models/pengunduran_diri_model.dart';
import 'package:digital_coop/features/profile/providers/profile_provider.dart';
import 'package:digital_coop/features/profile/screens/pengunduran_diri_screen.dart';
import 'package:digital_coop/core/services/location_address_service.dart';
import 'package:digital_coop/core/utils/ktp_ocr_helper.dart';
import 'package:digital_coop/features/home/models/dashboard_model.dart';
import 'package:digital_coop/features/home/widgets/tunggakan_modal_dialog.dart';
import 'package:digital_coop/features/home/widgets/wajib_simpanan_modal_dialog.dart';
import 'package:digital_coop/features/payment/models/payment_model.dart';
import 'package:digital_coop/shared/widgets/dashboard_alert_banner.dart';
import 'package:digital_coop/core/utils/member_activation_guard.dart';
import 'package:digital_coop/shared/widgets/app_dialog.dart';

void main() {
  group('MemberStatusResolver & status sync', () {
    test('requires BOTH Pokok and Wajib > 0 for AKTIF status', () {
      final neither = MemberStatusResolver.resolve(
        saldoPokok: 0,
        saldoWajib: 0,
        rawStatus: 'aktif',
      );
      expect(neither.isPokokPaid, isFalse);
      expect(neither.isWajibPaid, isFalse);
      expect(neither.isActive, isFalse);
      expect(neither.displayStatus, 'BELUM AKTIF');

      final pokokOnly = MemberStatusResolver.resolve(
        saldoPokok: 15000,
        saldoWajib: 0,
        rawStatus: 'aktif',
      );
      expect(pokokOnly.isPokokPaid, isTrue);
      expect(pokokOnly.isWajibPaid, isFalse);
      expect(pokokOnly.isActive, isFalse);
      expect(pokokOnly.displayStatus, 'BELUM AKTIF');

      final wajibOnly = MemberStatusResolver.resolve(
        saldoPokok: 0,
        saldoWajib: 2500,
        rawStatus: 'nonaktif',
      );
      expect(wajibOnly.isPokokPaid, isFalse);
      expect(wajibOnly.isWajibPaid, isTrue);
      expect(wajibOnly.isActive, isFalse);
      expect(wajibOnly.displayStatus, 'BELUM AKTIF');

      final bothPaid = MemberStatusResolver.resolve(
        saldoPokok: 15000,
        saldoWajib: 2500,
        rawStatus: 'aktif',
      );
      expect(bothPaid.isPokokPaid, isTrue);
      expect(bothPaid.isWajibPaid, isTrue);
      expect(bothPaid.isActive, isTrue);
      expect(bothPaid.displayStatus, 'AKTIF');

      final exited = MemberStatusResolver.resolve(
        saldoPokok: 15000,
        saldoWajib: 2500,
        rawStatus: 'keluar',
      );
      expect(exited.isActive, isFalse);
      expect(exited.displayStatus, 'KELUAR');
    });

    test('DashboardAnggota.fromJson respects belum_aktif flags cleanly', () {
      final anggota = DashboardAnggota.fromJson({
        'id': 10,
        'no_anggota': '1211260001',
        'nama': 'ZOYA NUJULA',
        'status': 'belum_aktif',
        'status_keanggotaan': 'belum_aktif',
        'is_pokok_paid': false,
        'is_wajib_paid': false,
        'is_member_active': false,
        'cabang': 'KC TELUK DALAM BJM',
        'is_menunggak': false,
      });

      expect(anggota.isPokokPaid, isFalse);
      expect(anggota.isWajibPaid, isFalse);
      expect(anggota.isMemberActive, isFalse);
      expect(anggota.statusKeanggotaan, 'belum_aktif');
    });

    test('SnapTokenResponse displayType formats simpanan_pokok_wajib', () {
      final snap = SnapTokenResponse.fromJson({
        'order_id': 'RegAwal-261112-AB12',
        'nominal': 17500,
        'admin_fee': 1110,
        'gross_amount': 18610,
        'type': 'simpanan_pokok_wajib',
        'status': 'pending',
      });

      expect(snap.displayType, 'Aktivasi (Pokok + Wajib)');
    });

    test('DashboardAnggota tracks registration date and prevents picking pre-registration or paid months', () {
      final anggotaNov = DashboardAnggota.fromJson({
        'id': 10,
        'no_anggota': '1211260001',
        'nama': 'ZOYA NUJULA',
        'status': 'aktif',
        'status_keanggotaan': 'aktif',
        'is_pokok_paid': true,
        'is_wajib_paid': true,
        'is_member_active': true,
        'cabang': 'KC TELUK DALAM BJM',
        'is_menunggak': false,
        'bulan_daftar': 11,
        'tahun_daftar': 2026,
        'wajib_terbayar': [
          {'bulan': 11, 'tahun': 2026},
        ],
        'tunggakan_wajib': [],
      });

      final now = DateTime(2026, 11, 15);

      // Bulan 1 - 10 tahun 2026 adalah sebelum terdaftar
      expect(anggotaNov.isBeforeRegistration(1, 2026), isTrue);
      expect(anggotaNov.isBeforeRegistration(10, 2026), isTrue);
      expect(anggotaNov.isBeforeRegistration(11, 2026), isFalse);
      expect(anggotaNov.isBeforeRegistration(12, 2026), isFalse);

      // Bulan sebelum daftar tidak dianggap lunas
      expect(anggotaNov.isMonthPaid(1, 2026, now: now), isFalse);

      // Bulan 11 tercatat terbayar
      expect(anggotaNov.isMonthPaid(11, 2026, now: now), isTrue);

      // Bulan 12 belum terbayar
      expect(anggotaNov.isMonthPaid(12, 2026, now: now), isFalse);
    });
  });

  group('DashboardAlertBanner narrow width layout', () {
    testWidgets('renders full status alert title on 360px screen without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardAlertBanner.amber(
              title: 'Perhatian: Status Menunggak',
              subtitle: 'Ada 1 bulan Simpanan Wajib belum dibayar.',
              actionLabel: 'Bayar',
              icon: Icons.warning_amber_rounded,
              onActionTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perhatian: Status Menunggak'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Activation & Tunggakan modal dialogs', () {
    testWidgets(
        'WajibSimpananModalDialog uses new-member activation copy and Rp 15.000 + Rp 2.500',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WajibSimpananModalDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktivasi Keanggotaan'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 2.500'), findsOneWidget);
      expect(find.text('Rp 17.500'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.textContaining('100.000'), findsNothing);
      expect(find.textContaining('MENUNGGAK'), findsNothing);
    });

    testWidgets(
        'TunggakanModalDialog switches to BELUM AKTIF & Rp 15.000 when saldoPokok == 0',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final newMember = DashboardAnggota(
        id: 1,
        noAnggota: '1211260001',
        nama: 'ZOYA NUJULA RAMADHONI',
        status: 'belum_aktif',
        isPokokPaid: false,
        isWajibPaid: false,
        isMemberActive: false,
        cabang: 'KC TELUK DALAM BJM',
        isMenunggak: false,
        tunggakanWajib: [
          TunggakanItem(
            bulan: 11,
            tahun: 2026,
            label: 'November 2026',
            nominal: 2500,
          ),
        ],
        totalTunggakanWajib: 2500,
        jumlahBulanMenunggak: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TunggakanModalDialog(anggota: newMember, saldoPokok: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STATUS: BELUM AKTIF'), findsOneWidget);
      expect(find.text('STATUS: MENUNGGAK'), findsNothing);
      expect(find.textContaining('Rp 15.000'), findsWidgets);
      expect(find.text('Rp 17.500'), findsOneWidget);
      expect(find.textContaining('100.000'), findsNothing);
      expect(find.text('Bayar Aktivasi Sekarang'), findsOneWidget);
    });

    testWidgets(
        'TunggakanModalDialog shows STATUS: MENUNGGAK when saldoPokok > 0',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final overdueMember = DashboardAnggota(
        id: 2,
        noAnggota: '1211260002',
        nama: 'BUDI SANTOSO',
        status: 'menunggak',
        isPokokPaid: true,
        isWajibPaid: true,
        isMemberActive: false,
        cabang: 'KC PUSAT',
        isMenunggak: true,
        tunggakanWajib: [
          TunggakanItem(
            bulan: 10,
            tahun: 2026,
            label: 'Oktober 2026',
            nominal: 2500,
          ),
          TunggakanItem(
            bulan: 11,
            tahun: 2026,
            label: 'November 2026',
            nominal: 2500,
          ),
        ],
        totalTunggakanWajib: 5000,
        jumlahBulanMenunggak: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TunggakanModalDialog(anggota: overdueMember, saldoPokok: 15000),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STATUS: MENUNGGAK'), findsOneWidget);
      expect(find.text('Tunggakan Simpanan Wajib'), findsOneWidget);
      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(find.textContaining('100.000'), findsNothing);
    });
  });

  group('KtpOcrHelper address extraction', () {
    test('extracts standard multi-line KTP address and administrative regions',
        () {
      final result = KtpOcrHelper.parseAddressFromLines([
        'PROVINSI JAWA TIMUR',
        'KABUPATEN SIDOARJO',
        'NIK : 3515081203900001',
        'Nama : AHMAD FAUZI',
        'Tempat/Tgl Lahir : SIDOARJO, 12-03-1990',
        'Jenis Kelamin : LAKI-LAKI Gol. Darah : O',
        'Alamat : JL. MERDEKA NO. 10',
        'PERUM GRIYA INDAH BLOK B2',
        'RT/RW : 003/004',
        'Kel/Desa : PEPELEGI',
        'Kecamatan : WARU',
        'Agama : ISLAM',
        'Status Perkawinan : KAWIN',
        'Kewarganegaraan : WNI',
        'Berlaku Hingga : SEUMUR HIDUP',
      ]);

      expect(result.provinsi, 'Jawa Timur');
      expect(result.kabupatenKota, 'Kabupaten Sidoarjo');
      expect(result.alamat, 'Jl. Merdeka No. 10 Perum Griya Indah Blok B2');
      expect(result.rtRw, '003/004');
      expect(result.kelurahanDesa, 'Pepelegi');
      expect(result.kecamatan, 'Waru');
      expect(
        result.formattedAlamat,
        'Jl. Merdeka No. 10 Perum Griya Indah Blok B2, RT/RW 003/004, Kel. Pepelegi, Kec. Waru',
      );
    });

    test('handles OCR confusion on split lines and ignores non-address values',
        () {
      final result = KtpOcrHelper.parseAddressFromLines([
        'PROPINSI KALIMANTAN SELATAN',
        'KOTA BANJARMASIN',
        'Alamai',
        ': KOMP MELATI NO 7',
        'RTIRW : OOI/OO2',
        'KEVDESA : TELUK DALAM',
        'Kecamatan',
        ': BANJARMASIN TENGAH',
        'Agama : ISLAM',
      ]);

      expect(result.provinsi, 'Kalimantan Selatan');
      expect(result.kabupatenKota, 'Kota Banjarmasin');
      expect(result.alamat, 'Komp Melati No 7');
      expect(result.rtRw, '001/002');
      expect(result.kelurahanDesa, 'Teluk Dalam');
      expect(result.kecamatan, 'Banjarmasin Tengah');
    });

    test('normalizes OCR typos in address and administrative regions (Banjarmasin, Surgi Mufti, Jl. Adam)', () {
      final result = KtpOcrHelper.parseAddressFromLines([
        'PROVINSI KALIMANTAN SEATAN',
        'KOTA BANJARMASIN',
        'NIK : 1371040903070804',
        'Nama : MOHAMMAD ARIFIN',
        'Tempat/Tgl Lahir : BANJARMASIN, 09-03-2007',
        'Jenis Kelamin : LAKI-LAKI',
        'Alamat : Lsadam Kompiaekwondo Permai',
        'RIRW : 001/002',
        'Kel/Desa : Surgiufh',
        'Kecamatan : Banjarmasin Utaha',
        'Agama : ISLAM',
      ]);

      expect(result.provinsi, 'Kalimantan Selatan');
      expect(result.kabupatenKota, 'Kota Banjarmasin');
      expect(result.alamat, 'Jl. Adam Komp. Taekwondo Permai');
      expect(result.rtRw, '001/002');
      expect(result.kelurahanDesa, 'Surgi Mufti');
      expect(result.kecamatan, 'Banjarmasin Utara');
      expect(
        result.formattedAlamat,
        'Jl. Adam Komp. Taekwondo Permai, RT/RW 001/002, Kel. Surgi Mufti, Kec. Banjarmasin Utara',
      );
    });

    test('validates and rejects non-names and OCR RT/RW label typos', () {
      expect(KtpOcrHelper.isValidNamaForTesting('RIRW'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('RTRW'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('RTIRW'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('RT/RW'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('RW'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('RT'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('ISLAM'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('SEUMUR HIDUP'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('BELUM KAWIN'), isFalse);
      expect(KtpOcrHelper.isValidNamaForTesting('JL. GAJAH MADA'), isFalse);

      expect(KtpOcrHelper.isValidNamaForTesting('MOHAMMAD ARIFIN'), isTrue);
      expect(KtpOcrHelper.isValidNamaForTesting('AHMAD FAUZI'), isTrue);
      expect(KtpOcrHelper.isValidNamaForTesting('BUDI'), isTrue);
      expect(KtpOcrHelper.isValidNamaForTesting('SUHARTO'), isTrue);
    });

    test('extracts and cleans birth place and birth date accurately (resolves Ahir Banjarmasn D anomaly)', () {
      final birthData = KtpOcrHelper.extractBirthDataForTesting([
        'Tempat/Tgl Lahir : Ahir Banjarmasn D 09-03-2007',
      ], 'Tempat/Tgl Lahir : Ahir Banjarmasn D 09-03-2007', '6371940903070004');

      expect(birthData['tempat'], 'Banjarmasin');
      expect(birthData['tanggal'], DateTime(2007, 3, 9));
      expect(KtpOcrHelper.cleanPlaceTextForTesting('Ahir Banjarmasn D'), 'Banjarmasin');
      expect(KtpOcrHelper.cleanPlaceTextForTesting('Banjarmasn'), 'Banjarmasin');
      expect(KtpOcrHelper.cleanPlaceTextForTesting('Sidoarjo'), 'Sidoarjo');
      expect(KtpOcrHelper.cleanPlaceTextForTesting('TEMPAT LAHIR BANYUMAS'), 'Banyumas');
    });

    test('extracts RT/RW digits accurately across various formats (slash, colon, labels, space)', () {
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('RT/RW : 001/002'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('RIRW : 001/002'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('RT 01 RW 02'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('001/002'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('01/02'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('1/2'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('001002'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('0102'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('RT. 001 / RW. 002'), '001/002');
      expect(KtpOcrHelper.extractRtRwDigitsForTesting('PW 001/002'), '001/002');
    });

    test('auto-corrects NIK OCR typos using administrative context and birth date', () {
      // 1. Kasus typo kecamatan Banjarmasin Utara: 637194 -> 637104
      final correctedKec = KtpOcrHelper.correctNikForTesting(
        '6371940903070004',
        detectedProvince: 'Kalimantan Selatan',
        detectedKabupatenKota: 'Kota Banjarmasin',
        detectedKecamatan: 'Banjarmasin Utara',
        detectedBirthDate: DateTime(2007, 3, 9),
        detectedGender: 'Laki-laki',
      );
      expect(correctedKec, '6371040903070004');

      // 2. Kasus typo provinsi 13 -> 63 dan nomor urut 0804 -> 0004
      final correctedProvAndUrut = KtpOcrHelper.correctNikForTesting(
        '1371040903070804',
        detectedProvince: 'Kalimantan Selatan',
        detectedKabupatenKota: 'Kota Banjarmasin',
        detectedKecamatan: 'Banjarmasin Utara',
        detectedBirthDate: DateTime(2007, 3, 9),
        detectedGender: 'Laki-laki',
      );
      expect(correctedProvAndUrut, '6371040903070004');

      // 3. Kasus normalisasi alamat Lsadam Kompiaekwondo Perma
      final normalizedAlamat = KtpOcrHelper.normalizeAlamatForTesting('Lsadam Kompiaekwondo Perma');
      expect(normalizedAlamat, 'Jl. Adam Komp. Taekwondo Permai');
    });
  });

  group('LocationAddressService reverse-geocode parser', () {
    test('parses OSM Nominatim Indonesian response accurately without Semarang fallback',
        () {
      final parsed = LocationAddressService.fromNominatimJson({
        'display_name':
            'Jalan Sutoyo S, Teluk Dalam, Banjarmasin Tengah, Banjarmasin, Kalimantan Selatan, 70117, Indonesia',
        'address': {
          'road': 'Jalan Sutoyo S',
          'house_number': '18',
          'village': 'Teluk Dalam',
          'subdistrict': 'Banjarmasin Tengah',
          'city': 'Kota Banjarmasin',
          'state': 'Kalimantan Selatan',
          'postcode': '70117',
          'country_code': 'id',
        },
      });

      expect(parsed, isNotNull);
      expect(
        parsed!.formattedAddress,
        'Jalan Sutoyo S No. 18, Teluk Dalam, Kec. Banjarmasin Tengah',
      );
      expect(parsed.kelurahan, 'Teluk Dalam');
      expect(parsed.kecamatan, 'Banjarmasin Tengah');
      expect(parsed.kabupatenKota, 'Kota Banjarmasin');
      expect(parsed.provinsi, 'Kalimantan Selatan');
      expect(parsed.formattedAddress.toLowerCase(), isNot(contains('semarang')));
    });
  });

  group('Narrow screen overflow and registration consent gating', () {
    Widget wrapCompactScreen(Widget child) {
      return Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.15),
          ),
          child: child,
        ),
      );
    }

    testWidgets(
        'RegisterScreen disables Daftar Sekarang until consent checkbox is checked and avoids UU PDP overflow on 360px',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider(),
          child: MaterialApp(
            home: wrapCompactScreen(const RegisterScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(
        find.text('UU PDP No. 27/2022 • Kebijakan Privasi & Data'),
        findsOneWidget,
      );

      // Verifikasi tombol Scan e-KTP dan Foto Selfie berstatus wajib (*)
      expect(find.text('Foto Selfie *'), findsOneWidget);
      expect(find.text('Ambil Selfie (Wajib)'), findsOneWidget);
      expect(find.text('Scan e-KTP *'), findsOneWidget);
      expect(find.text('Pindai KTP (Wajib)'), findsOneWidget);

      // Verifikasi kolom Tempat Lahir dan Tanggal Lahir berjejer vertikal (stacked), bukan bersampingan
      final tempatLahirLabel = find.text('Tempat Lahir *');
      final tanggalLahirLabel = find.text('Tanggal Lahir *');
      await tester.ensureVisible(tempatLahirLabel);
      await tester.pump();
      expect(tempatLahirLabel, findsOneWidget);
      expect(tanggalLahirLabel, findsOneWidget);

      final tempatY = tester.getTopLeft(tempatLahirLabel).dy;
      final tanggalY = tester.getTopLeft(tanggalLahirLabel).dy;
      expect(tanggalY, greaterThan(tempatY + 40),
          reason: 'Tanggal Lahir harus berada di bawah Tempat Lahir (vertikal), tidak bersampingan.');

      final submitFinder = find.widgetWithText(ElevatedButton, 'Daftar Sekarang');
      await tester.ensureVisible(submitFinder);
      await tester.pump();

      final disabledButton = tester.widget<ElevatedButton>(submitFinder);
      expect(disabledButton.onPressed, isNull);

      final checkboxFinder = find.byType(Checkbox);
      await tester.ensureVisible(checkboxFinder);
      await tester.pump();
      await tester.tap(checkboxFinder);
      await tester.pump();

      final enabledButton = tester.widget<ElevatedButton>(submitFinder);
      expect(enabledButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'PengunduranDiriScreen renders keluar banner and matching confirmation helper without right overflow on 360px',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final exitedProvider = _FakeProfileProvider(
        PengunduranDiriStatusModel(
          statusAnggota: 'keluar',
          isKeluar: true,
          hasPending: false,
          konfirmasiTeksWajib: 'SAYA YAKIN UNTUK MENGUNDURKAN DIRI',
          riwayat: [
            PengajuanRiwayatItem(
              id: 1,
              status: 'disetujui',
              createdAt: '12 Nov 2026 13:50',
            ),
          ],
          ringkasanSaldo: RingkasanSaldoPengunduran(
            saldoPokok: 15000,
            saldoWajib: 2500,
            saldoSukarela: 0,
            saldoSijaka: 0,
            totalKembali: 17500,
          ),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>.value(
          value: exitedProvider,
          child: MaterialApp(
            home: wrapCompactScreen(const PengunduranDiriScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keanggotaan Anda Telah Berakhir'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final activeProvider = _FakeProfileProvider(
        PengunduranDiriStatusModel(
          statusAnggota: 'aktif',
          isKeluar: false,
          hasPending: false,
          konfirmasiTeksWajib: 'SAYA YAKIN UNTUK MENGUNDURKAN DIRI',
          riwayat: const [],
          ringkasanSaldo: RingkasanSaldoPengunduran(
            saldoPokok: 15000,
            saldoWajib: 2500,
            saldoSukarela: 0,
            saldoSijaka: 0,
            totalKembali: 17500,
          ),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>.value(
          value: activeProvider,
          child: MaterialApp(
            home: wrapCompactScreen(const PengunduranDiriScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmField = find.byType(TextField).first;
      await tester.ensureVisible(confirmField);
      await tester.enterText(
        confirmField,
        'SAYA YAKIN UNTUK MENGUNDURKAN DIRI',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Kalimat konfirmasi sesuai, tombol pengajuan aktif.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TopUpScreen aktivasi Pokok + Wajib breakdown and bottom bar render without right overflow on 360px',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dashboardProvider = _FakeDashboardProvider(
        DashboardData(
          anggota: DashboardAnggota(
            id: 1,
            noAnggota: '1211260001',
            nama: 'ZOYA NUJULA RAMADHONI',
            status: 'belum_aktif',
            isPokokPaid: false,
            isWajibPaid: false,
            isMemberActive: false,
            cabang: 'KC TELUK DALAM BJM',
            isMenunggak: false,
            tunggakanWajib: [
              TunggakanItem(
                bulan: 11,
                tahun: 2026,
                label: 'November 2026',
                nominal: 2500,
              ),
            ],
            totalTunggakanWajib: 2500,
            jumlahBulanMenunggak: 1,
          ),
          ringkasanSaldo: RingkasanSaldo(
            saldoPokok: 0,
            saldoWajib: 0,
            saldoSukarela: 0,
            saldoSijaka: 0,
            saldoBagihasilSijaka: 0,
            totalSimpanan: 0,
          ),
          statistiks: DashboardStatistik(jumlahBilyetSijakaAktif: 0),
        ),
      );
      final paymentProvider = _FakePaymentProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DashboardProvider>.value(
              value: dashboardProvider,
            ),
            ChangeNotifierProvider<PaymentProvider>.value(
              value: paymentProvider,
            ),
          ],
          child: MaterialApp(
            home: wrapCompactScreen(
              const TopUpScreen(initialType: 'simpanan_pokok_wajib'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rincian Biaya Registrasi'), findsOneWidget);
      expect(find.text('Simpanan Pokok (1x seumur hidup)'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
      );
    });

    testWidgets(
        'TopUpScreen VA Bank payment opens solid white Menyiapkan Pembayaran card, supports Batalkan, and navigates cleanly when VA ready',
        (tester) async {
      SharedPreferences.setMockInitialValues({'last_payment_method': 'bsi'});
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dashboardProvider = _FakeDashboardProvider(
        DashboardData(
          anggota: DashboardAnggota(
            id: 1,
            noAnggota: '1211260001',
            nama: 'ZOYA NUJULA RAMADHONI',
            status: 'aktif',
            isPokokPaid: true,
            isWajibPaid: true,
            isMemberActive: true,
            cabang: 'KC TELUK DALAM BJM',
            isMenunggak: false,
            tunggakanWajib: const [],
            totalTunggakanWajib: 0,
            jumlahBulanMenunggak: 0,
          ),
          ringkasanSaldo: RingkasanSaldo(
            saldoPokok: 15000,
            saldoWajib: 2500,
            saldoSukarela: 0,
            saldoSijaka: 0,
            saldoBagihasilSijaka: 0,
            totalSimpanan: 17500,
          ),
          statistiks: DashboardStatistik(jumlahBilyetSijakaAktif: 0),
        ),
      );

      Completer<SnapTokenResponse?>? completer;
      final paymentProvider = _FakePaymentProvider(
        channels: const [
          PaymentChannelModel(
            id: 1,
            code: 'bsi',
            name: 'BSI Virtual Account',
            category: 'virtual_account',
            badge: 'OTOMATIS',
            description: 'Transfer instan via BSI Mobile',
            tagColor: Color(0xFF00A39D),
            icon: Icons.account_balance_rounded,
            feeFlat: 4000,
          ),
        ],
        onCreatePayment: () {
          completer = Completer<SnapTokenResponse?>();
          return completer!.future;
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DashboardProvider>.value(
              value: dashboardProvider,
            ),
            ChangeNotifierProvider<PaymentProvider>.value(
              value: paymentProvider,
            ),
          ],
          child: const MaterialApp(
            home: TopUpScreen(initialType: 'simpanan_sukarela'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bayar Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('Menyiapkan Pembayaran...'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);

      final shellCard = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Menyiapkan Pembayaran...'),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).color == Colors.white &&
                    (w.decoration! as BoxDecoration).borderRadius == BorderRadius.circular(26),
              ),
            )
            .first,
      );
      expect((shellCard.decoration! as BoxDecoration).color, Colors.white);

      // Uji pembatalan menutup dialog dengan bersih
      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Menyiapkan Pembayaran...'), findsNothing);
      completer?.complete(null);
      await tester.pump();

      // Uji aliran VA selesai hingga membuka NativePaymentDetailScreen
      await tester.tap(find.text('Bayar Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Menyiapkan Pembayaran...'), findsOneWidget);

      completer!.complete(
        SnapTokenResponse(
          orderId: 'Sirela-261112-TEST',
          snapToken: 'Sirela-261112-TEST',
          snapRedirectUrl: '',
          nominal: 100000,
          nominalFormat: 'Rp 100.000',
          adminFee: 4000,
          grossAmount: 104000,
          type: 'simpanan_sukarela',
          status: 'pending',
          paymentMode: 'direct_va',
          paymentMethod: 'virtual_account',
          bank: 'bsi',
          bankName: 'BSI Virtual Account',
          vaNumber: '9881234567890123',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Menyiapkan Pembayaran...'), findsNothing);
      expect(find.byType(NativePaymentDetailScreen), findsOneWidget);
      expect(find.text('9881234567890123'), findsWidgets);

      // Pastikan timer polling/countdown pada detail screen dibersihkan sebelum test berakhir
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets(
      'TopUpScreen QRIS and VA Bank share identical PaymentPreparationCard layout and white 26px shell',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dashboardProvider = _FakeDashboardProvider(
          DashboardData(
            anggota: DashboardAnggota(
              id: 2,
              noAnggota: '1211260002',
              nama: 'Budi',
              status: 'aktif',
              isPokokPaid: true,
              isWajibPaid: true,
              isMemberActive: true,
              cabang: 'KC TELUK DALAM BJM',
              isMenunggak: false,
              tunggakanWajib: const [],
              totalTunggakanWajib: 0,
              jumlahBulanMenunggak: 0,
            ),
            ringkasanSaldo: RingkasanSaldo(
              saldoPokok: 15000,
              saldoWajib: 2500,
              saldoSukarela: 200000,
              saldoSijaka: 0,
              saldoBagihasilSijaka: 0,
              totalSimpanan: 217500,
            ),
            statistiks: DashboardStatistik(jumlahBilyetSijakaAktif: 0),
          ),
        );

        Future<Size> measurePreparationShellSize(String channelCode, String channelName) async {
          SharedPreferences.setMockInitialValues({'last_payment_method': channelCode});
          Completer<SnapTokenResponse?>? completer;
          final paymentProvider = _FakePaymentProvider(
            channels: [
              PaymentChannelModel(
                id: channelCode == 'qris' ? 2 : 1,
                code: channelCode,
                name: channelName,
                category: channelCode == 'qris' ? 'qris' : 'virtual_account',
                badge: 'OTOMATIS',
                tagColor: channelCode == 'qris'
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF00A39D),
                icon: Icons.qr_code_scanner_rounded,
                feeFlat: 0,
              ),
            ],
            onCreatePayment: () {
              completer = Completer<SnapTokenResponse?>();
              return completer!.future;
            },
          );

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
                ChangeNotifierProvider<PaymentProvider>.value(value: paymentProvider),
              ],
              child: const MaterialApp(
                home: TopUpScreen(initialType: 'simpanan_sukarela'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Bayar Sekarang'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 260));

          expect(find.byType(PaymentPreparationCard), findsOneWidget);
          expect(find.text('Menghubungkan ke server pembayaran...'), findsOneWidget);
          expect(find.text('Batalkan'), findsOneWidget);

          final cardSize = tester.getSize(find.byType(PaymentPreparationCard));
          final decoratedCardFinder = find.ancestor(
            of: find.byType(PaymentPreparationCard),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).color == Colors.white &&
                  (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(26),
            ),
          );
          expect(decoratedCardFinder, findsOneWidget);
          final cardShellSize = tester.getSize(decoratedCardFinder);
          expect(cardSize.width, cardShellSize.width);

          await tester.tap(find.text('Batalkan'));
          await tester.pumpAndSettle();
          completer?.complete(null);
          await tester.pump();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          return cardShellSize;
        }

        final qrisShellSize = await measurePreparationShellSize('qris', 'QRIS Nasional');
        final vaShellSize = await measurePreparationShellSize('bsi', 'BSI Virtual Account');

        expect(qrisShellSize.width, vaShellSize.width);
        expect(qrisShellSize.height, closeTo(vaShellSize.height, 2.0));
      },
    );

    testWidgets('MemberActivationGuard blocks inactive member and shows WajibSimpananModalDialog',
        (tester) async {
      final dashboardProvider = _FakeDashboardProvider(
        DashboardData(
          anggota: DashboardAnggota(
            id: 1,
            noAnggota: '12345',
            nama: 'Nasabah Baru',
            status: 'belum_aktif',
            isPokokPaid: false,
            isWajibPaid: false,
            isMemberActive: false,
            cabang: 'KC Banjarmasin',
            isMenunggak: false,
            tunggakanWajib: const [],
            totalTunggakanWajib: 0,
            jumlahBulanMenunggak: 0,
          ),
          ringkasanSaldo: RingkasanSaldo(
            saldoPokok: 0,
            saldoWajib: 0,
            saldoSukarela: 0,
            saldoSijaka: 0,
            saldoBagihasilSijaka: 0,
            totalSimpanan: 0,
          ),
          statistiks: DashboardStatistik(jumlahBilyetSijakaAktif: 0),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DashboardProvider>.value(
          value: dashboardProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MemberActivationGuard.checkAndRequireActivation(context);
                    },
                    child: const Text('Klik Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Aktivasi Keanggotaan'), findsNothing);
      await tester.tap(find.text('Klik Menu'));
      await tester.pumpAndSettle();

      // Memastikan popup modal aktivasi muncul
      expect(find.text('Aktivasi Keanggotaan'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
      expect(find.text('Rp 17.500'), findsOneWidget);
    });
  });
}

class _FakeProfileProvider extends ProfileProvider {
  final PengunduranDiriStatusModel _fakeStatus;

  _FakeProfileProvider(this._fakeStatus);

  @override
  PengunduranDiriStatusModel? get pengunduranStatus => _fakeStatus;

  @override
  bool get isPengunduranLoading => false;

  @override
  Future<void> fetchPengunduranStatus() async {}
}

class _FakeDashboardProvider extends DashboardProvider {
  final DashboardData _fakeDashboard;

  _FakeDashboardProvider(this._fakeDashboard);

  @override
  DashboardData? get dashboardData => _fakeDashboard;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchDashboard({bool refresh = false}) async {}
}

class _FakePaymentProvider extends PaymentProvider {
  final List<PaymentChannelModel> _channels;
  final Future<SnapTokenResponse?> Function()? _onCreatePayment;

  _FakePaymentProvider({
    List<PaymentChannelModel> channels = const [],
    Future<SnapTokenResponse?> Function()? onCreatePayment,
  })  : _channels = channels,
        _onCreatePayment = onCreatePayment;

  @override
  List<PaymentChannelModel> get activeChannels => _channels;

  @override
  List<SnapTokenResponse> get pendingPayments => const [];

  @override
  Future<void> fetchPaymentChannels() async {}

  @override
  Future<SnapTokenResponse?> createPayment({
    required String type,
    required int nominal,
    String? paymentMethod,
    String? bank,
    int? bulan,
    int? bulanAkhir,
    int? tahun,
    int? sijakaProdukId,
    String? namaAhliWaris,
    String? hubunganAhliWaris,
    String? nikAhliWaris,
    String? namaBank,
    String? noRekening,
    String? atasNamaRekening,
    String? metodePenyerahanBagihasil,
  }) async {
    if (_onCreatePayment != null) {
      return _onCreatePayment();
    }
    return null;
  }
}

