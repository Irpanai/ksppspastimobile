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
      );
    } catch (_) {
      // Ignore API failure during logout, still clear local storage
    } finally {
      await StorageService.clearAll();
    }
  }
}
