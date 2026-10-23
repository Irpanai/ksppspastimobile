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

  // Kata kunci label/sistem KTP yang bukan merupakan nama orang
  static const List<String> _ktpKeywords = [
    'PROVINSI', 'KABUPATEN', 'KOTA', 'REPUBLIK', 'INDONESIA',
    'NIK', 'N1K', 'N I K', 'KIK', 'KTP', 'NAMA', 'NARNA',
    'TEMPAT', 'TGL', 'LAHIR', 'JENIS', 'KELAMIN', 'GOL',
    'DARAH', 'ALAMAT', 'RT', 'RW', 'KEL', 'DESA', 'KECAMATAN',
    'AGAMA', 'STATUS', 'PERKAWINAN', 'PEKERJAAN', 'KEWARGANEGARAAN',
    'WNI', 'WNA', 'BERLAKU', 'HINGGA', 'SEUMUR', 'HIDUP',
    'ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA', 'KONGHUCU',
    'LAKI-LAKI', 'PEREMPUAN', 'BELUM', 'KAWIN', 'CERAI',
    'PEGAWAI', 'SWASTA', 'WIRASWASTA', 'PELAJAR', 'MAHASISWA',
    'BURUH', 'PETANI', 'PETERNAK', 'PEDAGANG', 'TNI', 'POLRI', 'PNS'
  ];

  /// Memproses recognizedText dari ML Kit untuk mengekstrak NIK dan Nama secara cerdas
  static KtpOcrResult parse(RecognizedText recognizedText) {
    final List<String> lines = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
        }
      }
    }

    final rawText = recognizedText.text;
    final nik = _extractNik(lines, rawText);
    final nama = _extractNama(lines, rawText, nik);

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

  static String? _extractNik(List<String> lines, String rawText) {
    // 1. Cek langsung baris yang memiliki kata kunci NIK / N1K / KIK
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
        // Cari substring 16 digit yang diawali kode provinsi valid
        for (int j = 0; j <= cleaned.length - 16; j++) {
          final sub = cleaned.substring(j, j + 16);
          if (_isValidProvince(sub)) return sub;
        }
      }
    }

    // 4. Fallback pola berjarak (misal: 3201 0244 0592 0001 atau 3201-0244-0592-0001)
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
    // Hapus label "NIK", "N1K", "N I K", "KIK", ":", dll
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

  static String? _extractNama(List<String> lines, String rawText, String? foundNik) {
    // 1. Cari baris yang mengandung "Nama" / "NAMA" / "Narna"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      if (upper.startsWith('NAMA') ||
          upper.startsWith('NARNA') ||
          upper.startsWith('NAME') ||
          upper.contains('NAMA :') ||
          upper.contains('NAMA:') ||
          upper.contains('NARNA :')) {

        String candidate = '';
        if (line.contains(':')) {
          candidate = line.substring(line.indexOf(':') + 1).trim();
        } else {
          candidate = line.replaceFirst(
            RegExp(r'^(?:NAMA|NARNA|NAME|NAM A|N A M A)[\W_]*', caseSensitive: false),
            '',
          ).trim();
        }

        candidate = _cleanCandidateNama(candidate);

        // Jika valid di baris yang sama, langsung kembalikan
        if (_isValidNama(candidate)) {
          return candidate;
        }

        // Jika barisnya hanya berisi "Nama :" (kosong), cek baris berikutnya!
        if (i + 1 < lines.length) {
          final nextCandidate = _cleanCandidateNama(lines[i + 1]);
          if (_isValidNama(nextCandidate)) {
            return nextCandidate;
          }
        }
      }
    }

    // 2. Heuristik Posisi: Pada KTP, Nama berada 1-2 baris tepat di bawah NIK!
    if (foundNik != null) {
      int nikIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(foundNik) || normalizeOcrDigits(lines[i]).contains(foundNik)) {
          nikIndex = i;
          break;
        }
      }

      if (nikIndex != -1) {
        for (int i = nikIndex + 1; i <= nikIndex + 2 && i < lines.length; i++) {
          final candidate = _cleanCandidateNama(lines[i]);
          if (_isValidNama(candidate)) {
            return candidate;
          }
        }
      }
    }

    // 3. Fallback Regex baris nama (huruf kapital 2 kata atau lebih yang bukan label KTP)
    for (final line in lines) {
      final candidate = _cleanCandidateNama(line);
      if (_isValidNama(candidate)) {
        final words = candidate.split(' ').where((w) => w.length >= 2).toList();
        if (words.length >= 2 &&
            !candidate.contains('PROVINSI') &&
            !candidate.contains('KABUPATEN') &&
            !candidate.contains('KOTA')) {
          return candidate;
        }
      }
    }

    return null;
  }

  static String _cleanCandidateNama(String raw) {
    String text = raw;

    // Potong jika menempel dengan field berikutnya (Tempat/Tgl Lahir, Jenis Kelamin, dll)
    final stopWords = [
      'TEMPAT', 'TMP', 'TGL', 'LAHIR', 'JENIS', 'KELAMIN',
      'GOL', 'DARAH', 'ALAMAT', 'AGAMA', 'STATUS', 'RT/RW', 'RT', 'RW',
      'KEL/DESA', 'KECAMATAN', 'PEKERJAAN', 'KEWARGANEGARAAN'
    ];

    for (final sw in stopWords) {
      final idx = text.toUpperCase().indexOf(sw);
      if (idx != -1) {
        text = text.substring(0, idx);
      }
    }

    // Hapus simbol/angka di awal
    text = text.replaceAll(RegExp(r'^[\W\d_]+'), '');
    // Hapus simbol/angka di akhir
    text = text.replaceAll(RegExp(r'[\W\d_]+$'), '');
    // Hapus kata NAMA jika masih tersisa
    text = text.replaceFirst(RegExp(r'^(?:NAMA|NARNA|NAME)[\W_]*', caseSensitive: false), '');

    // Pertahankan hanya huruf alfabet, spasi, titik (singkatan), petik satu (nama arab/daerah), dan tanda hubung
    text = text.replaceAll(RegExp(r"[^a-zA-Z\s\.'\-]"), ' ');
    // Rapikan spasi ganda
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text.toUpperCase();
  }

  static bool _isValidNama(String name) {
    final clean = name.trim();
    if (clean.length < 3 || clean.length > 50) return false;

    // Wajib ada huruf vokal
    if (!RegExp(r'[AEIOUaeiou]').hasMatch(clean)) return false;

    // Tidak boleh hanya kata kunci label KTP
    final upper = clean.toUpperCase();
    for (final kw in _ktpKeywords) {
      if (upper == kw) return false;
    }

    // Tidak boleh berupa header wilayah
    if (upper.startsWith('PROVINSI') ||
        upper.startsWith('KABUPATEN') ||
        upper.startsWith('KOTA') ||
        upper.startsWith('REPUBLIK') ||
        upper.startsWith('INDONESIA')) {
      return false;
    }

    // Harus mengandung karakter alfabet
    if (!RegExp(r'[A-Za-z]').hasMatch(clean)) return false;

    return true;
  }
}