import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class BilyetSijakaItem {
  final int id;
  final String noBilyet;
  final String? noPemohonan;
  final String? noAkad;
  final String namaProduk;
  final num nominalModal;
  final num saldoBagihasil;
  final num persenNisbahBulanan;
  final int tenorBulan;
  final int? jumlahBulanDibayar;
  final num? totalBagihasilDiterima;
  final String tglSetor;
  final String tglJatuhTempo;
  final String metodePenyerahanBagihasil;
  final String status;
  final String? noRekeningPencairan;

  BilyetSijakaItem({
    required this.id,
    required this.noBilyet,
    this.noPemohonan,
    this.noAkad,
    required this.namaProduk,
    required this.nominalModal,
    required this.saldoBagihasil,
    required this.persenNisbahBulanan,
    required this.tenorBulan,
    this.jumlahBulanDibayar,
    this.totalBagihasilDiterima,
    required this.tglSetor,
    required this.tglJatuhTempo,
    required this.metodePenyerahanBagihasil,
    required this.status,
    this.noRekeningPencairan,
  });

  bool get isActive => status.toLowerCase() == 'aktif';

  String get formattedModal => AppCurrency.format(nominalModal);
  String get formattedSaldoBagiHasil => AppCurrency.format(saldoBagihasil);
  String get formattedTotalBagiHasil => AppCurrency.format(totalBagihasilDiterima ?? saldoBagihasil);

  String get formattedSetorDate => AppDateFormatter.formatIndoFull(tglSetor);
  String get formattedJatuhTempoDate => AppDateFormatter.formatIndoFull(tglJatuhTempo);

  factory BilyetSijakaItem.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is int) return val;
      if (val == null) return fallback;
      return int.tryParse(val.toString()) ?? fallback;
    }

    return BilyetSijakaItem(
      id: parseInt(json['id']),
      noBilyet: json['no_bilyet']?.toString() ?? 'SJK-${json['id']}',
      noPemohonan: json['no_pemohonan']?.toString(),
      noAkad: json['no_akad']?.toString(),
      namaProduk: json['nama_produk']?.toString() ?? 'Sijaka Mudharabah',
      nominalModal: parseNum(json['nominal_modal']),
      saldoBagihasil: parseNum(json['saldo_bagihasil']),
      persenNisbahBulanan: parseNum(json['persen_nisbah_bulanan']),
      tenorBulan: parseInt(json['tenor_bulan'], 12),
      jumlahBulanDibayar: json['jumlah_bulan_dibayar'] != null ? parseInt(json['jumlah_bulan_dibayar']) : null,
      totalBagihasilDiterima: json['total_bagihasil_diterima'] != null ? parseNum(json['total_bagihasil_diterima']) : null,
      tglSetor: json['tgl_setor']?.toString() ?? '',
      tglJatuhTempo: json['tgl_jatuh_tempo']?.toString() ?? '',
      metodePenyerahanBagihasil: json['metode_penyerahan_bagihasil']?.toString() ?? 'Setiap Bulan',
      status: json['status']?.toString() ?? 'aktif',
      noRekeningPencairan: json['rekening_pencairan']?.toString() ?? json['no_rekening_bank_pencairan']?.toString(),
    );
  }
}

class RiwayatBagiHasilItem {
  final int id;
  final String periode;
  final num modalSijaka;
  final num nominalBagihasil;
  final String createdAt;

  RiwayatBagiHasilItem({
    required this.id,
    required this.periode,
    required this.modalSijaka,
    required this.nominalBagihasil,
    required this.createdAt,
  });

  String get formattedNominal => AppCurrency.format(nominalBagihasil);

  String get formattedDate => AppDateFormatter.formatIndoWithTime(createdAt);

  factory RiwayatBagiHasilItem.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val == null) return 0;
      return int.tryParse(val.toString()) ?? 0;
    }

    return RiwayatBagiHasilItem(
      id: parseInt(json['id']),
      periode: json['periode']?.toString() ?? '',
      modalSijaka: parseNum(json['modal_sijaka']),
      nominalBagihasil: parseNum(json['nominal_bagihasil']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class BilyetSijakaDetail {
  final BilyetSijakaItem bilyet;
  final List<RiwayatBagiHasilItem> riwayatBagihasil;

  BilyetSijakaDetail({
    required this.bilyet,
    required this.riwayatBagihasil,
  });

  factory BilyetSijakaDetail.fromJson(Map<String, dynamic> json) {
    final bilyetJson = json['bilyet'] is Map<String, dynamic>
        ? json['bilyet'] as Map<String, dynamic>
        : json;

    List<RiwayatBagiHasilItem> riwayat = [];
    if (json['riwayat_bagihasil'] is List) {
      riwayat = (json['riwayat_bagihasil'] as List)
          .map((e) => RiwayatBagiHasilItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return BilyetSijakaDetail(
      bilyet: BilyetSijakaItem.fromJson(bilyetJson),
      riwayatBagihasil: riwayat,
    );
  }
}
