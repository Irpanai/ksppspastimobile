import 'package:intl/intl.dart';

class AppDateFormatter {
  static const List<String> _namaBulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _namaBulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Format date to "27 Agustus 2026"
  static String formatIndoFull(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day} ${_namaBulanIndo[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date to "27 Agu 2026"
  static String formatIndoShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day} ${_namaBulanSingkat[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date to "27 Agustus 2026, 16:00"
  static String formatIndoWithTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${_namaBulanIndo[dt.month - 1]} ${dt.year}, $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }
}
