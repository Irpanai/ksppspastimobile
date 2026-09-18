class DashboardAnggota {
  final int id;
  final String noAnggota;
  final String nama;
  final String status;
  final String cabang;

  DashboardAnggota({
    required this.id,
    required this.noAnggota,
    required this.nama,
    required this.status,
    required this.cabang,
  });

  factory DashboardAnggota.fromJson(Map<String, dynamic> json) {
    return DashboardAnggota(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      noAnggota: json['no_anggota']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      status: json['status']?.toString() ?? 'aktif',
      cabang: json['cabang']?.toString() ?? 'Pusat',
    );
  }
}

class RingkasanSaldo {
  final num saldoPokok;
  final num saldoWajib;
  final num saldoSukarela;
  final num saldoSijaka;
  final num saldoBagihasilSijaka;
  final num totalSimpanan;

  RingkasanSaldo({
    required this.saldoPokok,
    required this.saldoWajib,
    required this.saldoSukarela,
    required this.saldoSijaka,
    required this.saldoBagihasilSijaka,
    required this.totalSimpanan,
  });

  num get saldoPokokDanWajib => saldoPokok + saldoWajib;

  factory RingkasanSaldo.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    return RingkasanSaldo(
      saldoPokok: parseNum(json['saldo_pokok']),
      saldoWajib: parseNum(json['saldo_wajib']),
      saldoSukarela: parseNum(json['saldo_sukarela']),
      saldoSijaka: parseNum(json['saldo_sijaka']),
      saldoBagihasilSijaka: parseNum(json['saldo_bagihasil_sijaka']),
      totalSimpanan: parseNum(json['total_simpanan']),
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
