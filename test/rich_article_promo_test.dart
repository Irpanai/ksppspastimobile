import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_coop/features/promo/models/promo_model.dart';
import 'package:digital_coop/features/promo/widgets/promo_detail_sheet.dart';
import 'package:digital_coop/shared/widgets/rich_article_viewer.dart';

void main() {
  test('stripHtmlToPlainText converts HTML news & tables into clean summary text', () {
    const html = '''
      <h2>Informasi Pemeliharaan Sistem</h2>
      <p>Yth. <strong>Bapak/Ibu Anggota</strong>, layanan <em>mobile</em> akan diperbarui.</p>
      <table>
        <thead><tr><th>Hari</th><th>Jam</th></tr></thead>
        <tbody><tr><td>Kamis</td><td>23.00 &ndash; 03.00 WITA</td></tr></tbody>
      </table>
    ''';

    final plain = stripHtmlToPlainText(html);
    expect(plain, contains('Informasi Pemeliharaan Sistem'));
    expect(plain, contains('Yth. Bapak/Ibu Anggota'));
    expect(plain, contains('Kamis'));
    expect(plain.contains('<'), isFalse);
    expect(plain.contains('>'), isFalse);
  });

  testWidgets('RichArticleViewer renders headings, bold, italic, lists, quotes, and tables cleanly', (tester) async {
    const richHtml = '''
      <h2>Pengumuman Resmi</h2>
      <p>Layanan <strong>KSPPS PASTI</strong> tetap buka dengan <em>penyesuaian jadwal</em> dan <u>ketentuan</u> baru.</p>
      <ul>
        <li>Setoran via <b>QRIS</b> aktif 24 jam</li>
        <li>Layanan kantor buka normal</li>
      </ul>
      <blockquote>Harap menyelesaikan transaksi sebelum pukul 22.00 WITA.</blockquote>
      <table>
        <thead>
          <tr><th>Hari</th><th>Jam Operasional</th><th>Status</th></tr>
        </thead>
        <tbody>
          <tr><td>Senin - Kamis</td><td>08.00 - 16.00</td><td>Buka</td></tr>
          <tr><td>Jumat</td><td>08.00 - 15.30</td><td>Buka</td></tr>
        </tbody>
      </table>
    ''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: RichArticleViewer(content: richHtml),
          ),
        ),
      ),
    );

    expect(find.byType(RichArticleViewer), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('Pengumuman Resmi'), findsOneWidget);
    expect(find.textContaining('Harap menyelesaikan transaksi'), findsOneWidget);
    expect(find.text('Jam Operasional'), findsOneWidget);
  });

  testWidgets('showPromoDetailSheet scrolls cleanly for very long news + table content', (tester) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final longParagraphs = List.generate(
      14,
      (i) => '<p>Paragraf berita ke-${i + 1}: <strong>Informasi penting</strong> untuk seluruh <em>anggota koperasi</em> mengenai pemeliharaan sistem dan layanan digital.</p>',
    ).join();

    final promo = PromoModel(
      id: 99,
      judul: 'Informasi Pemeliharaan Sistem KSPPS PASTI Mobile',
      tipe: 'info',
      tanggalBerakhir: '2026-11-14',
      deskripsi: '$longParagraphs<table><thead><tr><th>Hari</th><th>Waktu</th></tr></thead><tbody><tr><td>Kamis</td><td>23.00 - 03.00 WITA</td></tr></tbody></table><p>AKHIR_ARTIKEL_TERVERIFIKASI</p>',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPromoDetailSheet(context, promo),
              child: const Text('Buka Detail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Informasi Pemeliharaan Sistem KSPPS PASTI Mobile'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // Pastikan tombol scroll bisa menggulir ke bawah hingga akhir artikel tanpa terpotong
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView).first,
      matching: find.byType(Scrollable),
    );
    await tester.dragUntilVisible(
      find.textContaining('AKHIR_ARTIKEL_TERVERIFIKASI'),
      scrollable,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('AKHIR_ARTIKEL_TERVERIFIKASI'), findsOneWidget);
  });
}

