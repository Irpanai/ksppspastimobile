class AnggotaModel {
  final int id;
  final String? noAnggota;
  final String? nik;
  final String? noHp;
  final String? alamat;
  final String? cabang;
  final String? status;
  final String? tglBergabung;

  AnggotaModel({
    required this.id,
    this.noAnggota,
    this.nik,
    this.noHp,
    this.alamat,
    this.cabang,
    this.status,
    this.tglBergabung,
  });

  factory AnggotaModel.fromJson(Map<String, dynamic> json) {
    return AnggotaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      noAnggota: json['no_anggota']?.toString(),
      nik: json['nik']?.toString(),
      noHp: json['no_hp']?.toString(),
      alamat: json['alamat']?.toString(),
      cabang: json['cabang']?.toString(),
      status: json['status']?.toString(),
      tglBergabung: json['tgl_bergabung']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_anggota': noAnggota,
      'nik': nik,
      'no_hp': noHp,
      'alamat': alamat,
      'cabang': cabang,
      'status': status,
      'tgl_bergabung': tglBergabung,
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? noAnggota;
  final String? statusKeanggotaan;
  final String? cabang;
  final String? profilePhotoUrl;
  final List<String> roles;
  final AnggotaModel? anggota;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.noAnggota,
    this.statusKeanggotaan,
    this.cabang,
    this.profilePhotoUrl,
    this.roles = const [],
    this.anggota,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    }

    AnggotaModel? parsedAnggota;
    if (json['anggota'] is Map<String, dynamic>) {
      parsedAnggota = AnggotaModel.fromJson(json['anggota'] as Map<String, dynamic>);
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      noAnggota: json['no_anggota']?.toString() ?? parsedAnggota?.noAnggota,
      statusKeanggotaan: json['status_keanggotaan']?.toString() ?? parsedAnggota?.status,
      cabang: json['cabang']?.toString() ?? parsedAnggota?.cabang,
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      roles: parsedRoles,
      anggota: parsedAnggota,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'no_anggota': noAnggota,
      'status_keanggotaan': statusKeanggotaan,
      'cabang': cabang,
      'profile_photo_url': profilePhotoUrl,
      'roles': roles,
      'anggota': anggota?.toJson(),
    };
  }
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
