class PenarikanItemModel {
  final int id;
  final String kodeTransaksi;
  final String jenisSimpanan;
  final int nominal;
  final String nominalFormat;
  final String metodePenarikan;
  final String namaBank;
  final String noRekening;
  final String atasNama;
  final String status;
  final String statusLabel;
  final String? catatanAnggota;
  final String? catatanFinance;
  final String? approvedAt;
  final String tglPengajuan;

  PenarikanItemModel({
    required this.id,
    required this.kodeTransaksi,
    required this.jenisSimpanan,
    required this.nominal,
    required this.nominalFormat,
    required this.metodePenarikan,
    required this.namaBank,
    required this.noRekening,
    required this.atasNama,
    required this.status,
    required this.statusLabel,
    this.catatanAnggota,
    this.catatanFinance,
    this.approvedAt,
    required this.tglPengajuan,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PenarikanItemModel.fromJson(Map<String, dynamic> json) {
    return PenarikanItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kodeTransaksi: json['kode_transaksi']?.toString() ?? '-',
      jenisSimpanan: json['jenis_simpanan']?.toString() ?? 'sukarela',
      nominal: json['nominal'] is int ? json['nominal'] : int.tryParse(json['nominal']?.toString() ?? '0') ?? 0,
      nominalFormat: json['nominal_format']?.toString() ?? '',
      metodePenarikan: json['metode_penarikan']?.toString() ?? 'transfer_bank',
      namaBank: json['nama_bank']?.toString() ?? '',
      noRekening: json['no_rekening']?.toString() ?? '',
      atasNama: json['atas_nama']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Menunggu Transfer',
      catatanAnggota: json['catatan_anggota']?.toString(),
      catatanFinance: json['catatan_finance']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
    );
  }
}

class PenarikanPaginationModel {
  final List<PenarikanItemModel> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PenarikanPaginationModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PenarikanPaginationModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<PenarikanItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => PenarikanItemModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return PenarikanPaginationModel(
      items: parsedItems,
      currentPage: json['current_page'] is int ? json['current_page'] : 1,
      lastPage: json['last_page'] is int ? json['last_page'] : 1,
      perPage: json['per_page'] is int ? json['per_page'] : 15,
      total: json['total'] is int ? json['total'] : parsedItems.length,
    );
  }
}
