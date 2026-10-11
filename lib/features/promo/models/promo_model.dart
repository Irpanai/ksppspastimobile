import '../../../core/constants/api_constants.dart';

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

  /// Resolves the banner image to an active URL (CORS / host-aware)
  String? get fullGambarUrl => ApiConstants.resolveImageUrl(gambarBanner);

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

