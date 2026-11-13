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

  Map<String, dynamic> toJson() {
    return {
      'bulan': bulan,
      'tahun': tahun,
      'label': label,
      'nominal': nominal,
    };
  }
}

class MemberStatusResolver {
  final bool isPokokPaid;
  final bool isWajibPaid;
  final bool isActive;
  final String displayStatus;

  const MemberStatusResolver({
    required this.isPokokPaid,
    required this.isWajibPaid,
    required this.isActive,
    required this.displayStatus,
  });

  static MemberStatusResolver resolve({
    num? saldoPokok,
    num? saldoWajib,
    bool? apiIsPokokPaid,
    bool? apiIsWajibPaid,
    String? rawStatus,
  }) {
    final normalizedRaw = (rawStatus ?? '').trim().toLowerCase();
    if (normalizedRaw == 'keluar') {
      return const MemberStatusResolver(
        isPokokPaid: false,
        isWajibPaid: false,
        isActive: false,
        displayStatus: 'KELUAR',
      );
    }

    final bool hasBalanceData = saldoPokok != null && saldoWajib != null;
    final bool effectivePokokPaid = hasBalanceData
        ? saldoPokok > 0
        : (apiIsPokokPaid ?? (normalizedRaw == 'aktif'));
    final bool effectiveWajibPaid = hasBalanceData
        ? saldoWajib > 0
        : (apiIsWajibPaid ?? (normalizedRaw == 'aktif'));

    if (!effectivePokokPaid ||
        !effectiveWajibPaid ||
        normalizedRaw == 'belum_aktif' ||
        normalizedRaw == 'nonaktif') {
      return MemberStatusResolver(
        isPokokPaid: effectivePokokPaid,
        isWajibPaid: effectiveWajibPaid,
        isActive: false,
        displayStatus: 'BELUM AKTIF',
      );
    }

    if (normalizedRaw == 'menunggak') {
      return MemberStatusResolver(
        isPokokPaid: effectivePokokPaid,
        isWajibPaid: effectiveWajibPaid,
        isActive: false,
        displayStatus: 'MENUNGGAK',
      );
    }

    return MemberStatusResolver(
      isPokokPaid: effectivePokokPaid,
      isWajibPaid: effectiveWajibPaid,
      isActive: true,
      displayStatus: 'AKTIF',
    );
  }
}

class DashboardAnggota {
  final int id;
  final String noAnggota;
  final String nama;
  final String status;
  final String statusKeanggotaan;
  final bool isPokokPaid;
  final bool isWajibPaid;
  final bool isMemberActive;
  final String cabang;
  final bool isMenunggak;
  final List<TunggakanItem> tunggakanWajib;
  final int totalTunggakanWajib;
  final int jumlahBulanMenunggak;
  final DateTime? tanggalDaftar;
  final int? bulanDaftar;
  final int? tahunDaftar;
  final List<Map<String, int>> wajibTerbayar;

  DashboardAnggota({
    required this.id,
    required this.noAnggota,
    required this.nama,
    required this.status,
    String? statusKeanggotaan,
    bool? isPokokPaid,
    bool? isWajibPaid,
    bool? isMemberActive,
    required this.cabang,
    this.isMenunggak = false,
    this.tunggakanWajib = const [],
    this.totalTunggakanWajib = 0,
    this.jumlahBulanMenunggak = 0,
    this.tanggalDaftar,
    this.bulanDaftar,
    this.tahunDaftar,
    this.wajibTerbayar = const [],
  })  : statusKeanggotaan = statusKeanggotaan ?? status,
        isPokokPaid = isPokokPaid ?? (status.toLowerCase() == 'aktif'),
        isWajibPaid = isWajibPaid ?? (status.toLowerCase() == 'aktif'),
        isMemberActive = isMemberActive ??
            ((isPokokPaid ?? (status.toLowerCase() == 'aktif')) &&
                (isWajibPaid ?? (status.toLowerCase() == 'aktif')) &&
                status.toLowerCase() == 'aktif');

  /// Apakah bulan tertentu berada sebelum tanggal anggota terdaftar di KSPPS PASTI
  bool isBeforeRegistration(int bulan, int tahun) {
    final tgl = tanggalDaftar;
    final bDaftar = bulanDaftar ?? (tgl?.month ?? (tunggakanWajib.isNotEmpty ? tunggakanWajib.first.bulan : null));
    final tDaftar = tahunDaftar ?? (tgl?.year ?? (tunggakanWajib.isNotEmpty ? tunggakanWajib.first.tahun : null));
    if (bDaftar == null || tDaftar == null) return false;
    if (tahun < tDaftar) return true;
    if (tahun == tDaftar && bulan < bDaftar) return true;
    return false;
  }

  /// Apakah bulan tertentu sudah lunas dibayar
  bool isMonthPaid(int bulan, int tahun, {required DateTime now}) {
    if (isBeforeRegistration(bulan, tahun)) return false;
    // Cek di list transaksi wajib terbayar
    if (wajibTerbayar.any((item) => item['bulan'] == bulan && item['tahun'] == tahun)) {
      return true;
    }
    // Jika tidak menunggak dan periode sudah lewat atau bulan berjalan
    final isTunggakan = tunggakanWajib.any((t) => t.bulan == bulan && t.tahun == tahun);
    if (!isTunggakan) {
      if (tahun < now.year) return true;
      if (tahun == now.year && bulan < now.month) return true;
      if (tahun == now.year && bulan == now.month && isWajibPaid) return true;
    }
    return false;
  }

