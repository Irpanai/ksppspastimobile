import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KtpAddressResult {
  final String? alamat;
  final String? rtRw;
  final String? kelurahanDesa;
  final String? kecamatan;
  final String? kabupatenKota;
  final String? provinsi;

  const KtpAddressResult({
    this.alamat,
    this.rtRw,
    this.kelurahanDesa,
    this.kecamatan,
    this.kabupatenKota,
    this.provinsi,
  });

  bool get hasAnyAddress =>
      (alamat != null && alamat!.isNotEmpty) ||
      (rtRw != null && rtRw!.isNotEmpty) ||
      (kelurahanDesa != null && kelurahanDesa!.isNotEmpty) ||
      (kecamatan != null && kecamatan!.isNotEmpty) ||
      (kabupatenKota != null && kabupatenKota!.isNotEmpty) ||
      (provinsi != null && provinsi!.isNotEmpty);

  /// Gabungan Jalan + RT/RW + Kel/Desa + Kecamatan untuk isian domisili
  String? get formattedAlamat {
    final parts = <String>[];
    if (alamat != null && alamat!.trim().isNotEmpty) {
      parts.add(alamat!.trim());
    }
    if (rtRw != null && rtRw!.trim().isNotEmpty) {
      final hasRtAlready = (alamat ?? '').toUpperCase().contains('RT');
      if (!hasRtAlready) {
        parts.add('RT/RW ${rtRw!.trim()}');
      }
    }
    if (kelurahanDesa != null && kelurahanDesa!.trim().isNotEmpty) {
      final kel = kelurahanDesa!.trim();
      final upper = kel.toUpperCase();
      parts.add((upper.startsWith('KEL') || upper.startsWith('DESA')) ? kel : 'Kel. $kel');
    }
    if (kecamatan != null && kecamatan!.trim().isNotEmpty) {
      final kec = kecamatan!.trim();
      final upper = kec.toUpperCase();
      parts.add(upper.startsWith('KEC') ? kec : 'Kec. $kec');
    }
    if (parts.isEmpty && kabupatenKota != null && kabupatenKota!.trim().isNotEmpty) {
      parts.add(kabupatenKota!.trim());
    }
    if (parts.isEmpty && provinsi != null && provinsi!.trim().isNotEmpty) {
      parts.add(provinsi!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}

class KtpOcrResult {
  final String? nik;
  final String? nama;
  final String? alamat;
  final KtpAddressResult? addressDetail;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final String? jenisKelamin;
  final String? agama;
  final String? pekerjaan;
  final String? rawText;
  final bool isSuccess;

  const KtpOcrResult({
    this.nik,
    this.nama,
    this.alamat,
    this.addressDetail,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.agama,
    this.pekerjaan,
    this.rawText,
    this.isSuccess = false,
  });
}

class KtpOcrHelper {
  // Kode Provinsi di Indonesia (2 digit pertama NIK)
  static const Set<String> _validProvinceCodes = {
    '11', '12', '13', '14', '15', '16', '17', '18', '19',
    '21', '31', '32', '33', '34', '35', '36', '51', '52',
    '53', '61', '62', '63', '64', '65', '71', '72', '73',
    '74', '75', '76', '81', '82', '91', '92', '94'
  };

  // Mapping nama provinsi Indonesia ke 2 digit kode Dukcapil
  static const Map<String, String> _provinceNameToCode = {
    'ACEH': '11',
    'SUMATERA UTARA': '12',
    'SUMATERA BARAT': '13',
    'RIAU': '14',
    'JAMBI': '15',
    'SUMATERA SELATAN': '16',
    'BENGKULU': '17',
    'LAMPUNG': '18',
    'KEPULAUAN BANGKA BELITUNG': '19',
    'BANGKA BELITUNG': '19',
    'KEPULAUAN RIAU': '21',
    'DKI JAKARTA': '31',
    'JAKARTA': '31',
    'JAWA BARAT': '32',
    'JAWA TENGAH': '33',
    'DI YOGYAKARTA': '34',
    'YOGYAKARTA': '34',
    'JAWA TIMUR': '35',
    'BANTEN': '36',
    'BALI': '51',
    'NUSA TENGGARA BARAT': '52',
    'NTB': '52',
    'NUSA TENGGARA TIMUR': '53',
    'NTT': '53',
    'KALIMANTAN BARAT': '61',
    'KALIMANTAN TENGAH': '62',
    'KALIMANTAN SELATAN': '63',
    'KALIMANTAN TIMUR': '64',
    'KALIMANTAN UTARA': '65',
    'SULAWESI UTARA': '71',
    'SULAWESI TENGAH': '72',
    'SULAWESI SELATAN': '73',
    'SULAWESI TENGGARA': '74',
    'GORONTALO': '75',
    'SULAWESI BARAT': '76',
    'MALUKU': '81',
    'MALUKU UTARA': '82',
    'PAPUA BARAT': '91',
    'PAPUA': '92',
    'PAPUA SELATAN': '93',
    'PAPUA TENGAH': '94',
    'PAPUA PEGUNUNGAN': '95',
    'PAPUA BARAT DAYA': '96',
  };

  // Frasa KTP yang PASTI BUKAN nama orang (blacklist lengkap)
  static const Set<String> _blacklistedPhrases = {
    // Header & Wilayah
    'PROVINSI', 'KABUPATEN', 'KOTA', 'REPUBLIK', 'INDONESIA', 'REPUBLIK INDONESIA',
    'DAERAH KHUSUS', 'IBUKOTA', 'DKI JAKARTA', 'JAWA BARAT', 'JAWA TENGAH',
    'JAWA TIMUR', 'SUMATERA', 'KALIMANTAN', 'SULAWESI', 'PAPUA', 'BALI',
    // Label Field & Typo OCR Label
    'NIK', 'N1K', 'N I K', 'KIK', 'KTP', 'NAMA', 'NARNA', 'NAME', 'MAMA',
    'TEMPAT', 'TGL LAHIR', 'TEMPAT TGL LAHIR', 'TEMPAT LAHIR', 'TANGGAL LAHIR',
    'JENIS KELAMIN', 'GOL DARAH', 'GOLONGAN DARAH', 'ALAMAT', 'RT RW', 'RT', 'RW',
    'RIRW', 'RTRW', 'RTIRW', 'R1RW', 'RT/RW', 'RI/RW', 'R/RW', 'RT.RW', 'RT-RW', 'RW/RT',
    'KEL DESA', 'KELURAHAN', 'DESA', 'KECAMATAN', 'AGAMA', 'STATUS PERKAWINAN',
    'STATUS', 'PERKAWINAN', 'PEKERJAAN', 'KEWARGANEGARAAN', 'BERLAKU HINGGA',
    'BERLAKU', 'HINGGA',
    // Nilai Agama
    'ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDHA', 'BUDDHA', 'KONGHUCU',
    // Nilai Status Perkawinan
    'BELUM KAWIN', 'KAWIN', 'CERAI HIDUP', 'CERAI MATI', 'JANDA', 'DUDA',
    // Nilai Jenis Kelamin
    'LAKI LAKI', 'LAKI-LAKI', 'LAKILAKI', 'PEREMPUAN',
    // Nilai Masa Berlaku
    'SEUMUR HIDUP', 'SEUMUR', 'HIDUP',
    // Nilai Kewarganegaraan
    'WNI', 'WNA',
    // Nilai Pekerjaan Umum di KTP
    'KARYAWAN SWASTA', 'PEGAWAI NEGERI', 'PEGAWAI NEGERI SIPIL', 'PNS',
    'WIRASWASTA', 'PELAJAR MAHASISWA', 'PELAJAR', 'MAHASISWA',
    'PETANI PEKEBUN', 'PETANI', 'PETERNAK', 'NELAYAN', 'BURUH HARIAN',
    'BURUH HARIAN LEPAS', 'PEMBANTU RUMAH TANGGA', 'TNI', 'POLRI', 'POLISI',
    'PENSIUNAN', 'BELUM TIDAK BEKERJA', 'MENGURUS RUMAH TANGGA', 'PEDAGANG',
    'TIDAK BEKERJA', 'BELUM BEKERJA', 'SWASTA', 'BURUH'
  };

  // Kata-kata satuan yang jika semuanya ada di frase, maka bukan nama
  static const Set<String> _blacklistedWords = {
    'PROVINSI', 'KABUPATEN', 'KOTA', 'REPUBLIK', 'INDONESIA', 'KTP', 'NIK',
    'NAMA', 'NARNA', 'NAME', 'TEMPAT', 'TGL', 'LAHIR', 'JENIS', 'KELAMIN',
    'GOL', 'DARAH', 'ALAMAT', 'RT', 'RW', 'RIRW', 'RTRW', 'RTIRW', 'R1RW',
    'KEL', 'DESA', 'KEC', 'KECAMATAN',
    'AGAMA', 'STATUS', 'PERKAWINAN', 'PEKERJAAN', 'KEWARGANEGARAAN', 'BERLAKU',
    'HINGGA', 'SEUMUR', 'HIDUP', 'ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU',
    'BUDDHA', 'BUDHA', 'KONGHUCU', 'BELUM', 'KAWIN', 'CERAI', 'LAKI',
    'PEREMPUAN', 'WNI', 'WNA', 'SWASTA', 'PNS', 'PIRASWASTA', 'WIRASWASTA',
    'KARYAWAN', 'PEGAWAI', 'PELAJAR', 'MAHASISWA', 'PETANI', 'BURUH',
    'BLOK', 'GANG', 'GG', 'NO', 'NOMOR', 'JL', 'JLN', 'JALAN', 'KODE', 'POS'
  };

  /// Memproses recognizedText dari ML Kit untuk mengekstrak NIK dan Nama secara cerdas & presisi
  static KtpOcrResult parse(RecognizedText recognizedText) {
    final List<TextLine> allLines = [];
    final List<String> lineTexts = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          allLines.add(line);
          lineTexts.add(text);
        }
      }
    }

    final rawText = recognizedText.text;
    final visualLines = _mergeVisualLines(allLines);
    final targetLines = visualLines.isNotEmpty ? visualLines : lineTexts;

    // 1. Ekstrak data wilayah & alamat terlebih dahulu untuk konteks koreksi NIK
    final addressDetail = parseAddressFromLines(targetLines);
    final alamat = addressDetail.formattedAlamat;

    // 2. Ekstrak data tanggal lahir & jenis kelamin untuk cross-validasi NIK
    final birthData = _extractBirthData(targetLines, rawText, null);
    final gender = _extractGender(targetLines, rawText, null);
    final detectedBirthDate = birthData['tanggal'] as DateTime?;

    // 3. Ekstrak NIK dengan BoundingBox spatial alignment + cross-validation metadata wilayah & tanggal lahir
    final nik = _extractNik(
      allLines: allLines,
      lineTexts: lineTexts,
      mergedLines: targetLines,
      rawText: rawText,
      detectedProvince: addressDetail.provinsi,
      detectedKabupatenKota: addressDetail.kabupatenKota,
      detectedKecamatan: addressDetail.kecamatan,
      detectedBirthDate: detectedBirthDate,
      detectedGender: gender,
    );

    // 4. Ekstrak Nama (memanfaatkan NIK untuk heuristik urutan posisi di bawah NIK)
    final nama = _extractNama(allLines, lineTexts, targetLines, rawText, nik);

    // 5. Ekstrak Agama & Pekerjaan
    final religion = _extractReligion(targetLines, rawText);
    final job = _extractJob(targetLines, rawText);

    // Fallback tanggal lahir & gender dari NIK jika sebelumnya belum terdeteksi dari teks
    final finalBirthDate = detectedBirthDate ??
        (nik != null && nik.length == 16
            ? (parseNikData(nik)?['dateTime'] as DateTime?)
            : null);
    final finalGender = gender ??
        (nik != null && nik.length == 16
            ? (parseNikData(nik)?['jenis_kelamin'] as String?)
            : null);

    return KtpOcrResult(
      nik: nik,
      nama: nama,
      alamat: alamat,
      addressDetail: addressDetail.hasAnyAddress ? addressDetail : null,
      tempatLahir: birthData['tempat'] as String?,
      tanggalLahir: finalBirthDate,
      jenisKelamin: finalGender,
      agama: religion,
      pekerjaan: job,
      rawText: rawText,
      isSuccess: (nik != null && nik.isNotEmpty) ||
          (nama != null && nama.isNotEmpty) ||
          (alamat != null && alamat.isNotEmpty),
    );
  }

  /// Normalisasi huruf yang sering tertukar dengan angka pada font OCR KTP
  static String normalizeOcrDigits(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      switch (char) {
        case 'O':
        case 'o':
        case 'D':
        case 'Q':
          buffer.write('0');
          break;
        case 'I':
        case 'i':
        case 'l':
        case 'L':
        case '|':
        case '!':
        case '/':
        case ']':
        case '[':
          buffer.write('1');
          break;
        case 'Z':
        case 'z':
          buffer.write('2');
          break;
        case 'E':
        case 'e':
          buffer.write('3');
          break;
        case 'A':
          buffer.write('4');
          break;
        case 'S':
        case 's':
          buffer.write('5');
          break;
        case 'b':
        case 'G':
          buffer.write('6');
          break;
        case 'T':
          buffer.write('7');
          break;
        case 'B':
          buffer.write('8');
          break;
        case 'g':
        case 'q':
          buffer.write('9');
          break;
        default:
          if (RegExp(r'\d').hasMatch(char)) {
            buffer.write(char);
          }
      }
    }
    return buffer.toString();
  }

  // ==========================================
  // LOGIKA EKSTRAKSI NIK (SPATIAL & AUTO-CORRECT METADATA)
  // ==========================================
  static String? _extractNik({
    required List<TextLine> allLines,
    required List<String> lineTexts,
    required List<String> mergedLines,
    required String rawText,
    String? detectedProvince,
    String? detectedKabupatenKota,
    String? detectedKecamatan,
    DateTime? detectedBirthDate,
    String? detectedGender,
  }) {
    // -------------------------------------------------------------
    // STRATEGI 1: Bounding Box Horizontal Alignment (Paling Akurat di ML Kit)
    // Mencari baris label "NIK" di kolom kiri, lalu mencari teks di kolom kanan
    // yang berada di baris horizontal yang sama (Y-level sejajar).
    // -------------------------------------------------------------
    for (final labelLine in allLines) {
      final upper = labelLine.text.trim().toUpperCase();
      if (_isNikLabel(upper)) {
        final labelBox = labelLine.boundingBox;
        final labelCenterY = (labelBox.top + labelBox.bottom) / 2;
        final labelHeight = labelBox.height;

        TextLine? bestMatch;
        double minDistanceX = double.infinity;

        for (final candLine in allLines) {
          if (candLine == labelLine) continue;

          final candBox = candLine.boundingBox;
          final candCenterY = (candBox.top + candBox.bottom) / 2;

          // Berada di sebelah kanan label NIK
          if (candBox.left > labelBox.left + 15) {
            final diffY = (candCenterY - labelCenterY).abs();
            final rowTol = (labelHeight * 0.85).clamp(12.0, 32.0);
            if (diffY < rowTol) {
              final diffX = candBox.left - labelBox.right;
              if (diffX < minDistanceX) {
                minDistanceX = diffX;
                bestMatch = candLine;
              }
            }
          }
        }

        if (bestMatch != null) {
          final candDigits = normalizeOcrDigits(bestMatch.text);
          if (candDigits.length >= 16) {
            final rawCand = candDigits.length == 16
                ? candDigits
                : candDigits.substring(0, 16);
            final corrected = _correctNikWithMetadata(
              rawCand,
              detectedProvince: detectedProvince,
              detectedKabupatenKota: detectedKabupatenKota,
              detectedKecamatan: detectedKecamatan,
              detectedBirthDate: detectedBirthDate,
              detectedGender: detectedGender,
            );
            if (_isValidNik(corrected)) {
              return corrected;
            }
          }
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 2: Teks Berada di Baris yang Mengandung Label NIK
    // (pada mergedLines dan lineTexts)
    // -------------------------------------------------------------
    for (final lines in [mergedLines, lineTexts]) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final upper = line.toUpperCase();

        if (_containsNikLabel(upper)) {
          // Baris yang sama
          final candidate = _cleanLineToNik(line);
          if (candidate != null) {
            final corrected = _correctNikWithMetadata(
              candidate,
              detectedProvince: detectedProvince,
              detectedKabupatenKota: detectedKabupatenKota,
              detectedKecamatan: detectedKecamatan,
              detectedBirthDate: detectedBirthDate,
              detectedGender: detectedGender,
            );
            if (_isValidNik(corrected)) return corrected;
          }

          // Baris berikutnya i + 1
          if (i + 1 < lines.length) {
            final nextCand = _cleanLineToNik(lines[i + 1]);
            if (nextCand != null) {
              final corrected = _correctNikWithMetadata(
                nextCand,
                detectedProvince: detectedProvince,
                detectedKabupatenKota: detectedKabupatenKota,
                detectedKecamatan: detectedKecamatan,
                detectedBirthDate: detectedBirthDate,
                detectedGender: detectedGender,
              );
              if (_isValidNik(corrected)) return corrected;
            }
          }

          // Baris i + 2
          if (i + 2 < lines.length) {
            final next2Cand = _cleanLineToNik(lines[i + 2]);
            if (next2Cand != null) {
              final corrected = _correctNikWithMetadata(
                next2Cand,
                detectedProvince: detectedProvince,
                detectedKabupatenKota: detectedKabupatenKota,
                detectedKecamatan: detectedKecamatan,
                detectedBirthDate: detectedBirthDate,
                detectedGender: detectedGender,
              );
              if (_isValidNik(corrected)) return corrected;
            }
          }
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 3: Scan Regex 16 digit langsung pada rawText
    // -------------------------------------------------------------
    final exactMatches = RegExp(r'\b(\d{16})\b').allMatches(rawText);
    for (final m in exactMatches) {
      final val = m.group(1)!;
      final corrected = _correctNikWithMetadata(
        val,
        detectedProvince: detectedProvince,
        detectedKabupatenKota: detectedKabupatenKota,
        detectedKecamatan: detectedKecamatan,
        detectedBirthDate: detectedBirthDate,
        detectedGender: detectedGender,
      );
      if (_isValidNik(corrected)) return corrected;
    }

    // -------------------------------------------------------------
    // STRATEGI 4: Scan tiap baris dengan normalisasi OCR confusion huruf -> angka
    // -------------------------------------------------------------
    for (final line in [...mergedLines, ...lineTexts]) {
      final cleaned = normalizeOcrDigits(line);
      if (cleaned.length == 16) {
        final corrected = _correctNikWithMetadata(
          cleaned,
          detectedProvince: detectedProvince,
          detectedKabupatenKota: detectedKabupatenKota,
          detectedKecamatan: detectedKecamatan,
          detectedBirthDate: detectedBirthDate,
          detectedGender: detectedGender,
        );
        if (_isValidNik(corrected)) return corrected;
      } else if (cleaned.length > 16) {
        for (int j = 0; j <= cleaned.length - 16; j++) {
          final sub = cleaned.substring(j, j + 16);
          final corrected = _correctNikWithMetadata(
            sub,
            detectedProvince: detectedProvince,
            detectedKabupatenKota: detectedKabupatenKota,
            detectedKecamatan: detectedKecamatan,
            detectedBirthDate: detectedBirthDate,
            detectedGender: detectedGender,
          );
          if (_isValidNik(corrected)) return corrected;
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 5: Pola angka berjarak (misal: 6371 0409 0307 0004)
    // -------------------------------------------------------------
    final spacedMatches = RegExp(r'(\d{2,6}[\s\-\.]{1,2}\d{2,6}[\s\-\.]{1,2}\d{2,6}[\s\-\.]{0,2}\d{0,6})')
        .allMatches(rawText);
    for (final m in spacedMatches) {
      final cleaned = m.group(0)!.replaceAll(RegExp(r'[\s\-\.]'), '');
      if (cleaned.length == 16) {
        final corrected = _correctNikWithMetadata(
          cleaned,
          detectedProvince: detectedProvince,
          detectedKabupatenKota: detectedKabupatenKota,
          detectedKecamatan: detectedKecamatan,
          detectedBirthDate: detectedBirthDate,
          detectedGender: detectedGender,
        );
        if (_isValidNik(corrected)) return corrected;
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 6: Fallback terakhir jika ada 16 digit angka murni
    // -------------------------------------------------------------
    for (final m in exactMatches) {
      return _correctNikWithMetadata(
        m.group(1)!,
        detectedProvince: detectedProvince,
        detectedKabupatenKota: detectedKabupatenKota,
        detectedKecamatan: detectedKecamatan,
        detectedBirthDate: detectedBirthDate,
        detectedGender: detectedGender,
      );
    }

    return null;
  }

  static bool _isNikLabel(String upper) {
    final clean = upper.replaceAll(RegExp(r'[\W_]+'), ' ').trim();
    return clean == 'NIK' ||
        clean == 'N1K' ||
        clean == 'KIK' ||
        clean == 'N I K' ||
        clean == 'NI K' ||
        clean == 'N IK' ||
        clean.startsWith('NIK ') ||
        clean.startsWith('N1K ') ||
        clean.startsWith('KIK ');
  }

  static bool _containsNikLabel(String upper) {
    return upper.contains('NIK') ||
        upper.contains('N1K') ||
        upper.contains('N I K') ||
        upper.contains('KIK');
  }

  static String? _cleanLineToNik(String line) {
    final cleaned = line.replaceAll(
      RegExp(r'(?:NIK|N1K|N I K|KIK|KTP|:)[\W_]*', caseSensitive: false),
      ' ',
    );
    final digitsOnly = normalizeOcrDigits(cleaned);
    if (digitsOnly.length == 16) {
      return digitsOnly;
    }
    if (digitsOnly.length > 16) {
      for (int i = 0; i <= digitsOnly.length - 16; i++) {
        final sub = digitsOnly.substring(i, i + 16);
        if (_isValidProvince(sub)) return sub;
      }
      return digitsOnly.substring(0, 16);
    }
    return null;
  }

  static bool _isValidProvince(String nik) {
    if (nik.length < 2) return false;
    final prov = nik.substring(0, 2);
    return _validProvinceCodes.contains(prov);
  }

  /// Memvalidasi format 16 digit NIK sesuai standar Dukcapil RI
  static bool _isValidNik(String nik) {
    if (nik.length != 16) return false;
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) return false;
    final prov = nik.substring(0, 2);
    if (!_validProvinceCodes.contains(prov)) return false;

    final kab = nik.substring(2, 4);
    if (kab == '00') return false;

    final kec = nik.substring(4, 6);
    if (kec == '00') return false;

    final day = int.tryParse(nik.substring(6, 8)) ?? 0;
    final month = int.tryParse(nik.substring(8, 10)) ?? 0;
    final isValidDay = (day >= 1 && day <= 31) || (day >= 41 && day <= 71);
    final isValidMonth = (month >= 1 && month <= 12);

    final urut = nik.substring(12, 16);
    if (urut == '0000') return false;

    return isValidDay && isValidMonth;
  }

  /// Koreksi otomatis OCR typo pada NIK berdasarkan konteks wilayah administratif & tanggal lahir KTP
  static String _correctNikWithMetadata(
    String rawNik, {
    String? detectedProvince,
    String? detectedKabupatenKota,
    String? detectedKecamatan,
    DateTime? detectedBirthDate,
    String? detectedGender,
  }) {
    var digits = normalizeOcrDigits(rawNik);
    if (digits.length != 16) return digits;

    var prov = digits.substring(0, 2);
    var kab = digits.substring(2, 4);
    var kec = digits.substring(4, 6);
    var tgl = digits.substring(6, 8);
    var bln = digits.substring(8, 10);
    var thn = digits.substring(10, 12);
    var urut = digits.substring(12, 16);

    // 1. KOREKSI KODE PROVINSI (Digit 1-2)
    if (detectedProvince != null && detectedProvince.isNotEmpty) {
      final normProv = detectedProvince.toUpperCase().trim();
      String? expectedProvCode;
      for (final entry in _provinceNameToCode.entries) {
        if (normProv.contains(entry.key)) {
          expectedProvCode = entry.value;
          break;
        }
      }
      if (expectedProvCode != null && prov != expectedProvCode) {
        // Contoh: '13' (Sumbar) atau '83' terkoreksi menjadi '63' (Kalimantan Selatan)
        // karena lengkung bawah angka 6 pudar terbaca 1 atau 8
        if (prov[1] == expectedProvCode[1] ||
            _isOcrDigitConfusion(prov[0], expectedProvCode[0]) ||
            _isOcrDigitConfusion(prov[1], expectedProvCode[1])) {
          prov = expectedProvCode;
        } else {
          prov = expectedProvCode;
        }
      }
    }

    // 2. KOREKSI KODE KABUPATEN/KOTA & KECAMATAN (Digit 3-6)
    final normKab = (detectedKabupatenKota ?? '').toUpperCase();
    final normKec = (detectedKecamatan ?? '').toUpperCase();

    // Khusus Kota Banjarmasin (63.71):
    // 01 = Banjarmasin Selatan
    // 02 = Banjarmasin Timur
    // 03 = Banjarmasin Barat
    // 04 = Banjarmasin Utara
    // 05 = Banjarmasin Tengah
    if (kab == '71' || normKab.contains('BANJARMASIN')) {
      kab = '71';
      if (normKec.contains('UTARA') || normKec.contains('UTAHA')) {
        kec = '04'; // Koreksi '94' atau '84' -> '04'
      } else if (normKec.contains('SELATAN') || normKec.contains('SEATAN')) {
        kec = '01';
      } else if (normKec.contains('TIMUR')) {
        kec = '02';
      } else if (normKec.contains('BARAT')) {
        kec = '03';
      } else if (normKec.contains('TENGAH')) {
        kec = '05';
      } else if (kec[0] == '9' || kec[0] == '8') {
        // Fallback: di Banjarmasin tidak ada kecamatan 9x atau 8x, puluhan selalu 0
        kec = '0${kec[1]}';
      }
    } else {
      // Untuk wilayah lain: jika puluhan kecamatan terbaca '9' atau '8' (typo dari '0')
      if (kec[0] == '9' || kec[0] == '8') {
        kec = '0${kec[1]}';
      }
    }

    // 3. KOREKSI TANGGAL LAHIR (Digit 7-12)
    if (detectedBirthDate != null) {
      final isFemale = (detectedGender?.toUpperCase().contains('PEREMPUAN') ?? false) ||
          ((int.tryParse(tgl) ?? 0) > 40);
      final expectedDay = detectedBirthDate.day + (isFemale ? 40 : 0);
      final expectedTgl = expectedDay.toString().padLeft(2, '0');
      final expectedBln = detectedBirthDate.month.toString().padLeft(2, '0');
      final expectedThn = (detectedBirthDate.year % 100).toString().padLeft(2, '0');
      final expectedBirth = '$expectedTgl$expectedBln$expectedThn';
      final actualBirth = '$tgl$bln$thn';

      // Sinkronkan jika hanya ada perbedaan 1 atau 2 digit akibat OCR typo
      int diffCount = 0;
      for (int i = 0; i < 6; i++) {
        if (actualBirth[i] != expectedBirth[i]) diffCount++;
      }
      if (diffCount <= 2) {
        tgl = expectedTgl;
        bln = expectedBln;
        thn = expectedThn;
      }
    }

    // 4. KOREKSI NOMOR URUT PENDAFTARAN (Digit 13-16)
    // Di Dukcapil nomor urut harian dimulai dari 0001, jarang melebihi puluhan per kecamatan per hari.
    // Typo OCR umum: '08' atau '80' atau '88' akibat '00' terbaca 8 atau B
    if (urut.startsWith('08')) {
      urut = '00${urut.substring(2)}'; // Contoh: 0804 -> 0004
    } else if (urut.startsWith('80')) {
      urut = '00${urut.substring(2)}';
    } else if (urut.startsWith('88')) {
      urut = '00${urut.substring(2)}';
    }

    return '$prov$kab$kec$tgl$bln$thn$urut';
  }

  static bool _isOcrDigitConfusion(String a, String b) {
    if (a == b) return true;
    const pairs = {
      '0': {'8', '9', '6', '1'},
      '1': {'7', '4', '6', '0'},
      '2': {'7', '3', '8'},
      '3': {'8', '5', '9'},
      '4': {'1', '9'},
      '5': {'6', '8', '3'},
      '6': {'1', '8', '0', '5'},
      '7': {'1', '2'},
      '8': {'0', '3', '6', '9'},
      '9': {'0', '4', '8'},
    };
    return pairs[a]?.contains(b) ?? false;
  }

  // ==========================================
  // LOGIKA EKSTRAKSI NAMA (AKURAT & PRESET BEBAS ERROR)
  // ==========================================
  static String? _extractNama(
    List<TextLine> allLines,
    List<String> lineTexts,
    List<String> mergedLines,
    String rawText,
    String? foundNik,
  ) {
    // -------------------------------------------------------------
    // STRATEGI 1: Bounding Box Horizontal Alignment (Paling Akurat di ML Kit)
    // Mencari baris label "NAMA" di kolom kiri, lalu mencari teks di kolom kanan
    // yang berada di baris horizontal yang sama (Y-level sejajar).
    // -------------------------------------------------------------
    for (final labelLine in allLines) {
      final upper = labelLine.text.trim().toUpperCase();
      if (_isNamaLabel(upper)) {
        final labelBox = labelLine.boundingBox;
        final labelCenterY = (labelBox.top + labelBox.bottom) / 2;
        final labelHeight = labelBox.height;

        TextLine? bestMatch;
        double minDistanceX = double.infinity;

        for (final candLine in allLines) {
          if (candLine == labelLine) continue;

          final candBox = candLine.boundingBox;
          final candCenterY = (candBox.top + candBox.bottom) / 2;

          // Harus berada di sebelah kanan label NAMA
          if (candBox.left > labelBox.left + 15) {
            // Harus sejajar secara vertikal
            final diffY = (candCenterY - labelCenterY).abs();
            final rowTol = (labelHeight * 0.85).clamp(12.0, 32.0);
            if (diffY < rowTol) {
              final diffX = candBox.left - labelBox.right;
              if (diffX < minDistanceX) {
                minDistanceX = diffX;
                bestMatch = candLine;
              }
            }
          }
        }

        if (bestMatch != null) {
          final candidate = _cleanCandidateNama(bestMatch.text);
          if (_isValidNama(candidate)) {
            return candidate;
          }
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 2: Teks Nama Berada di Baris yang Sama dengan Label
    // Periksa pada mergedLines (baris visual spasial) terlebih dahulu,
    // kemudian pada lineTexts asli.
    // Contoh: "Nama : AHMAD FAUZI" atau "Nama: BUDI SANTOSO"
    // -------------------------------------------------------------
    for (final lines in [mergedLines, lineTexts]) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final upper = line.toUpperCase();

        if (_containsNamaLabel(upper)) {
          String candidate = '';

          // Jika ada tanda pemisah titik dua (':')
          if (line.contains(':')) {
            candidate = line.substring(line.indexOf(':') + 1).trim();
          } else {
            // Hapus awalan label NAMA
            candidate = line.replaceFirst(
              RegExp(r'^(?:NAMA|NARNA|NAME|MAMA|NAM A|N AMA|HAMA)[\s\:\;\-\.]*', caseSensitive: false),
              '',
            ).trim();
          }

          candidate = _cleanCandidateNama(candidate);
          if (_isValidNama(candidate)) {
            return candidate;
          }

          // Jika barisnya hanya berisi label NAMA (nilainya di baris berikutnya)
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            String nextCandidate = nextLine;
            if (nextCandidate.startsWith(':')) {
              nextCandidate = nextCandidate.substring(1).trim();
            }
            nextCandidate = _cleanCandidateNama(nextCandidate);
            if (_isValidNama(nextCandidate)) {
              return nextCandidate;
            }
          }
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 3: Heuristik Urutan KTP (Tepat di Bawah NIK & Sebelum Tempat Lahir)
    // Pada KTP, NAMA selalu terletak di antara NIK dan Tempat/Tgl Lahir.
    // -------------------------------------------------------------
    for (final lines in [mergedLines, lineTexts]) {
      if (foundNik != null) {
        int nikIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains(foundNik) ||
              normalizeOcrDigits(lines[i]).contains(foundNik)) {
            nikIndex = i;
            break;
          }
        }

        if (nikIndex != -1) {
          for (int i = nikIndex + 1; i <= nikIndex + 3 && i < lines.length; i++) {
            final line = lines[i];
            final upper = line.toUpperCase();

            // Lewati jika ini adalah label nama itu sendiri
            if (_isNamaLabel(upper)) continue;
            // Lewati jika ini baris Tempat/Tgl Lahir
            if (upper.contains('TEMPAT') || upper.contains('LAHIR') || upper.contains('TGL')) {
              break; // Sudah melewati area nama
            }

            String candidate = line;
            if (candidate.startsWith(':')) {
              candidate = candidate.substring(1).trim();
            }
            candidate = _cleanCandidateNama(candidate);
            if (_isValidNama(candidate)) {
              return candidate;
            }
          }
        }
      }
    }

    // -------------------------------------------------------------
    // STRATEGI 4: Scan Baris yang Memiliki Format Nama Manusia Valid
    // (Wajib terdiri dari 2 kata atau lebih, hanya huruf, dan bebas blacklist)
    // -------------------------------------------------------------
    for (final line in [...mergedLines, ...lineTexts]) {
      final candidate = _cleanCandidateNama(line);
      if (_isValidNama(candidate)) {
        final words = candidate.split(' ').where((w) => w.length >= 2).toList();
        if (words.length >= 2 && words.length <= 5) {
          // Pastikan tidak ada kata yang terdaftar di blacklist KTP
          bool hasBlacklistedWord = false;
          for (final word in words) {
            if (_blacklistedWords.contains(word)) {
              hasBlacklistedWord = true;
              break;
            }
          }
          if (!hasBlacklistedWord) {
            return candidate;
          }
        }
      }
    }

    return null;
  }

  // ==========================================
  // LOGIKA EKSTRAKSI ALAMAT KTP (LINE & SPASIAL)
  // ==========================================

  /// Menggabungkan segmen TextLine ML Kit yang berada pada baris vertikal sejajar
  /// agar kolom label (kiri) & nilai (kanan) bersatu dalam satu baris logis.
  static List<String> _mergeVisualLines(List<TextLine> lines) {
    if (lines.isEmpty) return [];

    // 1. Sort secara strictly transitif berdasarkan pusat Y (atas ke bawah)
    final sorted = List<TextLine>.from(lines)
      ..sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    // 2. Kelompokkan baris yang sejajar secara horizontal
    final rows = <List<TextLine>>[];
    for (final line in sorted) {
      if (line.text.trim().isEmpty) continue;
      if (rows.isEmpty) {
        rows.add([line]);
        continue;
      }

      final currentRow = rows.last;
      final avgY = currentRow
              .map((l) => l.boundingBox.center.dy)
              .reduce((a, b) => a + b) /
          currentRow.length;
      final avgH = currentRow
              .map((l) => l.boundingBox.height)
              .reduce((a, b) => a + b) /
          currentRow.length;
      final threshold = (avgH * 0.70).clamp(10.0, 32.0);

      if ((line.boundingBox.center.dy - avgY).abs() <= threshold) {
        currentRow.add(line);
      } else {
        rows.add([line]);
      }
    }

    // 3. Urutkan tiap baris dari kiri ke kanan (sumbu X) lalu gabungkan teksnya
    return rows.map((row) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return row.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join(' ');
    }).toList();
  }

  /// Ekstrak komponen alamat KTP dari daftar baris teks terurut.
  static KtpAddressResult parseAddressFromLines(List<String> lines) {
    String? provinsi;
    String? kabupatenKota;
    String? alamat;
    String? rtRw;
    String? kelurahanDesa;
    String? kecamatan;

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i].trim();
      if (rawLine.isEmpty) continue;
      final upper = rawLine.toUpperCase();

      // 1. Header Provinsi
      if (provinsi == null &&
          RegExp(r'^(?:PROVINSI|PROPINSI|PR0VINSI)\b').hasMatch(upper)) {
        String val = rawLine
            .replaceFirst(
              RegExp(r'^(?:PROVINSI|PROPINSI|PR0VINSI)[\s\:\.\-]*', caseSensitive: false),
              '',
            )
            .trim();
        if (val.isEmpty && i + 1 < lines.length && !_isAnyKtpFieldLine(lines[i + 1])) {
          val = lines[i + 1].trim();
        }
        val = _cleanAddressValue(val);
        if (val.isNotEmpty && !_isNonAddressValue(val)) {
          provinsi = _normalizeProvince(val);
        }
        continue;
      }

      // 2. Header Kabupaten / Kota
      if (kabupatenKota == null &&
          RegExp(r'^(?:KABUPATEN|KAB\.|KOTA)\b').hasMatch(upper)) {
        String val = _cleanAddressValue(rawLine);
        if (val.isNotEmpty && !_isNonAddressValue(val)) {
          kabupatenKota = _toReadableTitleCase(_normalizeWilayahText(val));
        }
        continue;
      }

      // 3. Field Alamat (dapat berlanjut ke baris berikutnya)
      if (alamat == null && _matchesAddressLabel(upper, _alamatLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _alamatLabelPattern);
        final parts = <String>[];
        if (val.isNotEmpty && !_isAnyKtpFieldLine(val) && !_isNonAddressValue(val)) {
          final rtInVal = _extractRtRwDigits(val);
          if (rtInVal != null) {
            rtRw ??= rtInVal;
          }
          parts.add(val);
        }

        // Ambil lanjutan baris alamat (maks 2 baris berikutnya sebelum RT/RW atau label lain)
        for (int nextIdx = i + 1; nextIdx <= i + 2 && nextIdx < lines.length; nextIdx++) {
          final nextLine = lines[nextIdx].trim();
          if (nextLine.isEmpty || _isAnyKtpFieldLine(nextLine)) break;

          final cleanedNext = _cleanAddressValue(nextLine);
          if (cleanedNext.isEmpty || _isNonAddressValue(cleanedNext)) break;

          final parsedRtCandidate = _extractRtRwDigits(cleanedNext);
          if (parsedRtCandidate != null) {
            rtRw ??= parsedRtCandidate;
            break;
          }

          if (_looksLikeGenderOrBirthValue(cleanedNext)) break;
          parts.add(cleanedNext);
        }

        final combined = _cleanAddressValue(parts.join(' '));
        if (combined.isNotEmpty && !_isNonAddressValue(combined)) {
          final rtInCombined = _extractRtRwDigits(combined);
          if (rtInCombined != null) {
            rtRw ??= rtInCombined;
          }
          alamat = _normalizeAlamat(combined);
        }
        continue;
      }

      // 4. Field RT/RW
      if (rtRw == null && _matchesAddressLabel(upper, _rtRwLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _rtRwLabelPattern);
        if (val.isEmpty && i + 1 < lines.length && !_isAnyKtpFieldLine(lines[i + 1])) {
          val = lines[i + 1].trim();
        }
        // Coba ekstraksi dari val atau langsung dari rawLine
        final extracted = _extractRtRwDigits(val.isNotEmpty ? val : rawLine);
        if (extracted != null) {
          rtRw = extracted;
        }
        continue;
      }

      // 5. Field Kel/Desa
      if (kelurahanDesa == null && _matchesAddressLabel(upper, _kelDesaLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _kelDesaLabelPattern);
        if (val.isEmpty && i + 1 < lines.length && !_isAnyKtpFieldLine(lines[i + 1])) {
          val = lines[i + 1].trim();
        }
        val = _cleanAddressValue(val);
        if (val.isNotEmpty && !_isNonAddressValue(val)) {
          kelurahanDesa = _toReadableTitleCase(_normalizeWilayahText(val));
        }
        continue;
      }

      // 6. Field Kecamatan
      if (kecamatan == null && _matchesAddressLabel(upper, _kecamatanLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _kecamatanLabelPattern);
        if (val.isEmpty && i + 1 < lines.length && !_isAnyKtpFieldLine(lines[i + 1])) {
          val = lines[i + 1].trim();
        }
        val = _cleanAddressValue(val);
        if (val.isNotEmpty && !_isNonAddressValue(val)) {
          kecamatan = _toReadableTitleCase(_normalizeWilayahText(val));
        }
        continue;
      }
    }

    // Fallback pencarian alamat jika label ALAMAT tidak terbaca namun ada baris jalan/komplek
    if (alamat == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        if (_isAnyKtpFieldLine(line)) continue;
        if (_isNonAddressValue(line)) continue;
        if (_looksLikeGenderOrBirthValue(line)) continue;

        if (RegExp(r'^(?:[LlIi1\|]{1,2}[\.\s]+|[Ll]s|[Jj][Ll]|\bJALAN\b|\bKOMP|\bPERUM)', caseSensitive: false).hasMatch(line)) {
          final rtCand = _extractRtRwDigits(line);
          if (rtCand != null) {
            rtRw ??= rtCand;
          }
          alamat = _normalizeAlamat(line);
          break;
        }
      }
    }

    return KtpAddressResult(
      alamat: alamat,
      rtRw: rtRw,
      kelurahanDesa: kelurahanDesa,
      kecamatan: kecamatan,
      kabupatenKota: kabupatenKota,
      provinsi: provinsi,
    );
  }

  static final RegExp _alamatLabelPattern = RegExp(
    r'^(?:ALAMAT|ALAMAI|ALANAT|AIAMAT)\b',
    caseSensitive: false,
  );

  static final RegExp _rtRwLabelPattern = RegExp(
    r'^(?:R[TI1l\s]*[/\|\\I1\.\-]?\s*RW|RTRW|RIRW|RTIRW|RI\/RW|R\/RW|RT|RW)\b',
    caseSensitive: false,
  );

  static final RegExp _kelDesaLabelPattern = RegExp(
    r'^(?:KEL(?:\.|URAHAN)?\s*[/\|\\V\.\-]?\s*DESA|KEV\s*DESA|KELURAHAN|DESA)\b',
    caseSensitive: false,
  );

  static final RegExp _kecamatanLabelPattern = RegExp(
    r'^(?:KECAMATAN|KECAMAIAN|KEC\.?)\b',
    caseSensitive: false,
  );

  static bool _matchesAddressLabel(String upperLine, RegExp labelPattern) {
    final normalized = upperLine.replaceFirst(RegExp(r'^[\s\:\;\.\-\|!\/]+'), '');
    return labelPattern.hasMatch(normalized);
  }

  static String _extractAfterLabel(String line, RegExp labelPattern) {
    final normalized = line.replaceFirst(RegExp(r'^[\s\:\;\.\-\|!\/]+'), '');
    final withoutLabel = normalized.replaceFirst(labelPattern, '');
    return _cleanAddressValue(withoutLabel);
  }

  static String _cleanAddressValue(String raw) {
    return raw
        .replaceFirst(RegExp(r'^[\s\:\;\|\-\.=]+'), '')
        .replaceAll(RegExp(r'[\s\|]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalisasi arah mata angin & koreksi typo OCR umum pada wilayah administratif Indonesia
  static String _normalizeWilayahText(String input) {
    var s = input.trim();
    if (s.isEmpty) return s;

    // Normalisasi arah mata angin umum
    s = s.replaceAll(RegExp(r'\bUtaha\b', caseSensitive: false), 'Utara');
    s = s.replaceAll(RegExp(r'\bUtapa\b', caseSensitive: false), 'Utara');
    s = s.replaceAll(RegExp(r'\bSeatan\b', caseSensitive: false), 'Selatan');
    s = s.replaceAll(RegExp(r'\bSeiatan\b', caseSensitive: false), 'Selatan');
    s = s.replaceAll(RegExp(r'\bSlatan\b', caseSensitive: false), 'Selatan');
    s = s.replaceAll(RegExp(r'\bBarai\b', caseSensitive: false), 'Barat');
    s = s.replaceAll(RegExp(r'\bTengai\b', caseSensitive: false), 'Tengah');
    s = s.replaceAll(RegExp(r'\bTinur\b', caseSensitive: false), 'Timur');

    // Koreksi typo OCR spesifik pada wilayah yang sering discan pengguna (misal: Banjarmasin & Kalsel)
    s = s.replaceAll(RegExp(r'\bSurgi(?:ufh|mufh|muflti|mufli)\b', caseSensitive: false), 'Surgi Mufti');
    s = s.replaceAll(RegExp(r'\bAntasan\s*Kecil\s*Tim(?:ur|uh|ur)\b', caseSensitive: false), 'Antasan Kecil Timur');
    s = s.replaceAll(RegExp(r'\bSungai\s*Miai\b', caseSensitive: false), 'Sungai Miai');
    s = s.replaceAll(RegExp(r'\bAlalak\s*Ut(?:ara|aha|apa)\b', caseSensitive: false), 'Alalak Utara');
    s = s.replaceAll(RegExp(r'\bKuin\s*Ut(?:ara|aha|apa)\b', caseSensitive: false), 'Kuin Utara');

    return s;
  }

  /// Normalisasi nama provinsi ke bentuk resmi di Indonesia
  static String _normalizeProvince(String raw) {
    var cleaned = _cleanAddressValue(raw);
    cleaned = _normalizeWilayahText(cleaned);
    final upper = cleaned.toUpperCase();

    if (upper.contains('KALIMANTAN')) {
      if (upper.contains('SELATAN') || upper.contains('SEATAN')) return 'Kalimantan Selatan';
      if (upper.contains('TIMUR') || upper.contains('TINUR')) return 'Kalimantan Timur';
      if (upper.contains('BARAT') || upper.contains('BARAI')) return 'Kalimantan Barat';
      if (upper.contains('TENGAH') || upper.contains('TENGAI')) return 'Kalimantan Tengah';
      if (upper.contains('UTARA') || upper.contains('UTAHA')) return 'Kalimantan Utara';
      return 'Kalimantan Selatan';
    }
    if (upper.contains('JAWA')) {
      if (upper.contains('BARAT') || upper.contains('BARAI')) return 'Jawa Barat';
      if (upper.contains('TENGAH') || upper.contains('TENGAI')) return 'Jawa Tengah';
      if (upper.contains('TIMUR') || upper.contains('TINUR')) return 'Jawa Timur';
    }
    if (upper.contains('JAKARTA')) return 'DKI Jakarta';
    if (upper.contains('YOGYAKARTA') || upper.contains('JOGJA')) return 'DI Yogyakarta';
    if (upper.contains('SUMATERA') || upper.contains('SUMATRA')) {
      if (upper.contains('UTARA') || upper.contains('UTAHA')) return 'Sumatera Utara';
      if (upper.contains('BARAT') || upper.contains('BARAI')) return 'Sumatera Barat';
      if (upper.contains('SELATAN') || upper.contains('SEATAN')) return 'Sumatera Selatan';
    }
    if (upper.contains('SULAWESI')) {
      if (upper.contains('SELATAN') || upper.contains('SEATAN')) return 'Sulawesi Selatan';
      if (upper.contains('UTARA') || upper.contains('UTAHA')) return 'Sulawesi Utara';
    }

    return _toReadableTitleCase(cleaned);
  }

  /// Normalisasi teks alamat jalan / domisili dari noise OCR KTP
  static String _normalizeAlamat(String raw) {
    var cleaned = _cleanAddressValue(raw);
    if (cleaned.isEmpty) return cleaned;

    // 1. Bersihkan sisa label Alamat jika ada
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(?:ALAMAT|ALAMAI|ALANAT|AIAMAT)[\s\:\;\.\-]*', caseSensitive: false),
      '',
    );

    // 2. Normalisasi awalan 'Jl.' (Jalan)
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(?:JALAN|JLN|JL|JI|J1|I\.|L\.|1\.)[\.\s]*', caseSensitive: false),
      'Jl. ',
    );
    // Tangani awalan Ls / Is / 1s yang menempel atau terpisah spasi: e.g. "Lsadam" -> "Jl. Adam", "Ls adam" -> "Jl. Adam"
    cleaned = cleaned.replaceFirstMapped(
      RegExp(r'^[LlIi1\|]s[\.\s]*([A-Za-z])'),
      (m) => 'Jl. ${m[1]}',
    );
    // Tangani jika hanya awalan L. / I. / 1. tanpa spasi: "L.Adam" -> "Jl. Adam"
    cleaned = cleaned.replaceFirstMapped(
      RegExp(r'^[LlIi1\|]\.\s*([A-Za-z])'),
      (m) => 'Jl. ${m[1]}',
    );

    // 3. Normalisasi kata Komplek / Kompleks / Komp yang menyatu dengan nama komplek (mis: Kompiaekwondo)
    cleaned = cleaned.replaceAll(
      RegExp(r'\bKomp[a-z]*(?:taekwondo|ekwondo|aekwondo)\b', caseSensitive: false),
      'Komp. Taekwondo',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bKomp(?:ia|ik|ek|\.|\s*)*\s*(?:t?aekwondo|iaekwondo)\b', caseSensitive: false),
      'Komp. Taekwondo',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(?:taekwondo|iaekwondo)\b', caseSensitive: false),
      'Taekwondo',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bKomp(?=[A-Z][a-z]{3,})'),
      'Komp. ',
    );

    // 4. Normalisasi kata Permai yang terpotong/typo (misal: Perma -> Permai)
    cleaned = cleaned.replaceAll(RegExp(r'\bPerma\b', caseSensitive: false), 'Permai');

    // 5. Hapus sisa string RT/RW dari dalam baris jalan agar tidak terduplikasi saat digabung
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(?:RT\s*[/\\\|]?\s*RW|RTRW|RIRW|RTIRW|RI/RW|R/RW|RT|RW)\s*[\:\;\.\-]?\s*\d{1,3}(?:\s*[/\\\|\-]\s*\d{1,3})?', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[\s,]+$'), '').trim();

    return _toReadableTitleCase(cleaned);
  }

  static String? _extractRtRwDigits(String raw) {
    if (raw.trim().isEmpty) return null;

    // 1. Bersihkan kata/token label RT, RW, RTRW, RIRW, RTIRW, RI/RW, PW, dll.
    var cleaned = raw.replaceAll(
      RegExp(r'\b(?:RT\s*[/\\\|]?\s*RW|RTRW|RIRW|RTIRW|RI/RW|R/RW|RT|RW|PW|TI)\b', caseSensitive: false),
      ' ',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[\:\;\=\.]+'), ' ').trim();

    // 2. Format standar dengan slash / dash / backslash: 001/002, 01/02, 1/2
    final slashMatch = RegExp(r'(\d{1,3})\s*[/\\\|\-]\s*(\d{1,3})').firstMatch(cleaned);
    if (slashMatch != null) {
      final rtNum = int.tryParse(slashMatch.group(1)!);
      final rwNum = int.tryParse(slashMatch.group(2)!);
      if (rtNum != null && rwNum != null) {
        return '${rtNum.toString().padLeft(3, '0')}/${rwNum.toString().padLeft(3, '0')}';
      }
    }

    // 3. Format dua grup angka berturutan tanpa slash: '001 002', '01 02', '1 2'
    final spaceMatch = RegExp(r'\b(\d{1,3})\s+(\d{1,3})\b').firstMatch(cleaned);
    if (spaceMatch != null) {
      final rtNum = int.tryParse(spaceMatch.group(1)!);
      final rwNum = int.tryParse(spaceMatch.group(2)!);
      if (rtNum != null && rwNum != null && (rtNum > 0 || rwNum > 0)) {
        return '${rtNum.toString().padLeft(3, '0')}/${rwNum.toString().padLeft(3, '0')}';
      }
    }

    // 4. Normalisasi karakter OCR confusion (O->0, I/l->1, dll.) pada angka
    final digitsOnly = normalizeOcrDigits(cleaned);
    if (digitsOnly.length == 6) {
      final rt = digitsOnly.substring(0, 3);
      final rw = digitsOnly.substring(3, 6);
      return '$rt/$rw';
    }
    if (digitsOnly.length == 4) {
      final rt = digitsOnly.substring(0, 2).padLeft(3, '0');
      final rw = digitsOnly.substring(2, 4).padLeft(3, '0');
      return '$rt/$rw';
    }

    // 5. Coba pencocokan slash dengan normalisasi karakter jika masih ada huruf yang mirip angka
    final alphaSlash = RegExp(r'([A-Za-z0-9]{1,3})\s*[/\\\|\-]\s*([A-Za-z0-9]{1,3})').firstMatch(cleaned);
    if (alphaSlash != null) {
      final rtDigits = normalizeOcrDigits(alphaSlash.group(1)!);
      final rwDigits = normalizeOcrDigits(alphaSlash.group(2)!);
      if (rtDigits.isNotEmpty && rwDigits.isNotEmpty) {
        return '${rtDigits.padLeft(3, '0')}/${rwDigits.padLeft(3, '0')}';
      }
    }

    return null;
  }

  static bool _isAnyKtpFieldLine(String line) {
    final upper = line.trim().toUpperCase();
    return RegExp(
      r'^(?:PROVINSI|PROPINSI|KABUPATEN|KOTA|NIK|NAMA|TEMPAT|JENIS\s*KELAMIN|GOL\.?\s*DARAH|'
      r'ALAMAT|ALAMAI|R[TI1l\s]*[/\|I1\.\-]?\s*RW|RIRW|RTRW|RTIRW|RI/RW|R/RW|RT|RW|'
      r'KEL|KEV|DESA|KEC|AGAMA|STATUS|PEKERJAAN|'
      r'KEWARGANEGARAAN|BERLAKU|SEUMUR\s*HIDUP)\b',
      caseSensitive: false,
    ).hasMatch(upper);
  }

  static bool _looksLikeGenderOrBirthValue(String line) {
    final upper = line.toUpperCase();
    return upper.contains('LAKI-LAKI') ||
        upper.contains('PEREMPUAN') ||
        upper.contains('GOL. DARAH') ||
        RegExp(r'\b\d{2}-\d{2}-\d{4}\b').hasMatch(upper);
  }

  static bool _isNonAddressValue(String value) {
    final upper = value.trim().toUpperCase();
    return const {
      'ISLAM',
      'KRISTEN',
      'KATOLIK',
      'HINDU',
      'BUDDHA',
      'KONGHUCU',
      'WNI',
      'SEUMUR HIDUP',
      'KAWIN',
      'BELUM KAWIN',
      'CERAI HIDUP',
      'CERAI MATI',
    }.contains(upper);
  }

  static String _toReadableTitleCase(String input) {
    const keepUpper = {'RT', 'RW', 'DKI', 'DIY', 'NTB', 'NTT'};
    final words = input.trim().split(RegExp(r'\s+'));
    return words.map((word) {
      final cleanUpper = word.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
      if (keepUpper.contains(cleanUpper)) {
        return word.toUpperCase();
      }
      if (word.contains('/')) {
        return word
            .split('/')
            .map((part) => keepUpper.contains(part.toUpperCase())
                ? part.toUpperCase()
                : _capitalizeSegment(part))
            .join('/');
      }
      return _capitalizeSegment(word);
    }).join(' ');
  }

  static String _capitalizeSegment(String seg) {
    if (seg.isEmpty) return seg;
    if (RegExp(r'^\d+$').hasMatch(seg)) return seg;
    if (seg.length == 1) return seg.toUpperCase();
    return seg[0].toUpperCase() + seg.substring(1).toLowerCase();
  }

  /// Cek apakah baris merupakan label "NAMA"
  static bool _isNamaLabel(String upper) {
    final clean = upper.replaceAll(RegExp(r'[\W_]+'), ' ').trim();
    return clean == 'NAMA' ||
        clean == 'NARNA' ||
        clean == 'NAME' ||
        clean == 'MAMA' ||
        clean == 'NAM A' ||
        clean == 'N AMA' ||
        clean == 'HAMA' ||
        clean == 'MARNA' ||
        clean.startsWith('NAMA ') ||
        clean.startsWith('NARNA ');
  }

  /// Cek apakah baris mengandung label "NAMA"
  static bool _containsNamaLabel(String upper) {
    return upper.contains('NAMA') ||
        upper.contains('NARNA') ||
        upper.contains('NAME') ||
        upper.contains('MAMA') ||
        upper.contains('NAM A') ||
        upper.contains('N AMA');
  }

  /// Membersihkan kandidat nama dari noise OCR, simbol, dan label yang menempel
  static String _cleanCandidateNama(String raw) {
    String text = raw.trim();

    // 1. Potong field berikutnya jika menempel di baris yang sama
    // PENTING: Gunakan batas kata (\b) agar tidak memotong nama seperti:
    // KARTINI (bukan RT), PURWANTO (bukan RW), SITOMPUL (bukan TMP), HARTONO (bukan RT)
    final stopWordsRegex = RegExp(
      r'\b(?:TEMPAT|TMP|TGL|LAHIR|JENIS|KELAMIN|GOL|DARAH|ALAMAT|AGAMA|STATUS|PERKAWINAN|PEKERJAAN|KEWARGANEGARAAN|BERLAKU|RT\s*[/\|I1\.\-]?\s*RW|RIRW|RTRW|RTIRW|RI/RW|R/RW|RT|RW)\b',
      caseSensitive: false,
    );

    final match = stopWordsRegex.firstMatch(text);
    if (match != null) {
      text = text.substring(0, match.start);
    }

    // 2. Hapus simbol awalan seperti ':', '-', '.', '|', tanda kutip, atau angka
    text = text.replaceAll(RegExp(r'^[\s\:\;\-\.\|\!\?\_\d\(\)\[\]\/\\]+'), '');

    // 3. Hapus kata NAMA jika masih tersisa di awal
    text = text.replaceFirst(
      RegExp(r'^(?:NAMA|NARNA|NAME|MAMA|NAM A|N AMA)[\s\:\;\-\.]*', caseSensitive: false),
      '',
    );

    // 4. Hapus simbol akhiran
    text = text.replaceAll(RegExp(r'[\s\:\;\-\.\|\!\?\_\d\(\)\[\]\/\\]+$'), '');

    // 5. Hanya izinkan huruf alfabet, spasi, titik (singkatan nama), dan petik satu (nama arab/daerah)
    text = text.replaceAll(RegExp(r"[^a-zA-Z\s\.'\-]"), ' ');

    // 6. Rapikan spasi ganda
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 7. Bersihkan titik atau karakter liar di awal kata
    text = text.replaceAll(RegExp(r'^\.+'), '').trim();

    return text.toUpperCase();
  }

  /// Memvalidasi apakah kandidat nama benar-benar nama manusia yang masuk akal
  static bool _isValidNama(String candidate) {
    final clean = candidate.trim().toUpperCase();

    // 1. Panjang nama minimal 3 karakter, maksimal 50 karakter
    if (clean.length < 3 || clean.length > 50) return false;

    // 2. NAMA ASLI TIDAK PERNAH MENGANDUNG ANGKA
    if (RegExp(r'\d').hasMatch(clean)) return false;

    // 3. Wajib memiliki setidaknya satu huruf vokal (A, E, I, O, U)
    if (!RegExp(r'[AEIOU]').hasMatch(clean)) return false;

    // 4. Tidak boleh cocok dengan daftar kata/frasa terlarang KTP (Status, Agama, Wilayah, dll)
    final normalized = clean.replaceAll(RegExp(r'[\W_]+'), ' ').trim();
    if (_blacklistedPhrases.contains(normalized)) return false;

    // Cek versi huruf alfabet murni (menangkap typo OCR label KTP seperti RIRW, RTRW, RTIRW)
    final alphaOnly = clean.replaceAll(RegExp(r'[^A-Z]'), '');
    if (_blacklistedWords.contains(alphaOnly) || _blacklistedPhrases.contains(alphaOnly)) {
      return false;
    }

    if (RegExp(r'^(?:R[TI1L]*RW|RTRW|RIRW|RTIRW|RI/RW|R/RW|RW|RT|NIK|KTP|WNI|WNA|JL|JLN|GG|NO|BLOK)$')
        .hasMatch(alphaOnly)) {
      return false;
    }

    // 5. Cek apakah seluruh kata dalam nama ada di blacklist
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return false;

    if (words.every((w) => _blacklistedWords.contains(w))) {
      return false; // Contoh: "BELUM KAWIN", "SEUMUR HIDUP", "LAKI LAKI"
    }

    // Jika hanya 1 kata, tolak singkatan / akronim ganjil
    if (words.length == 1) {
      final single = words.first;
      if (single.contains('RW') || single.startsWith('RT') || single.endsWith('RT')) {
        return false;
      }
      if (single.length <= 4 &&
          !const {
            'EKO', 'ANI', 'IDA', 'IRA', 'INA', 'ARI', 'ALI', 'ADI', 'UDI', 'EDI',
            'ANA', 'EVA', 'LIA', 'MIA', 'TIA', 'RIA', 'BUDI', 'DENI', 'DEDI', 'DONI',
            'FERI', 'HADI', 'HERI', 'JONI', 'RUDI', 'RINI', 'SARI', 'TINA', 'TONI',
            'YUDI', 'YUNI', 'VINA', 'DINA', 'LINA', 'MINA', 'NINA', 'TINI', 'WATI'
          }.contains(single)) {
        final vowelCount = RegExp(r'[AEIOU]').allMatches(single).length;
        if (vowelCount < 2 && single.length >= 4) {
          return false;
        }
      }
    }

    // 6. Nama tidak boleh diawali dengan kata-kata header wilayah administratif
    if (normalized.startsWith('PROVINSI') ||
        normalized.startsWith('KABUPATEN') ||
        normalized.startsWith('KOTA') ||
        normalized.startsWith('REPUBLIK') ||
        normalized.startsWith('INDONESIA') ||
        normalized.startsWith('KECAMATAN') ||
        normalized.startsWith('KELURAHAN') ||
        normalized.startsWith('DESA') ||
        normalized.startsWith('DUSUN')) {
      return false;
    }

    // 7. Nama tidak boleh berformat alamat (misal: "JL", "JALAN", "BLOK", "NO")
    if (normalized.startsWith('JL ') ||
        normalized.startsWith('JALAN ') ||
        normalized.startsWith('BLOK ') ||
        normalized.startsWith('KOMP ') ||
        normalized.startsWith('KOMPLEK ') ||
        normalized.contains(' RT ') ||
        normalized.contains(' RW ')) {
      return false;
    }

    return true;
  }

  // ==========================================
  // PARSER TAMBAHAN: TEMPAT/TGL LAHIR, KELAMIN, AGAMA, PEKERJAAN
  // ==========================================

  /// Bersihkan teks nama tempat lahir dari noise OCR dan kata label KTP
  static String _cleanPlaceText(String raw) {
    var s = raw.trim();

    // 1. Hapus simbol awalan dan akhiran seperti ':', ',', '-', '.', '|'
    s = s.replaceAll(RegExp(r'^[\s\:\;\-\.\|\!\?\_\d\(\)\[\]\/\\]+'), '');
    s = s.replaceAll(RegExp(r'[\s\:\;\-\.\|\!\?\_\d\(\)\[\]\/\\]+$'), '');

    // 2. Hapus label KTP dan variasi salah baca OCR dari Tempat/Tgl Lahir
    s = s.replaceAll(
      RegExp(r'\b(?:TEMPAT|TENPAT|TEMPATIGL|TEMPATGL|TMP|TGL|TG1|TG|1GL|TGI|GL|IGL|LAHIR|LAHR|LAKIR|AHIR|HIR|LAIR|LHR)\b', caseSensitive: false),
      ' ',
    );

    // 3. Hapus karakter non huruf
    s = s.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ');

    // 4. Bersihkan kata/huruf tunggal di awal dan akhir yang merupakan sisa delimiter atau digit OCR
    // Contoh: "D" di akhir (dari sisa ": 0" atau ", 0") atau "L" di awal
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (s.isNotEmpty && (RegExp(r'^[a-zA-Z]\s+').hasMatch(s) || RegExp(r'\s+[a-zA-Z]$').hasMatch(s))) {
      s = s.replaceFirst(RegExp(r'^[a-zA-Z]\s+'), '');
      s = s.replaceFirst(RegExp(r'\s+[a-zA-Z]$'), '');
      s = s.trim();
    }

    // 5. Normalisasi typo OCR nama kota/kabupaten umum di Indonesia (terutama Kalsel & Jawa)
    s = _normalizeCityTypo(s);

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Normalisasi typo OCR nama kota/kabupaten umum di Indonesia
  static String _normalizeCityTypo(String input) {
    var s = input.trim();
    final upper = s.toUpperCase();

    // Banjarmasin (variasi typo: BANJARMASN, BANJARMASLN, BANJARMASHN, BANJARMASIN)
    if (RegExp(r'\bBANJARMAS[NILH][A-Z]?\b', caseSensitive: false).hasMatch(s) ||
        upper == 'BANJARMASN' ||
        upper == 'BANJARMASIN' ||
        upper == 'BANJARMASLN' ||
        upper == 'BANJARMASHN') {
      return 'Banjarmasin';
    }

    // Banjarbaru
    if (RegExp(r'\bBANJAR[BH]ARU\b', caseSensitive: false).hasMatch(s) ||
        upper == 'BANJARBARU' ||
        upper == 'BANJARHARU') {
      return 'Banjarbaru';
    }

    // Martapura
    if (RegExp(r'\bMARTAPU[RH]A\b', caseSensitive: false).hasMatch(s) ||
        upper == 'MARTAPURA' ||
        upper == 'MARTAPUHA') {
      return 'Martapura';
    }

    // Banyumas
    if (RegExp(r'\bBANYU[MN]AS\b', caseSensitive: false).hasMatch(s) ||
        upper == 'BANYUMAS' ||
        upper == 'BANYUNMAS') {
      return 'Banyumas';
    }

    // Sidoarjo
    if (RegExp(r'\bSIDOARJ[OA]\b', caseSensitive: false).hasMatch(s) ||
        upper == 'SIDOARJO' ||
        upper == 'SIDOARJA') {
      return 'Sidoarjo';
    }

    // Surabaya
    if (RegExp(r'\bSURA[BH]AYA\b', caseSensitive: false).hasMatch(s) ||
        upper == 'SURABAYA' ||
        upper == 'SURAHAYA') {
      return 'Surabaya';
    }

    // Jakarta
    if (RegExp(r'\bJAKAT?TA\b', caseSensitive: false).hasMatch(s) ||
        upper == 'JAKARTA' ||
        upper == 'JAKATTA') {
      return 'Jakarta';
    }

    // Semarang
    if (RegExp(r'\bSEMARAN[GY]\b', caseSensitive: false).hasMatch(s) ||
        upper == 'SEMARANG' ||
        upper == 'SEMARANY') {
      return 'Semarang';
    }

    // Padang
    if (RegExp(r'\bPADAN[GY]\b', caseSensitive: false).hasMatch(s) ||
        upper == 'PADANG' ||
        upper == 'PADANY') {
      return 'Padang';
    }

    return s;
  }

  /// Ekstraksi Tempat dan Tanggal Lahir
  static Map<String, dynamic> _extractBirthData(
    List<String> lines,
    String rawText,
    String? nik,
  ) {
    String? tempat;
    DateTime? tanggal;

    // Pola 1: Baris TEMPAT / TGL LAHIR (langsung atau berlanjut di baris berikutnya)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();
      if (upper.contains('TEMPAT') ||
          upper.contains('LAHIR') ||
          upper.contains('TGL') ||
          upper.contains('IGL') ||
          upper.contains('AHIR') ||
          upper.contains('LAHR')) {
        // Hapus label awal jika ada
        var cleaned = line.replaceFirst(
          RegExp(
            r'^(?:TEMPAT|TENPAT|TMP)?[\s\/\&\|Iil!1\:\;\-\.]*(?:TGL|GL|IGL|TG1|TG|1GL|TGI)?[\s\/\&\|Iil!1\:\;\-\.]*(?:LAHIR|LAHR|LAKIR|AHIR|HIR|LAIR|LHR)?[\s\:\;\-\.]*',
            caseSensitive: false,
          ),
          '',
        ).trim();

        // Jika label di baris ini berdiri sendiri, ambil nilai dari baris berikutnya
        if (cleaned.isEmpty && i + 1 < lines.length) {
          cleaned = lines[i + 1].trim();
        }

        // Cari pola tanggal dd-mm-yyyy / dd/mm/yyyy / dd.mm.yyyy
        final dateMatch = RegExp(r'(\d{1,2})[\s\-\/\.](\d{1,2})[\s\-\/\.](\d{2,4})').firstMatch(cleaned);
        if (dateMatch != null) {
          final d = int.tryParse(dateMatch.group(1)!);
          final m = int.tryParse(dateMatch.group(2)!);
          var y = int.tryParse(dateMatch.group(3)!);
          if (y != null && y < 100) {
            final curYear2D = DateTime.now().year % 100;
            y = (y > curYear2D) ? (1900 + y) : (2000 + y);
          }
          if (d != null && m != null && y != null && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
            try {
              tanggal = DateTime(y, m, d);
            } catch (_) {}
          }

          var placeCandidate = cleaned.substring(0, dateMatch.start);
          final cleanedPlace = _cleanPlaceText(placeCandidate);
          if (cleanedPlace.isNotEmpty && cleanedPlace.length >= 3 && !RegExp(r'\d').hasMatch(cleanedPlace)) {
            tempat = _capitalizeWords(cleanedPlace);
          }
        } else if (tempat == null) {
          final cleanedPlace = _cleanPlaceText(cleaned);
          if (cleanedPlace.isNotEmpty && cleanedPlace.length >= 3 && !RegExp(r'\d').hasMatch(cleanedPlace)) {
            tempat = _capitalizeWords(cleanedPlace);
          }
        }
      }
    }

    // Pola 2: Fallback scan baris berformat "[KOTA], dd-mm-yyyy" jika label tidak tertangkap
    if (tempat == null || tanggal == null) {
      for (final line in lines) {
        final match = RegExp(r'^([A-Za-z\s]+)[\,\.\:\s]+(\d{1,2})[\s\-\/\.](\d{1,2})[\s\-\/\.](\d{2,4})').firstMatch(line.trim());
        if (match != null) {
          final placeCandidate = match.group(1)!;
          final cleanedPlace = _cleanPlaceText(placeCandidate);
          if (tempat == null && cleanedPlace.isNotEmpty && cleanedPlace.length >= 3 && !RegExp(r'\d').hasMatch(cleanedPlace)) {
            tempat = _capitalizeWords(cleanedPlace);
          }
          if (tanggal == null) {
            final d = int.tryParse(match.group(2)!);
            final m = int.tryParse(match.group(3)!);
            var y = int.tryParse(match.group(4)!);
            if (y != null && y < 100) {
              final curYear2D = DateTime.now().year % 100;
              y = (y > curYear2D) ? (1900 + y) : (2000 + y);
            }
            if (d != null && m != null && y != null && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
              try {
                tanggal = DateTime(y, m, d);
              } catch (_) {}
            }
          }
        }
      }
    }

    // Pola 3: Fallback tanggal lahir dari NIK jika belum terdeteksi dari teks
    if (tanggal == null && nik != null && nik.length == 16) {
      final nikData = parseNikData(nik);
      if (nikData != null && nikData['dateTime'] is DateTime) {
        tanggal = nikData['dateTime'] as DateTime;
      }
    }

    return {
      'tempat': tempat,
      'tanggal': tanggal,
    };
  }

  /// Ekstraksi Jenis Kelamin
  static String? _extractGender(List<String> lines, String rawText, String? nik) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('JENIS KELAMIN') || upper.contains('KELAMIN') || upper.contains('LAKI') || upper.contains('PEREMPUAN')) {
        if (upper.contains('PEREMPUAN')) {
          return 'Perempuan';
        }
        if (upper.contains('LAKI')) {
          return 'Laki-laki';
        }
      }
    }

    // Fallback dari NIK (Dukcapil standard: digit tanggal > 40 untuk perempuan)
    if (nik != null && nik.length == 16) {
      final nikData = parseNikData(nik);
      if (nikData != null && nikData['jenis_kelamin'] is String) {
        return nikData['jenis_kelamin'] as String;
      }
    }

    return null;
  }

  /// Ekstraksi Agama
  static String? _extractReligion(List<String> lines, String rawText) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('AGAMA') ||
          upper.contains('ISLAM') ||
          upper.contains('KRISTEN') ||
          upper.contains('KATOLIK') ||
          upper.contains('HINDU') ||
          upper.contains('BUDHA') ||
          upper.contains('BUDDHA') ||
          upper.contains('KONGHUCU')) {
        if (upper.contains('ISLAM')) return 'Islam';
        if (upper.contains('KATOLIK')) return 'Kristen Katolik';
        if (upper.contains('KRISTEN')) return 'Kristen Protestan';
        if (upper.contains('HINDU')) return 'Hindu';
        if (upper.contains('BUDDHA') || upper.contains('BUDHA')) return 'Buddha';
        if (upper.contains('KONGHUCU') || upper.contains('KHONGHUCU')) return 'Konghucu';
      }
    }
    return null;
  }

  /// Ekstraksi Pekerjaan
  static String? _extractJob(List<String> lines, String rawText) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('PEKERJAAN') ||
          upper.contains('KARYAWAN') ||
          upper.contains('WIRASWASTA') ||
          upper.contains('PEGAWAI') ||
          upper.contains('PNS') ||
          upper.contains('PETANI') ||
          upper.contains('PEDAGANG') ||
          upper.contains('PELAJAR') ||
          upper.contains('BURUH')) {
        if (upper.contains('WIRASWASTA')) return 'Wiraswasta / Pengusaha';
        if (upper.contains('KARYAWAN') || upper.contains('SWASTA')) return 'Pegawai Swasta';
        if (upper.contains('PNS') || upper.contains('PEGAWAI NEGERI')) return 'Pegawai Negeri Sipil (PNS) / ASN';
        if (upper.contains('PETANI') || upper.contains('PETERNAK') || upper.contains('NELAYAN')) return 'Petani / Peternak / Nelayan';
        if (upper.contains('PEDAGANG')) return 'Pedagang';
        if (upper.contains('PELAJAR') || upper.contains('MAHASISWA')) return 'Pelajar / Mahasiswa';
        if (upper.contains('BURUH')) return 'Buruh Harian / Pekerja Lepas';
        if (upper.contains('MENGURUS RUMAH TANGGA') || upper.contains('IBU RUMAH TANGGA')) return 'Ibu Rumah Tangga';
        if (upper.contains('TNI') || upper.contains('POLRI') || upper.contains('POLISI')) return 'TNI / Polri';
      }
    }
    return null;
  }

  /// Parsing data NIK (Tanggal lahir & Jenis kelamin standar Dukcapil)
  static Map<String, dynamic>? parseNikData(String nik) {
    final cleaned = normalizeOcrDigits(nik);
    if (cleaned.length != 16) return null;
    final dayPart = int.tryParse(cleaned.substring(6, 8));
    final monthPart = int.tryParse(cleaned.substring(8, 10));
    final yearPart = int.tryParse(cleaned.substring(10, 12));
    if (dayPart == null || monthPart == null || yearPart == null) return null;

    String gender = 'Laki-laki';
    int realDay = dayPart;
    if (dayPart > 40) {
      gender = 'Perempuan';
      realDay = dayPart - 40;
    }

    final curYear2Digits = DateTime.now().year % 100;
    final birthYear = (yearPart > curYear2Digits) ? (1900 + yearPart) : (2000 + yearPart);

    if (realDay >= 1 && realDay <= 31 && monthPart >= 1 && monthPart <= 12) {
      try {
        final dt = DateTime(birthYear, monthPart, realDay);
        return {
          'jenis_kelamin': gender,
          'tanggal_lahir': dt,
          'dateTime': dt,
        };
      } catch (_) {}
    }
    return null;
  }

  static String _capitalizeWords(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @visibleForTesting
  static bool isValidNamaForTesting(String candidate) => _isValidNama(candidate);

  @visibleForTesting
  static String normalizeAlamatForTesting(String raw) => _normalizeAlamat(raw);

  @visibleForTesting
  static String normalizeWilayahForTesting(String raw) => _normalizeWilayahText(raw);

  @visibleForTesting
  static String normalizeProvinceForTesting(String raw) => _normalizeProvince(raw);

  @visibleForTesting
  static String cleanPlaceTextForTesting(String raw) => _cleanPlaceText(raw);

  @visibleForTesting
  static Map<String, dynamic> extractBirthDataForTesting(
    List<String> lines,
    String rawText,
    String? nik,
  ) =>
      _extractBirthData(lines, rawText, nik);

  @visibleForTesting
  static String correctNikForTesting(
    String rawNik, {
    String? detectedProvince,
    String? detectedKabupatenKota,
    String? detectedKecamatan,
    DateTime? detectedBirthDate,
    String? detectedGender,
  }) =>
      _correctNikWithMetadata(
        rawNik,
        detectedProvince: detectedProvince,
        detectedKabupatenKota: detectedKabupatenKota,
        detectedKecamatan: detectedKecamatan,
        detectedBirthDate: detectedBirthDate,
        detectedGender: detectedGender,
      );

  @visibleForTesting
  static String? extractRtRwDigitsForTesting(String raw) => _extractRtRwDigits(raw);
}