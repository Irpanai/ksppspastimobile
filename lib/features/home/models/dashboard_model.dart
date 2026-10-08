class TunggakanItem {
  final int bulan;
  final int tahun;
  final String label;
  final int nominal;

  TunggakanItem({
    required this.bulan,
    required this.tahun,
    required this.label,
    required this.nominal,
  });

  factory TunggakanItem.fromJson(Map<String, dynamic> json) {
    return TunggakanItem(
      bulan: json['bulan'] is int ? json['bulan'] : int.tryParse(json['bulan']?.toString() ?? '0') ?? 0,
      tahun: json['tahun'] is int ? json['tahun'] : int.tryParse(json['tahun']?.toString() ?? '0') ?? 0,
      label: json['label']?.toString() ?? '',
      nominal: json['nominal'] is int ? json['nominal'] : int.tryParse(json['nominal']?.toString() ?? '2500') ?? 2500,
    );
  }
}

class DashboardAnggota {
  final int id;
  final String noAnggota;
  final String nama;
  final String status;
  final String cabang;
  final bool isMenunggak;
  final List<TunggakanItem> tunggakanWajib;
  final int totalTunggakanWajib;
  final int jumlahBulanMenunggak;

  DashboardAnggota({
    required this.id,
    required this.noAnggota,
    required this.nama,
    required this.status,
    required this.cabang,
    this.isMenunggak = false,
    this.tunggakanWajib = const [],
    this.totalTunggakanWajib = 0,
    this.jumlahBulanMenunggak = 0,
  });

  factory DashboardAnggota.fromJson(Map<String, dynamic> json) {
    final rawTunggakan = json['tunggakan_wajib'];
    List<TunggakanItem> tunggakanList = [];
    if (rawTunggakan is List) {
      tunggakanList = rawTunggakan
          .whereType<Map<String, dynamic>>()
          .map((item) => TunggakanItem.fromJson(item))
          .toList();
    }

    final isMenunggakVal = json['is_menunggak'] == true ||
        (json['status']?.toString().toLowerCase() == 'menunggak') ||
        tunggakanList.isNotEmpty;

    return DashboardAnggota(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      noAnggota: json['no_anggota']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      status: json['status']?.toString() ?? 'aktif',
      cabang: json['cabang']?.toString() ?? 'Pusat',
      isMenunggak: isMenunggakVal,
      tunggakanWajib: tunggakanList,
      totalTunggakanWajib: json['total_tunggakan_wajib'] is int
          ? json['total_tunggakan_wajib']
          : int.tryParse(json['total_tunggakan_wajib']?.toString() ?? '0') ?? (tunggakanList.length * 2500),
      jumlahBulanMenunggak: json['jumlah_bulan_menunggak'] is int
          ? json['jumlah_bulan_menunggak']
          : int.tryParse(json['jumlah_bulan_menunggak']?.toString() ?? '0') ?? tunggakanList.length,
    );
  }
}

class RingkasanSaldo {
  final num saldoPokok;
  final num saldoWajib;
  final num saldoSukarela;
  final num saldoSukarelaTersedia;
  final num saldoSukarelaPending;
  final num saldoSijaka;
  final num saldoBagihasilSijaka;
  final num saldoBagihasilTersedia;
  final num saldoBagihasilPending;
  final num totalSimpanan;
  final bool hasPendingPenarikan;

  RingkasanSaldo({
    required this.saldoPokok,
    required this.saldoWajib,
    required this.saldoSukarela,
    num? saldoSukarelaTersedia,
    this.saldoSukarelaPending = 0,
    required this.saldoSijaka,
    required this.saldoBagihasilSijaka,
    num? saldoBagihasilTersedia,
    this.saldoBagihasilPending = 0,
    required this.totalSimpanan,
    this.hasPendingPenarikan = false,
  })  : saldoSukarelaTersedia = saldoSukarelaTersedia ?? saldoSukarela,
        saldoBagihasilTersedia = saldoBagihasilTersedia ?? saldoBagihasilSijaka;

  num get saldoPokokDanWajib => saldoPokok + saldoWajib;

  factory RingkasanSaldo.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    final sukarela = parseNum(json['saldo_sukarela']);
    final sukarelaPending = parseNum(json['saldo_sukarela_pending']);
    final sukarelaTersedia = json['saldo_sukarela_tersedia'] != null
        ? parseNum(json['saldo_sukarela_tersedia'])
        : (sukarela - sukarelaPending > 0 ? sukarela - sukarelaPending : 0);

    final bagihasil = parseNum(json['saldo_bagihasil_sijaka']);
    final bagihasilPending = parseNum(json['saldo_bagihasil_pending']);
    final bagihasilTersedia = json['saldo_bagihasil_tersedia'] != null
        ? parseNum(json['saldo_bagihasil_tersedia'])
        : (bagihasil - bagihasilPending > 0 ? bagihasil - bagihasilPending : 0);

    return RingkasanSaldo(
      saldoPokok: parseNum(json['saldo_pokok']),
      saldoWajib: parseNum(json['saldo_wajib']),
      saldoSukarela: sukarela,
      saldoSukarelaTersedia: sukarelaTersedia,
      saldoSukarelaPending: sukarelaPending,
      saldoSijaka: parseNum(json['saldo_sijaka']),
      saldoBagihasilSijaka: bagihasil,
      saldoBagihasilTersedia: bagihasilTersedia,
      saldoBagihasilPending: bagihasilPending,
      totalSimpanan: parseNum(json['total_simpanan']),
      hasPendingPenarikan: json['has_pending_penarikan'] == true || (sukarelaPending + bagihasilPending) > 0,
    );
  }
}

class DashboardStatistik {
  final int jumlahBilyetSijakaAktif;

  DashboardStatistik({
    required this.jumlahBilyetSijakaAktif,
  });

  factory DashboardStatistik.fromJson(Map<String, dynamic> json) {
    return DashboardStatistik(
      jumlahBilyetSijakaAktif: json['jumlah_bilyet_sijaka_aktif'] is int
          ? json['jumlah_bilyet_sijaka_aktif']
          : int.tryParse(json['jumlah_bilyet_sijaka_aktif']?.toString() ?? '0') ?? 0,
    );
  }
}

class DashboardData {
  final DashboardAnggota? anggota;
  final RingkasanSaldo ringkasanSaldo;
  final DashboardStatistik statistiks;

  DashboardData({
    this.anggota,
    required this.ringkasanSaldo,
    required this.statistiks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      anggota: json['anggota'] != null ? DashboardAnggota.fromJson(json['anggota']) : null,
      ringkasanSaldo: json['ringkasan_saldo'] != null
          ? RingkasanSaldo.fromJson(json['ringkasan_saldo'])
          : RingkasanSaldo(
              saldoPokok: 0,
              saldoWajib: 0,
              saldoSukarela: 0,
              saldoSijaka: 0,
              saldoBagihasilSijaka: 0,
              totalSimpanan: 0,
            ),
      statistiks: json['statistiks'] != null
          ? DashboardStatistik.fromJson(json['statistiks'])
          : DashboardStatistik(jumlahBilyetSijakaAktif: 0),
    );
  }
}
