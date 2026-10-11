class PengunduranDiriStatusModel {
  final String statusAnggota;
  final bool isKeluar;
  final bool hasPending;
  final String konfirmasiTeksWajib;
  final PengajuanPendingItem? pendingPengajuan;
  final List<PengajuanRiwayatItem> riwayat;
  final RingkasanSaldoPengunduran ringkasanSaldo;

  PengunduranDiriStatusModel({
    required this.statusAnggota,
    required this.isKeluar,
    required this.hasPending,
    required this.konfirmasiTeksWajib,
    this.pendingPengajuan,
    required this.riwayat,
    required this.ringkasanSaldo,
  });

  factory PengunduranDiriStatusModel.fromJson(Map<String, dynamic> json) {
    return PengunduranDiriStatusModel(
      statusAnggota: json['status_anggota'] ?? 'aktif',
      isKeluar: json['is_keluar'] ?? false,
      hasPending: json['has_pending'] ?? false,
      konfirmasiTeksWajib: json['konfirmasi_teks_wajib'] ?? 'SAYA YAKIN UNTUK MENGUNDURKAN DIRI',
      pendingPengajuan: json['pengajuan_pending'] != null
          ? PengajuanPendingItem.fromJson(json['pengajuan_pending'])
          : null,
      riwayat: (json['riwayat'] as List<dynamic>?)
              ?.map((item) => PengajuanRiwayatItem.fromJson(item))
              .toList() ??
          [],
      ringkasanSaldo: RingkasanSaldoPengunduran.fromJson(
        json['ringkasan_saldo'] ?? {},
      ),
    );
  }
}

class PengajuanPendingItem {
  final int id;
  final String status;
  final String? createdAt;
  final String? catatan;

  PengajuanPendingItem({
    required this.id,
    required this.status,
    this.createdAt,
    this.catatan,
  });

  factory PengajuanPendingItem.fromJson(Map<String, dynamic> json) {
    return PengajuanPendingItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'],
      catatan: json['catatan'],
    );
  }
}

class PengajuanRiwayatItem {
  final int id;
  final String status;
  final String? createdAt;
  final String? approvedAt;
  final String? catatan;

  PengajuanRiwayatItem({
    required this.id,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.catatan,
  });

  factory PengajuanRiwayatItem.fromJson(Map<String, dynamic> json) {
    return PengajuanRiwayatItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'],
      approvedAt: json['approved_at'],
      catatan: json['catatan'],
    );
  }
}

class RingkasanSaldoPengunduran {
  final double saldoPokok;
  final double saldoWajib;
  final double saldoSukarela;
  final double saldoSijaka;
  final double totalKembali;

  RingkasanSaldoPengunduran({
    required this.saldoPokok,
    required this.saldoWajib,
    required this.saldoSukarela,
    required this.saldoSijaka,
    required this.totalKembali,
  });

  factory RingkasanSaldoPengunduran.fromJson(Map<String, dynamic> json) {
    return RingkasanSaldoPengunduran(
      saldoPokok: (json['saldo_pokok'] as num?)?.toDouble() ?? 0.0,
      saldoWajib: (json['saldo_wajib'] as num?)?.toDouble() ?? 0.0,
      saldoSukarela: (json['saldo_sukarela'] as num?)?.toDouble() ?? 0.0,
      saldoSijaka: (json['saldo_sijaka'] as num?)?.toDouble() ?? 0.0,
      totalKembali: (json['total_kembali'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
