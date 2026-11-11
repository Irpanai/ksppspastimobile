import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/rich_article_viewer.dart';

class PromoModel {
  final int id;
  final String judul;
  final String tipe;
  final String? gambarBanner;
  final String? deskripsi;
  final String? tanggalMulai;
  final String? tanggalBerakhir;
  final String? createdAt;

  PromoModel({
    required this.id,
    required this.judul,
    required this.tipe,
    this.gambarBanner,
    this.deskripsi,
    this.tanggalMulai,
    this.tanggalBerakhir,
    this.createdAt,
  });

  bool get isPromo => tipe.toLowerCase() == 'promo';
  bool get isInfo => tipe.toLowerCase() == 'info';

  /// Cuplikan teks bersih (tanpa tag HTML / kode tabel) untuk pratinjau kartu.
  String get plainTextPreview => stripHtmlToPlainText(deskripsi);

  /// Resolves the banner image to an active URL (CORS / host-aware)
  String? get fullGambarUrl => ApiConstants.resolveImageUrl(gambarBanner);

  /// Memeriksa apakah konten sedang berada di dalam rentang tanggal tayang [tanggalMulai .. tanggalBerakhir].
  static DateTime? parseDateOnly(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final ymdMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
    if (ymdMatch != null) {
      final y = int.tryParse(ymdMatch.group(1)!);
      final m = int.tryParse(ymdMatch.group(2)!);
      final d = int.tryParse(ymdMatch.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool isCurrentlyVisibleOn([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = parseDateOnly(tanggalMulai);
    if (start != null && today.isBefore(start)) {
      return false;
    }

    final end = parseDateOnly(tanggalBerakhir);
    if (end != null && today.isAfter(end)) {
      return false;
    }

    return true;
  }

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      tipe: json['tipe'] ?? 'promo',
      gambarBanner: ApiConstants.resolveImageUrl(json['gambar_banner']),
      deskripsi: json['deskripsi'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalBerakhir: json['tanggal_berakhir'],
      createdAt: json['created_at'],
    );
  }
}

