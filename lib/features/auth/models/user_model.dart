import '../../../core/constants/api_constants.dart';

class AnggotaModel {
  final int id;
  final String? noAnggota;
  final String? noKtp;
  final String? nik;
  final String? noTelpon;
  final String? noHp;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? agama;
  final String? pekerjaan;
  final String? namaAhliWaris;
  final String? hubunganAhliWaris;
  final String? nikAhliWaris;
  final String? noHpAhliWaris;
  final String? emailAhliWaris;
  final String? alamatAhliWaris;
  final String? namaBank;
  final String? noRekening;
  final String? atasNamaRekening;
  final String? provinsi;
  final String? kabupatenKota;
  final String? kecamatan;
  final String? kelurahan;
  final String? alamat;
  final String? cabang;
  final String? jenisKeanggotaan;
  final String? status;
  final String? statusKeanggotaan;
  final bool? isPokokPaid;
  final bool? isWajibPaid;
  final bool? isMemberActive;
  final String? tglBergabung;
  final String? foto;
  final bool isReaktivasi;
  final String? noAnggotaLama;
  final String? tanggalPertamaGabung;
  final String? namaPanggilan;

  AnggotaModel({
    required this.id,
    this.noAnggota,
    this.noKtp,
    this.nik,
    this.noTelpon,
    this.noHp,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.agama,
    this.pekerjaan,
    this.namaAhliWaris,
    this.hubunganAhliWaris,
    this.nikAhliWaris,
    this.noHpAhliWaris,
    this.emailAhliWaris,
    this.alamatAhliWaris,
    this.namaBank,
    this.noRekening,
    this.atasNamaRekening,
    this.provinsi,
    this.kabupatenKota,
    this.kecamatan,
    this.kelurahan,
    this.alamat,
    this.cabang,
    this.jenisKeanggotaan,
    this.status,
    this.statusKeanggotaan,
    this.isPokokPaid,
    this.isWajibPaid,
    this.isMemberActive,
    this.tglBergabung,
    this.foto,
    this.isReaktivasi = false,
    this.noAnggotaLama,
    this.tanggalPertamaGabung,
    this.namaPanggilan,
  });

  String get effectiveNik => nik ?? noKtp ?? '-';
  String get effectivePhone => noHp ?? noTelpon ?? '-';
  String get effectiveStatus => statusKeanggotaan ?? status ?? 'Aktif';
  String? get fullFotoUrl => ApiConstants.resolveImageUrl(foto);

