import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/member_profile_model.dart';

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
}
