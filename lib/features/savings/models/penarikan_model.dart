class PenarikanItemModel {
  final int id;
  final String kodeTransaksi;
  final String jenisSimpanan;
  final int nominal;
  final String nominalFormat;
  final int biayaAdmin;
  final String biayaAdminFormat;
  final int nominalTransfer;
  final String nominalTransferFormat;
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
    this.biayaAdmin = 0,
    this.biayaAdminFormat = 'Rp 0',
    this.nominalTransfer = 0,
    this.nominalTransferFormat = '',
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

  bool get isBsi {
    final lower = namaBank.trim().toLowerCase();
    return lower.contains('bsi') || lower.contains('syariah indonesia');
  }

  factory PenarikanItemModel.fromJson(Map<String, dynamic> json) {
    final int parsedNominal = json['nominal'] is int ? json['nominal'] : int.tryParse(json['nominal']?.toString() ?? '0') ?? 0;
    final int parsedBiaya = json['biaya_admin'] is int ? json['biaya_admin'] : int.tryParse(json['biaya_admin']?.toString() ?? '0') ?? 0;
    final int parsedTransfer = json['nominal_transfer'] is int 
        ? json['nominal_transfer'] 
        : int.tryParse(json['nominal_transfer']?.toString() ?? '0') ?? (parsedNominal > parsedBiaya ? parsedNominal - parsedBiaya : 0);

    return PenarikanItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kodeTransaksi: json['kode_transaksi']?.toString() ?? '-',
      jenisSimpanan: json['jenis_simpanan']?.toString() ?? 'sukarela',
      nominal: parsedNominal,
      nominalFormat: json['nominal_format']?.toString() ?? 'Rp $parsedNominal',
      biayaAdmin: parsedBiaya,
      biayaAdminFormat: json['biaya_admin_format']?.toString() ?? 'Rp $parsedBiaya',
      nominalTransfer: parsedTransfer,
      nominalTransferFormat: json['nominal_transfer_format']?.toString() ?? 'Rp $parsedTransfer',
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
  final bool hasPending;
  final PenarikanItemModel? activePending;
  final Map<String, PenarikanItemModel> activePendings;
  final Map<String, dynamic>? ringkasanSaldoTarik;

  PenarikanPaginationModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.hasPending = false,
    this.activePending,
    this.activePendings = const {},
    this.ringkasanSaldoTarik,
  });

  PenarikanItemModel? activePendingFor(String jenisSimpanan) {
    return activePendings[jenisSimpanan];
  }

  factory PenarikanPaginationModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<PenarikanItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => PenarikanItemModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    PenarikanItemModel? active;
    if (json['active_pending'] is Map<String, dynamic>) {
      active = PenarikanItemModel.fromJson(json['active_pending'] as Map<String, dynamic>);
    } else {
      try {
        active = parsedItems.firstWhere((it) => it.isPending);
      } catch (_) {
        active = null;
      }
    }

    final Map<String, PenarikanItemModel> pendingsByJenis = {};
    if (json['active_pendings'] is Map) {
      final rawMap = json['active_pendings'] as Map;
      rawMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          pendingsByJenis[key.toString()] = PenarikanItemModel.fromJson(value);
        }
      });
    } else {
      // Fallback untuk backend lama: kumpulkan pending berdasarkan jenis_simpanan dari items & active_pending
      for (final item in parsedItems) {
        if (item.isPending && !pendingsByJenis.containsKey(item.jenisSimpanan)) {
          pendingsByJenis[item.jenisSimpanan] = item;
        }
      }
      if (active != null && !pendingsByJenis.containsKey(active.jenisSimpanan)) {
        pendingsByJenis[active.jenisSimpanan] = active;
      }
    }

    return PenarikanPaginationModel(
      items: parsedItems,
      currentPage: json['current_page'] is int ? json['current_page'] : 1,
      lastPage: json['last_page'] is int ? json['last_page'] : 1,
      perPage: json['per_page'] is int ? json['per_page'] : 15,
      total: json['total'] is int ? json['total'] : parsedItems.length,
      hasPending: json['has_pending'] == true || active != null || pendingsByJenis.isNotEmpty,
      activePending: active,
      activePendings: pendingsByJenis,
      ringkasanSaldoTarik: json['ringkasan_saldo_tarik'] as Map<String, dynamic>?,
    );
  }
}