  factory AnggotaModel.fromJson(Map<String, dynamic> json) {
    return AnggotaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      noAnggota: json['no_anggota']?.toString(),
      noKtp: json['no_ktp']?.toString(),
      nik: json['nik']?.toString() ?? json['no_ktp']?.toString(),
      noTelpon: json['no_telpon']?.toString(),
      noHp: json['no_hp']?.toString() ?? json['no_telpon']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      agama: json['agama']?.toString(),
      pekerjaan: json['pekerjaan']?.toString(),
      namaAhliWaris: json['nama_ahli_waris']?.toString(),
      hubunganAhliWaris: json['hubungan_ahli_waris']?.toString(),
      nikAhliWaris: json['nik_ahli_waris']?.toString() ?? json['no_ktp_ahli_waris']?.toString(),
      noHpAhliWaris: json['no_hp_ahli_waris']?.toString(),
      emailAhliWaris: json['email_ahli_waris']?.toString(),
      alamatAhliWaris: json['alamat_ahli_waris']?.toString(),
      namaBank: json['nama_bank']?.toString(),
      noRekening: json['no_rekening']?.toString(),
      atasNamaRekening: json['atas_nama_rekening']?.toString(),
      provinsi: json['provinsi']?.toString(),
      kabupatenKota: json['kabupaten_kota']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      kelurahan: json['kelurahan']?.toString(),
      alamat: json['alamat']?.toString(),
      cabang: json['cabang']?.toString(),
      jenisKeanggotaan: json['jenis_keanggotaan']?.toString(),
      status: json['status']?.toString(),
      statusKeanggotaan: json['status_keanggotaan']?.toString() ?? json['status']?.toString(),
      isPokokPaid: _parseOptionalBool(json['is_pokok_paid']),
      isWajibPaid: _parseOptionalBool(json['is_wajib_paid']),
      isMemberActive: _parseOptionalBool(json['is_member_active']),
      tglBergabung: json['tgl_bergabung']?.toString(),
      foto: json['foto']?.toString() ??
          json['photo']?.toString() ??
          json['foto_url']?.toString() ??
          json['foto_wajah']?.toString() ??
          json['foto_wajah_url']?.toString(),
      isReaktivasi: json['is_reaktivasi'] == true ||
          json['is_reaktivasi'] == 1 ||
          json['is_reaktivasi'] == '1' ||
          json['is_reaktivasi'] == 'true',
      noAnggotaLama: json['no_anggota_lama']?.toString(),
      tanggalPertamaGabung: json['tanggal_pertama_gabung']?.toString(),
      namaPanggilan: json['nama_panggilan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_anggota': noAnggota,
      'no_ktp': noKtp,
      'nik': nik,
      'no_telpon': noTelpon,
      'no_hp': noHp,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'agama': agama,
      'pekerjaan': pekerjaan,
      'nama_ahli_waris': namaAhliWaris,
      'hubungan_ahli_waris': hubunganAhliWaris,
      'nik_ahli_waris': nikAhliWaris,
      'no_hp_ahli_waris': noHpAhliWaris,
      'email_ahli_waris': emailAhliWaris,
      'alamat_ahli_waris': alamatAhliWaris,
      'nama_bank': namaBank,
      'no_rekening': noRekening,
      'atas_nama_rekening': atasNamaRekening,
      'provinsi': provinsi,
      'kabupaten_kota': kabupatenKota,
      'kecamatan': kecamatan,
      'kelurahan': kelurahan,
      'alamat': alamat,
      'cabang': cabang,
      'jenis_keanggotaan': jenisKeanggotaan,
      'status': status,
      'status_keanggotaan': statusKeanggotaan,
      'is_pokok_paid': isPokokPaid,
      'is_wajib_paid': isWajibPaid,
      'is_member_active': isMemberActive,
      'tgl_bergabung': tglBergabung,
      'foto': foto,
      'is_reaktivasi': isReaktivasi,
      'no_anggota_lama': noAnggotaLama,
      'tanggal_pertama_gabung': tanggalPertamaGabung,
      'nama_panggilan': namaPanggilan,
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String? namaPanggilan;
  final String? callName;
  final String email;
  final String? noAnggota;
  final String? statusKeanggotaan;
  final bool? isPokokPaid;
  final bool? isWajibPaid;
  final bool? isMemberActive;
  final String? cabang;
  final String? profilePhotoUrl;
  final bool hasPin;
  final List<String> roles;
  final AnggotaModel? anggota;
  final bool isReaktivasi;
  final String? noAnggotaLama;
  final String? tanggalPertamaGabung;

  UserModel({
    required this.id,
    required this.name,
    this.namaPanggilan,
    this.callName,
    required this.email,
    this.noAnggota,
    this.statusKeanggotaan,
    this.isPokokPaid,
    this.isWajibPaid,
    this.isMemberActive,
    this.cabang,
    this.profilePhotoUrl,
    this.hasPin = false,
    this.roles = const [],
    this.anggota,
    this.isReaktivasi = false,
    this.noAnggotaLama,
    this.tanggalPertamaGabung,
  });

  /// Nama sapaan panggilan ramah dan ringkas untuk UI
  String get effectiveCallName {
    if (callName != null && callName!.trim().isNotEmpty) {
      return callName!.trim();
    }
    if (namaPanggilan != null && namaPanggilan!.trim().isNotEmpty) {
      return namaPanggilan!.trim();
    }
    final clean = name.trim();
    if (clean.isEmpty) return 'Nasabah';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'Nasabah';
    final firstLower = parts[0].toLowerCase();
    if (parts.length > 1 && ['muhammad', 'm.', 'moh.', 'muh.', 'h.', 'hj.'].contains(firstLower)) {
      return parts[1];
    }
    return parts[0];
  }

  /// Resolves profile image to absolute URL whether it's full URL or relative storage path
  String? get fullProfilePhotoUrl {
    final raw = profilePhotoUrl ?? anggota?.foto;
    return ApiConstants.resolveImageUrl(raw);
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? namaPanggilan,
    String? callName,
    String? email,
    String? noAnggota,
    String? statusKeanggotaan,
    bool? isPokokPaid,
    bool? isWajibPaid,
    bool? isMemberActive,
    String? cabang,
    String? profilePhotoUrl,
    bool? hasPin,
    List<String>? roles,
    AnggotaModel? anggota,
    bool? isReaktivasi,
    String? noAnggotaLama,
    String? tanggalPertamaGabung,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      namaPanggilan: namaPanggilan ?? this.namaPanggilan,
      callName: callName ?? this.callName,
      email: email ?? this.email,
      noAnggota: noAnggota ?? this.noAnggota,
      statusKeanggotaan: statusKeanggotaan ?? this.statusKeanggotaan,
      isPokokPaid: isPokokPaid ?? this.isPokokPaid,
      isWajibPaid: isWajibPaid ?? this.isWajibPaid,
      isMemberActive: isMemberActive ?? this.isMemberActive,
      cabang: cabang ?? this.cabang,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      hasPin: hasPin ?? this.hasPin,
      roles: roles ?? this.roles,
      anggota: anggota ?? this.anggota,
      isReaktivasi: isReaktivasi ?? this.isReaktivasi,
      noAnggotaLama: noAnggotaLama ?? this.noAnggotaLama,
      tanggalPertamaGabung: tanggalPertamaGabung ?? this.tanggalPertamaGabung,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    }

    AnggotaModel? parsedAnggota;
    if (json['anggota'] is Map<String, dynamic>) {
      parsedAnggota = AnggotaModel.fromJson(json['anggota'] as Map<String, dynamic>);
    }

    final rawPhoto = json['profile_photo_url']?.toString() ??
        json['photo_url']?.toString() ??
        json['photo']?.toString() ??
        json['foto']?.toString() ??
        json['foto_wajah']?.toString() ??
        json['foto_wajah_url']?.toString() ??
        json['profile_photo_path']?.toString() ??
        parsedAnggota?.foto;

    final bool parsedHasPin = json['has_pin'] == true ||
        json['has_pin'] == 1 ||
        json['has_pin'] == '1' ||
        json['has_pin'] == 'true';

    final bool parsedIsReaktivasi = json['is_reaktivasi'] == true ||
        json['is_reaktivasi'] == 1 ||
        json['is_reaktivasi'] == '1' ||
        json['is_reaktivasi'] == 'true' ||
        (parsedAnggota?.isReaktivasi ?? false);

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      namaPanggilan: json['nama_panggilan']?.toString() ?? parsedAnggota?.namaPanggilan,
      callName: json['call_name']?.toString(),
      email: json['email']?.toString() ?? '',
      noAnggota: json['no_anggota']?.toString() ?? parsedAnggota?.noAnggota,
      statusKeanggotaan: json['status_keanggotaan']?.toString() ?? parsedAnggota?.status,
      isPokokPaid: _parseOptionalBool(json['is_pokok_paid']) ?? parsedAnggota?.isPokokPaid,
      isWajibPaid: _parseOptionalBool(json['is_wajib_paid']) ?? parsedAnggota?.isWajibPaid,
      isMemberActive: _parseOptionalBool(json['is_member_active']) ?? parsedAnggota?.isMemberActive,
      cabang: json['cabang']?.toString() ?? parsedAnggota?.cabang,
      profilePhotoUrl: rawPhoto,
      hasPin: parsedHasPin,
      roles: parsedRoles,
      anggota: parsedAnggota,
      isReaktivasi: parsedIsReaktivasi,
      noAnggotaLama: json['no_anggota_lama']?.toString() ?? parsedAnggota?.noAnggotaLama,
      tanggalPertamaGabung: json['tanggal_pertama_gabung']?.toString() ?? parsedAnggota?.tanggalPertamaGabung,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nama_panggilan': namaPanggilan,
      'call_name': callName,
      'email': email,
      'no_anggota': noAnggota,
      'status_keanggotaan': statusKeanggotaan,
      'is_pokok_paid': isPokokPaid,
      'is_wajib_paid': isWajibPaid,
      'is_member_active': isMemberActive,
      'cabang': cabang,
      'profile_photo_url': profilePhotoUrl,
      'has_pin': hasPin,
      'roles': roles,
      'anggota': anggota?.toJson(),
      'is_reaktivasi': isReaktivasi,
      'no_anggota_lama': noAnggotaLama,
      'tanggal_pertama_gabung': tanggalPertamaGabung,
    };
  }
}

bool? _parseOptionalBool(dynamic val) {
  if (val == null) return null;
  if (val is bool) return val;
  if (val == 1 || val == '1' || val.toString().toLowerCase() == 'true') return true;
  if (val == 0 || val == '0' || val.toString().toLowerCase() == 'false') return false;
  return null;
}

class LoginResponseData {
  final String token;
  final UserModel user;

  LoginResponseData({
    required this.token,
    required this.user,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      token: json['token']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
