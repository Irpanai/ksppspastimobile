class TerbilangFormatter {
  static String format(num number) {
    if (number == 0) return 'Nol Rupiah';

    final numStrings = [
      '', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh', 'Sebelas'
    ];

    String _terbilang(num n) {
      if (n < 12) {
        return numStrings[n.toInt()];
      } else if (n < 20) {
        return '${_terbilang(n - 10)} Belas';
      } else if (n < 100) {
        return '${_terbilang(n ~/ 10)} Puluh ${_terbilang(n % 10)}'.trim();
      } else if (n < 200) {
        return 'Seratus ${_terbilang(n - 100)}'.trim();
      } else if (n < 1000) {
        return '${_terbilang(n ~/ 100)} Ratus ${_terbilang(n % 100)}'.trim();
      } else if (n < 2000) {
        return 'Seribu ${_terbilang(n - 1000)}'.trim();
      } else if (n < 1000000) {
        return '${_terbilang(n ~/ 1000)} Ribu ${_terbilang(n % 1000)}'.trim();
      } else if (n < 1000000000) {
        return '${_terbilang(n ~/ 1000000)} Juta ${_terbilang(n % 1000000)}'.trim();
      } else if (n < 1000000000000) {
        return '${_terbilang(n ~/ 1000000000)} Miliar ${_terbilang(n % 1000000000)}'.trim();
      } else {
        return '${_terbilang(n ~/ 1000000000000)} Triliun ${_terbilang(n % 1000000000000)}'.trim();
      }
    }

    return '${_terbilang(number)} Rupiah';
  }
}
