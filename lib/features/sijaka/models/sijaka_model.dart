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

  int get calculatedBulanBerjalan {
    if (tglSetor.isEmpty) return 0;
    
    try {
      final startDate = DateTime.parse(tglSetor);
      final now = DateTime.now();
      
      int months = (now.year - startDate.year) * 12 + now.month - startDate.month;
      if (now.day < startDate.day) {
        months--;
      }
      return months < 0 ? 0 : months;
    } catch (e) {
      return 0;
    }
  }

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
  final String? periodeLabel;
  final num modalSijaka;
  final num nominalBagihasil;
  final String? noTransaksi;
  final String? tanggalTransaksi;
  final String? tanggalTransaksiJam;
  final String? namaAnggota;
  final String? noAnggota;
  final String? jenisTransaksi;
  final String? rekeningSumber;
  final String? bankTujuan;
  final String? noRekTujuan;
  final String? namaRekTujuan;
  final String? keterangan;
  final String? status;
  final String createdAt;

  RiwayatBagiHasilItem({
    required this.id,
    required this.periode,
    this.periodeLabel,
    required this.modalSijaka,
    required this.nominalBagihasil,
    this.noTransaksi,
    this.tanggalTransaksi,
    this.tanggalTransaksiJam,
    this.namaAnggota,
    this.noAnggota,
    this.jenisTransaksi,
    this.rekeningSumber,
    this.bankTujuan,
    this.noRekTujuan,
    this.namaRekTujuan,
    this.keterangan,
    this.status,
    required this.createdAt,
  });

  String get formattedNominal => AppCurrency.format(nominalBagihasil);

  String get formattedDate => tanggalTransaksiJam?.isNotEmpty == true 
      ? tanggalTransaksiJam! 
      : AppDateFormatter.formatIndoWithTime(createdAt);

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
      periodeLabel: json['periode_label']?.toString(),
      modalSijaka: parseNum(json['modal_sijaka']),
      nominalBagihasil: parseNum(json['nominal_bagihasil']),
      noTransaksi: json['no_transaksi']?.toString(),
      tanggalTransaksi: json['tanggal_transaksi']?.toString(),
      tanggalTransaksiJam: json['tanggal_transaksi_jam']?.toString(),
      namaAnggota: json['nama_anggota']?.toString(),
      noAnggota: json['no_anggota']?.toString(),
      jenisTransaksi: json['jenis_transaksi']?.toString(),
      rekeningSumber: json['rekening_sumber']?.toString(),
      bankTujuan: json['bank_tujuan']?.toString(),
      noRekTujuan: json['no_rek_tujuan']?.toString(),
      namaRekTujuan: json['nama_rek_tujuan']?.toString(),
      keterangan: json['keterangan']?.toString(),
      status: json['status']?.toString(),
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

class SijakaProdukItem {
  final int id;
  final String namaProduk;
  final int tenorBulan;
  final num persenNisbahTotal;
  final num persenNisbahBulanan;
  final num minimalSetoran;
  final String? minimalSetoranFormat;
  final int? tglSetorTerakhir;
  final String status;

  SijakaProdukItem({
    required this.id,
    required this.namaProduk,
    required this.tenorBulan,
    required this.persenNisbahTotal,
    required this.persenNisbahBulanan,
    required this.minimalSetoran,
    this.minimalSetoranFormat,
    this.tglSetorTerakhir,
    required this.status,
  });

  bool get isActive => status.toLowerCase() == 'aktif';

  String get formattedMinimalSetoran =>
      minimalSetoranFormat ?? AppCurrency.format(minimalSetoran);

  num hitungBagiHasilBulanan(num nominal) {
    return (nominal * persenNisbahBulanan) / 100;
  }

  num hitungTotalBagiHasil(num nominal) {
    if (persenNisbahTotal > 0) {
      return (nominal * persenNisbahTotal) / 100;
    }
    return hitungBagiHasilBulanan(nominal) * tenorBulan;
  }

  factory SijakaProdukItem.fromJson(Map<String, dynamic> json) {
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

    return SijakaProdukItem(
      id: parseInt(json['id']),
      namaProduk: json['nama_produk']?.toString() ?? 'Sijaka',
      tenorBulan: parseInt(json['tenor_bulan'], 1),
      persenNisbahTotal: parseNum(json['persen_nisbah_total']),
      persenNisbahBulanan: parseNum(json['persen_nisbah_bulanan']),
      minimalSetoran: parseNum(json['minimal_setoran']),
      minimalSetoranFormat: json['minimal_setoran_format']?.toString(),
      tglSetorTerakhir: json['tgl_setor_terakhir'] != null
          ? parseInt(json['tgl_setor_terakhir'])
          : null,
      status: json['status']?.toString() ?? 'aktif',
    );
  }
}

