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

  // Frasa KTP yang PASTI BUKAN nama orang (blacklist lengkap)
  static const Set<String> _blacklistedPhrases = {
    // Header & Wilayah
    'PROVINSI', 'KABUPATEN', 'KOTA', 'REPUBLIK', 'INDONESIA', 'REPUBLIK INDONESIA',
    'DAERAH KHUSUS', 'IBUKOTA', 'DKI JAKARTA', 'JAWA BARAT', 'JAWA TENGAH',
    'JAWA TIMUR', 'SUMATERA', 'KALIMANTAN', 'SULAWESI', 'PAPUA', 'BALI',
    // Label Field
    'NIK', 'N1K', 'N I K', 'KIK', 'KTP', 'NAMA', 'NARNA', 'NAME', 'MAMA',
    'TEMPAT', 'TGL LAHIR', 'TEMPAT TGL LAHIR', 'TEMPAT LAHIR', 'TANGGAL LAHIR',
    'JENIS KELAMIN', 'GOL DARAH', 'GOLONGAN DARAH', 'ALAMAT', 'RT RW', 'RT', 'RW',
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
    'GOL', 'DARAH', 'ALAMAT', 'RT', 'RW', 'KEL', 'DESA', 'KEC', 'KECAMATAN',
    'AGAMA', 'STATUS', 'PERKAWINAN', 'PEKERJAAN', 'KEWARGANEGARAAN', 'BERLAKU',
    'HINGGA', 'SEUMUR', 'HIDUP', 'ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU',
    'BUDDHA', 'BUDHA', 'KONGHUCU', 'BELUM', 'KAWIN', 'CERAI', 'LAKI',
    'PEREMPUAN', 'WNI', 'WNA', 'SWASTA', 'PNS', 'PIRASWASTA', 'WIRASWASTA',
    'KARYAWAN', 'PEGAWAI', 'PELAJAR', 'MAHASISWA', 'PETANI', 'BURUH'
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
    final nik = _extractNik(lineTexts, rawText);
    final nama = _extractNama(allLines, lineTexts, rawText, nik);
    final visualLines = _mergeVisualLines(allLines);
    final targetLines = visualLines.isNotEmpty ? visualLines : lineTexts;
    final addressDetail = parseAddressFromLines(targetLines);
    final alamat = addressDetail.formattedAlamat;

    final birthData = _extractBirthData(targetLines, rawText, nik);
    final gender = _extractGender(targetLines, rawText, nik);
    final religion = _extractReligion(targetLines, rawText);
    final job = _extractJob(targetLines, rawText);

    return KtpOcrResult(
      nik: nik,
      nama: nama,
      alamat: alamat,
      addressDetail: addressDetail.hasAnyAddress ? addressDetail : null,
      tempatLahir: birthData['tempat'] as String?,
      tanggalLahir: birthData['tanggal'] as DateTime?,
      jenisKelamin: gender,
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
  // LOGIKA EKSTRAKSI NIK
  // ==========================================
  static String? _extractNik(List<String> lines, String rawText) {
    // 1. Cek langsung baris yang memiliki label NIK
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      if (upper.contains('NIK') ||
          upper.contains('N1K') ||
          upper.contains('N I K') ||
          upper.contains('KIK')) {

        // Coba di baris yang sama
        final candidate = _cleanLineToNik(line);
        if (candidate != null) return candidate;

        // Coba baris berikutnya (jika label NIK dan angkanya terpisah baris oleh OCR)
        if (i + 1 < lines.length) {
          final nextCandidate = _cleanLineToNik(lines[i + 1]);
          if (nextCandidate != null) return nextCandidate;
        }

        // Coba baris i + 2
        if (i + 2 < lines.length) {
          final next2Candidate = _cleanLineToNik(lines[i + 2]);
          if (next2Candidate != null) return next2Candidate;
        }
      }
    }

    // 2. Scan Regex 16 digit langsung pada rawText
    final exactMatches = RegExp(r'\b(\d{16})\b').allMatches(rawText);
    for (final m in exactMatches) {
      final val = m.group(1)!;
      if (_isValidProvince(val)) return val;
    }

    // 3. Scan tiap baris dan normalisasikan OCR confusion huruf -> angka
    for (final line in lines) {
      final cleaned = normalizeOcrDigits(line);
      if (cleaned.length == 16) {
        if (_isValidProvince(cleaned)) return cleaned;
      } else if (cleaned.length > 16) {
        for (int j = 0; j <= cleaned.length - 16; j++) {
          final sub = cleaned.substring(j, j + 16);
          if (_isValidProvince(sub)) return sub;
        }
      }
    }

    // 4. Pola angka berjarak (misal: 3201 0244 0592 0001)
    final spacedMatches = RegExp(r'(\d{2,6}[\s\-\.]{1,2}\d{2,6}[\s\-\.]{1,2}\d{2,6}[\s\-\.]{0,2}\d{0,6})')
        .allMatches(rawText);
    for (final m in spacedMatches) {
      final cleaned = m.group(0)!.replaceAll(RegExp(r'[\s\-\.]'), '');
      if (cleaned.length == 16 && _isValidProvince(cleaned)) {
        return cleaned;
      }
    }

    // 5. Fallback terakhir jika ada 16 digit angka murni
    for (final m in exactMatches) {
      return m.group(1)!;
    }

    return null;
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

  // ==========================================
  // LOGIKA EKSTRAKSI NAMA (AKURAT & PRESET BEBAS ERROR)
  // ==========================================
  static String? _extractNama(
    List<TextLine> allLines,
    List<String> lineTexts,
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
            // Harus sejajar secara vertikal (toleransi ~70% dari tinggi baris)
            final diffY = (candCenterY - labelCenterY).abs();
            if (diffY < (labelHeight * 0.75 + 10)) {
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
    // Contoh: "Nama : AHMAD FAUZI" atau "Nama: BUDI SANTOSO"
    // -------------------------------------------------------------
    for (int i = 0; i < lineTexts.length; i++) {
      final line = lineTexts[i];
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
        if (i + 1 < lineTexts.length) {
          final nextLine = lineTexts[i + 1];
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

    // -------------------------------------------------------------
    // STRATEGI 3: Heuristik Urutan KTP (Tepat di Bawah NIK & Sebelum Tempat Lahir)
    // Pada KTP, NAMA selalu terletak di antara NIK dan Tempat/Tgl Lahir.
    // -------------------------------------------------------------
    if (foundNik != null) {
      int nikIndex = -1;
      for (int i = 0; i < lineTexts.length; i++) {
        if (lineTexts[i].contains(foundNik) ||
            normalizeOcrDigits(lineTexts[i]).contains(foundNik)) {
          nikIndex = i;
          break;
        }
      }

      if (nikIndex != -1) {
        for (int i = nikIndex + 1; i <= nikIndex + 3 && i < lineTexts.length; i++) {
          final line = lineTexts[i];
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

    // -------------------------------------------------------------
    // STRATEGI 4: Scan Baris yang Memiliki Format Nama Manusia Valid
    // (Wajib terdiri dari 2 kata atau lebih, hanya huruf, dan bebas blacklist)
    // -------------------------------------------------------------
    for (final line in lineTexts) {
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

    final sorted = List<TextLine>.from(lines)
      ..sort((a, b) {
        final ay = a.boundingBox.center.dy;
        final by = b.boundingBox.center.dy;
        final rowTol = ((a.boundingBox.height + b.boundingBox.height) / 2) * 0.55;
        if ((ay - by).abs() <= (rowTol > 6 ? rowTol : 6)) {
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        }
        return ay.compareTo(by);
      });

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
      final threshold = (avgH * 0.65).clamp(8.0, 28.0);

      if ((line.boundingBox.center.dy - avgY).abs() <= threshold) {
        currentRow.add(line);
      } else {
        rows.add([line]);
      }
    }

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
          provinsi = _toReadableTitleCase(val);
        }
        continue;
      }

      // 2. Header Kabupaten / Kota
      if (kabupatenKota == null &&
          RegExp(r'^(?:KABUPATEN|KAB\.|KOTA)\b').hasMatch(upper)) {
        String val = _cleanAddressValue(rawLine);
        if (val.isNotEmpty && !_isNonAddressValue(val)) {
          kabupatenKota = _toReadableTitleCase(val);
        }
        continue;
      }

      // 3. Field Alamat (dapat berlanjut ke baris berikutnya)
      if (alamat == null && _matchesAddressLabel(upper, _alamatLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _alamatLabelPattern);
        final parts = <String>[];
        if (val.isNotEmpty && !_isAnyKtpFieldLine(val) && !_isNonAddressValue(val)) {
          parts.add(val);
        }

        // Ambil lanjutan baris alamat (maks 2 baris berikutnya sebelum RT/RW atau label lain)
        for (int nextIdx = i + 1; nextIdx <= i + 2 && nextIdx < lines.length; nextIdx++) {
          final nextLine = lines[nextIdx].trim();
          if (nextLine.isEmpty || _isAnyKtpFieldLine(nextLine)) break;

          final cleanedNext = _cleanAddressValue(nextLine);
          if (cleanedNext.isEmpty || _isNonAddressValue(cleanedNext)) break;

          final parsedRtCandidate = _extractRtRwDigits(cleanedNext);
          if (parsedRtCandidate != null &&
              cleanedNext.replaceAll(RegExp(r'[\d\s/\-\.\:]'), '').isEmpty) {
            rtRw ??= parsedRtCandidate;
            break;
          }

          if (_looksLikeGenderOrBirthValue(cleanedNext)) break;
          parts.add(cleanedNext);
        }

        final combined = _cleanAddressValue(parts.join(' '));
        if (combined.isNotEmpty && !_isNonAddressValue(combined)) {
          alamat = _toReadableTitleCase(combined);
        }
        continue;
      }

      // 4. Field RT/RW
      if (rtRw == null && _matchesAddressLabel(upper, _rtRwLabelPattern)) {
        String val = _extractAfterLabel(rawLine, _rtRwLabelPattern);
        if (val.isEmpty && i + 1 < lines.length && !_isAnyKtpFieldLine(lines[i + 1])) {
          val = lines[i + 1].trim();
        }
        final extracted = _extractRtRwDigits(val);
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
          kelurahanDesa = _toReadableTitleCase(val);
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
          kecamatan = _toReadableTitleCase(val);
        }
        continue;
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
    r'^(?:RT\s*[/\|\\I1\.\-]?\s*RW)\b',
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
    final normalized = upperLine.replaceFirst(RegExp(r'^[\s\:\;\.\-]+'), '');
    return labelPattern.hasMatch(normalized);
  }

  static String _extractAfterLabel(String line, RegExp labelPattern) {
    final normalized = line.replaceFirst(RegExp(r'^[\s\:\;\.\-]+'), '');
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

  static String? _extractRtRwDigits(String raw) {
    if (raw.trim().isEmpty) return null;
    final slashMatch = RegExp(
      r'([A-Za-z0-9]{1,3})\s*[/\\\|]\s*([A-Za-z0-9]{1,3})',
    ).firstMatch(raw);
    if (slashMatch != null) {
      final rtDigits = normalizeOcrDigits(slashMatch.group(1)!);
      final rwDigits = normalizeOcrDigits(slashMatch.group(2)!);
      if (rtDigits.isNotEmpty && rwDigits.isNotEmpty) {
        return '${rtDigits.padLeft(3, '0')}/${rwDigits.padLeft(3, '0')}';
      }
    }

    final digitsOnly = normalizeOcrDigits(raw);
    if (digitsOnly.length == 6) {
      return '${digitsOnly.substring(0, 3)}/${digitsOnly.substring(3, 6)}';
    }
    if (digitsOnly.length == 4) {
      return '${digitsOnly.substring(0, 2).padLeft(3, '0')}/${digitsOnly.substring(2, 4).padLeft(3, '0')}';
    }
    return null;
  }

  static bool _isAnyKtpFieldLine(String line) {
    final upper = line.trim().toUpperCase();
    return RegExp(
      r'^(?:PROVINSI|PROPINSI|KABUPATEN|KOTA|NIK|NAMA|TEMPAT|JENIS\s*KELAMIN|GOL\.?\s*DARAH|'
      r'ALAMAT|ALAMAI|RT\s*[/\|I]?\s*RW|KEL|KEV|DESA|KEC|AGAMA|STATUS|PEKERJAAN|'
      r'KEWARGANEGARAAN|BERLAKU|SEUMUR\s*HIDUP)\b',
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
      r'\b(?:TEMPAT|TMP|TGL|LAHIR|JENIS|KELAMIN|GOL|DARAH|ALAMAT|AGAMA|STATUS|PERKAWINAN|PEKERJAAN|KEWARGANEGARAAN|BERLAKU|RT\s*\/\s*RW)\b',
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

    // 5. Cek apakah seluruh kata dalam nama ada di blacklist
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return false;

    if (words.every((w) => _blacklistedWords.contains(w))) {
      return false; // Contoh: "BELUM KAWIN", "SEUMUR HIDUP", "LAKI LAKI"
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
    var s = raw;
    // Hapus label KTP dan variasi salah baca OCR
    s = s.replaceAll(
      RegExp(r'\b(?:TEMPAT|TENPAT|TEMPATIGL|TEMPATGL|TMP|TGL|TG1|IGL|LAHIR|LAHR|LAKIR)\b', caseSensitive: false),
      ' ',
    );
    // Hapus karakter non huruf seperti simbol atau tanda baca
    s = s.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ');
    // Rapikan spasi ganda
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
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

    // Pola 1: Baris TEMPAT / TGL LAHIR
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('TEMPAT') || upper.contains('LAHIR') || upper.contains('TGL') || upper.contains('IGL')) {
        // Hapus label awal jika ada
        var cleaned = line.replaceFirst(
          RegExp(r'^(?:TEMPAT|TENPAT|TMP)?[\s\/\&\|Iil!1]*(?:TGL|GL|IGL|TG1|TG|1GL|TGI)?[\s\/\&\|Iil!1]*(?:LAHIR|LAHR|LAKIR)?[\s\:\;\-\.]*', caseSensitive: false),
          '',
        ).trim();

        // Cari pola tanggal dd-mm-yyyy / dd/mm/yyyy
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

    // Pola 2: Fallback tanggal lahir dari NIK jika belum terdeteksi dari teks
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
}