import 'dart:io';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/member_profile_model.dart';
import '../models/pengunduran_diri_model.dart';

class ProfileService {
  /// 7.1 Detail Profil Lengkap
  Future<MemberProfileModel> getProfileDetail() async {
    final response = await ApiClient.get<MemberProfileModel>(
      ApiConstants.memberProfile,
      withAuth: true,
      fromJsonT: (data) => MemberProfileModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat detail profil',
    );
  }

  /// 7.2 Update Data Pribadi & Alamat Nasabah
  Future<MemberProfileModel> updateProfile(Map<String, dynamic> body) async {
    final response = await ApiClient.put<MemberProfileModel>(
      ApiConstants.updateProfile,
      body: body,
      withAuth: true,
      fromJsonT: (data) => MemberProfileModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memperbarui profil',
    );
  }

  /// 7.3 Ubah Password Akun
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.changePassword,
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      withAuth: true,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message.isNotEmpty ? response.message : 'Gagal mengubah password',
      );
    }
  }

  /// Reset Password Akun dengan PIN Transaksi
  Future<void> resetPasswordWithPin({
    required String pin,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.resetPasswordWithPin,
      body: {
        'pin': pin,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      withAuth: true,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message.isNotEmpty ? response.message : 'Gagal mereset password dengan PIN',
      );
    }
  }

  /// 7.4 Upload Foto Profil
  Future<MemberProfileModel> uploadPhoto({
    File? file,
    List<int>? bytes,
    String? filename,
  }) async {
    final response = await ApiClient.postMultipart<MemberProfileModel>(
      ApiConstants.updateProfile, // POST /member/profile
      file: file,
      fileBytes: bytes,
      filename: filename,
      fileField: 'photo',
      withAuth: true,
      fromJsonT: (data) => MemberProfileModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal mengunggah foto profil',
    );
  }

  /// Status Pengunduran Diri (Keluar Keanggotaan)
  Future<PengunduranDiriStatusModel> getPengunduranDiriStatus() async {
    final response = await ApiClient.get<PengunduranDiriStatusModel>(
      ApiConstants.pengunduranDiri,
      withAuth: true,
      fromJsonT: (data) => PengunduranDiriStatusModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat status pengunduran diri',
    );
  }

  /// Ajukan Pengunduran Diri dari Mobile
  Future<void> ajukanPengunduranDiri(String konfirmasiTeks) async {
    final response = await ApiClient.post(
      ApiConstants.pengunduranDiri,
      body: {
        'konfirmasi_teks': konfirmasiTeks,
      },
      withAuth: true,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message.isNotEmpty ? response.message : 'Gagal mengajukan pengunduran diri',
      );
    }
  }
}