  factory DashboardAnggota.fromJson(Map<String, dynamic> json) {
    final rawTunggakan = json['tunggakan_wajib'];
    List<TunggakanItem> tunggakanList = [];
    if (rawTunggakan is List) {
      tunggakanList = rawTunggakan
          .whereType<Map<String, dynamic>>()
          .map((item) => TunggakanItem.fromJson(item))
          .toList();
    }

    bool parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

    final statusStr = json['status']?.toString() ?? json['status_keanggotaan']?.toString() ?? 'belum_aktif';
    final hasPokokFlag = json.containsKey('is_pokok_paid') && json['is_pokok_paid'] != null;
    final hasWajibFlag = json.containsKey('is_wajib_paid') && json['is_wajib_paid'] != null;
    final hasActiveFlag = json.containsKey('is_member_active') && json['is_member_active'] != null;

    final parsedPokokPaid = hasPokokFlag ? parseBool(json['is_pokok_paid']) : (statusStr.toLowerCase() == 'aktif');
    final parsedWajibPaid = hasWajibFlag ? parseBool(json['is_wajib_paid']) : (statusStr.toLowerCase() == 'aktif');
    final parsedMemberActive = hasActiveFlag
        ? parseBool(json['is_member_active'])
        : (parsedPokokPaid && parsedWajibPaid && statusStr.toLowerCase() == 'aktif');

    final isMenunggakVal = parsedPokokPaid &&
        parsedWajibPaid &&
        (json['is_menunggak'] == true ||
            (statusStr.toLowerCase() == 'menunggak') ||
            tunggakanList.isNotEmpty);

    final tglDaftarStr = json['tanggal_daftar']?.toString() ?? json['created_at']?.toString();
    final parsedTanggalDaftar = tglDaftarStr != null ? DateTime.tryParse(tglDaftarStr) : null;
    final parsedBulanDaftar = json['bulan_daftar'] is int
        ? json['bulan_daftar'] as int
        : (int.tryParse(json['bulan_daftar']?.toString() ?? '') ?? parsedTanggalDaftar?.month);
    final parsedTahunDaftar = json['tahun_daftar'] is int
        ? json['tahun_daftar'] as int
        : (int.tryParse(json['tahun_daftar']?.toString() ?? '') ?? parsedTanggalDaftar?.year);

    final rawWajibTerbayar = json['wajib_terbayar'];
    List<Map<String, int>> terbayarList = [];
    if (rawWajibTerbayar is List) {
      for (final item in rawWajibTerbayar) {
        if (item is Map) {
          final b = item['bulan'] is int ? item['bulan'] as int : int.tryParse(item['bulan']?.toString() ?? '') ?? 0;
          final t = item['tahun'] is int ? item['tahun'] as int : int.tryParse(item['tahun']?.toString() ?? '') ?? 0;
          if (b > 0 && t > 0) {
            terbayarList.add({'bulan': b, 'tahun': t});
          }
        }
      }
    }

    return DashboardAnggota(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      noAnggota: json['no_anggota']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      status: statusStr,
      statusKeanggotaan: json['status_keanggotaan']?.toString() ?? statusStr,
      isPokokPaid: parsedPokokPaid,
      isWajibPaid: parsedWajibPaid,
      isMemberActive: parsedMemberActive,
      cabang: json['cabang']?.toString() ?? 'Pusat',
      isMenunggak: isMenunggakVal,
      tunggakanWajib: tunggakanList,
      totalTunggakanWajib: json['total_tunggakan_wajib'] is int
          ? json['total_tunggakan_wajib']
          : int.tryParse(json['total_tunggakan_wajib']?.toString() ?? '0') ?? (tunggakanList.length * 2500),
      jumlahBulanMenunggak: json['jumlah_bulan_menunggak'] is int
          ? json['jumlah_bulan_menunggak']
          : int.tryParse(json['jumlah_bulan_menunggak']?.toString() ?? '0') ?? tunggakanList.length,
      tanggalDaftar: parsedTanggalDaftar,
      bulanDaftar: parsedBulanDaftar,
      tahunDaftar: parsedTahunDaftar,
      wajibTerbayar: terbayarList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_anggota': noAnggota,
      'nama': nama,
      'status': status,
      'status_keanggotaan': statusKeanggotaan,
      'is_pokok_paid': isPokokPaid,
      'is_wajib_paid': isWajibPaid,
      'is_member_active': isMemberActive,
      'cabang': cabang,
      'is_menunggak': isMenunggak,
      'tunggakan_wajib': tunggakanWajib.map((e) => e.toJson()).toList(),
      'total_tunggakan_wajib': totalTunggakanWajib,
      'jumlah_bulan_menunggak': jumlahBulanMenunggak,
      'tanggal_daftar': tanggalDaftar?.toIso8601String(),
      'bulan_daftar': bulanDaftar,
      'tahun_daftar': tahunDaftar,
      'wajib_terbayar': wajibTerbayar,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'saldo_pokok': saldoPokok,
      'saldo_wajib': saldoWajib,
      'saldo_sukarela': saldoSukarela,
      'saldo_sukarela_tersedia': saldoSukarelaTersedia,
      'saldo_sukarela_pending': saldoSukarelaPending,
      'saldo_sijaka': saldoSijaka,
      'saldo_bagihasil_sijaka': saldoBagihasilSijaka,
      'saldo_bagihasil_tersedia': saldoBagihasilTersedia,
      'saldo_bagihasil_pending': saldoBagihasilPending,
      'total_simpanan': totalSimpanan,
      'has_pending_penarikan': hasPendingPenarikan,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'jumlah_bilyet_sijaka_aktif': jumlahBilyetSijakaAktif,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'anggota': anggota?.toJson(),
      'ringkasan_saldo': ringkasanSaldo.toJson(),
      'statistiks': statistiks.toJson(),
    };
  }
}
