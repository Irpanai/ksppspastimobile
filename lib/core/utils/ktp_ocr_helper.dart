import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KtpOcrResult {
  final String? nik;
  final String? nama;
  final String? rawText;
  final bool isSuccess;

  const KtpOcrResult({
    this.nik,
    this.nama,
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

    return KtpOcrResult(
      nik: nik,
      nama: nama,
      rawText: rawText,
      isSuccess: (nik != null && nik.isNotEmpty) || (nama != null && nama.isNotEmpty),
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
}