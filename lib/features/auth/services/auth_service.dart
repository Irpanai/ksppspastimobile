import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  Future<LoginResponseData> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post<LoginResponseData>(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
      withAuth: false,
      fromJsonT: (data) => LoginResponseData.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      final loginData = response.data!;
      // Persist token and initial user
      await StorageService.saveToken(loginData.token);
      await StorageService.saveUserData(loginData.user.toJson());
      if (loginData.user.anggota != null) {
        await StorageService.saveAnggotaData(loginData.user.anggota!.toJson());
      }
      return loginData;
    }

    throw ApiException(message: response.message.isNotEmpty ? response.message : 'Login gagal');
  }

  Future<LoginResponseData> register({
    required String name,
    required String email,
    required String password,
    String? passwordConfirmation,
    required String nik,
    required String noHp,
    String? alamat,
    String? tempatLahir,
    String? tanggalLahir,
    String? jenisKelamin,
    String? agama,
    String? pekerjaan,
    String? provinsi,
    String? kabupatenKota,
    String? kecamatan,
    String? kelurahan,
    String? cabang,
  }) async {
    final response = await ApiClient.post<LoginResponseData>(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation ?? password,
        'nik': nik,
        'no_ktp': nik,
        'no_hp': noHp,
        'no_telpon': noHp,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (tempatLahir != null && tempatLahir.isNotEmpty) 'tempat_lahir': tempatLahir,
        if (tanggalLahir != null && tanggalLahir.isNotEmpty) 'tanggal_lahir': tanggalLahir,
        if (jenisKelamin != null && jenisKelamin.isNotEmpty) 'jenis_kelamin': jenisKelamin,
        if (agama != null && agama.isNotEmpty) 'agama': agama,
        if (pekerjaan != null && pekerjaan.isNotEmpty) 'pekerjaan': pekerjaan,
        if (provinsi != null && provinsi.isNotEmpty) 'provinsi': provinsi,
        if (kabupatenKota != null && kabupatenKota.isNotEmpty) 'kabupaten_kota': kabupatenKota,
        if (kecamatan != null && kecamatan.isNotEmpty) 'kecamatan': kecamatan,
        if (kelurahan != null && kelurahan.isNotEmpty) 'kelurahan': kelurahan,
        if (cabang != null && cabang.isNotEmpty) 'cabang': cabang,
      },
      withAuth: false,
      fromJsonT: (data) => LoginResponseData.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      final loginData = response.data!;
      await StorageService.saveToken(loginData.token);
      await StorageService.saveUserData(loginData.user.toJson());
      if (loginData.user.anggota != null) {
        await StorageService.saveAnggotaData(loginData.user.anggota!.toJson());
      }
      return loginData;
    }

    throw ApiException(message: response.message.isNotEmpty ? response.message : 'Pendaftaran gagal');
  }

  Future<UserModel> getProfile() async {
    final response = await ApiClient.get<UserModel>(
      ApiConstants.me,
      withAuth: true,
      fromJsonT: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      final user = response.data!;
      await StorageService.saveUserData(user.toJson());
      if (user.anggota != null) {
        await StorageService.saveAnggotaData(user.anggota!.toJson());
      }
      return user;
    }

    throw ApiException(message: response.message.isNotEmpty ? response.message : 'Gagal memuat profil');
  }

  Future<void> logout() async {
    try {
      await ApiClient.post(
        ApiConstants.logout,
        withAuth: true,
        timeout: const Duration(seconds: 2),
      );
    } catch (_) {
      // Ignore API failure during logout, still clear local storage
    } finally {
      await StorageService.clearAll();
    }
  }
}
