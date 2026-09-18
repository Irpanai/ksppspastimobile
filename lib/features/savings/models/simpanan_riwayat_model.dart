import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class MutasiSimpananItem {
  final int id;
  final String jenis;
  final String tipe;
  final num nominal;
  final int? bulan;
  final int? tahun;
  final String keterangan;
  final String tglTransaksi;

  MutasiSimpananItem({
    required this.id,
    required this.jenis,
    required this.tipe,
    required this.nominal,
    this.bulan,
    this.tahun,
    required this.keterangan,
    required this.tglTransaksi,
  });

  bool get isMasuk {
    final t = tipe.toLowerCase();
    return t == 'setor' || t == 'masuk' || t == 'kredit' || t == 'pencairan' || t == 'bagihasil';
  }

  String get formattedNominal {
    final prefix = isMasuk ? '+ ' : '- ';
    return '$prefix${AppCurrency.format(nominal)}';
  }

  String get formattedDate => AppDateFormatter.formatIndoWithTime(tglTransaksi);

  factory MutasiSimpananItem.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    int? parseInt(dynamic val) {
      if (val is int) return val;
      if (val == null) return null;
      return int.tryParse(val.toString());
    }

    return MutasiSimpananItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jenis: json['jenis']?.toString().toLowerCase() ?? '',
      tipe: json['tipe']?.toString().toLowerCase() ?? 'setor',
      nominal: parseNum(json['nominal']),
      bulan: parseInt(json['bulan']),
      tahun: parseInt(json['tahun']),
      keterangan: json['keterangan']?.toString() ?? 'Transaksi Simpanan',
      tglTransaksi: json['tgl_transaksi']?.toString() ?? '',
    );
  }
}

class SimpananRiwayatPagination {
  final List<MutasiSimpananItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  SimpananRiwayatPagination({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory SimpananRiwayatPagination.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 1]) {
      if (val is int) return val;
      if (val == null) return fallback;
      return int.tryParse(val.toString()) ?? fallback;
    }

    List<MutasiSimpananItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => MutasiSimpananItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SimpananRiwayatPagination(
      items: parsedItems,
      currentPage: parseInt(json['current_page'], 1),
      lastPage: parseInt(json['last_page'], 1),
      perPage: parseInt(json['per_page'], 15),
      total: parseInt(json['total'], parsedItems.length),
    );
  }
}
