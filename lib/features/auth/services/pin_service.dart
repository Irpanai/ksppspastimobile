import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class PinStatusResponse {
  final bool hasPin;
  final String? pinSetAt;

  PinStatusResponse({
    required this.hasPin,
    this.pinSetAt,
  });

  factory PinStatusResponse.fromJson(Map<String, dynamic> json) {
    return PinStatusResponse(
      hasPin: json['has_pin'] == true || json['has_pin'] == 1 || json['has_pin'] == 'true',
      pinSetAt: json['pin_set_at']?.toString(),
    );
  }
}

class PinService {
  /// Cek status apakah user sudah memiliki PIN
  Future<bool> checkHasPin() async {
    try {
      final response = await ApiClient.get<PinStatusResponse>(
        ApiConstants.pinStatus,
        withAuth: true,
        fromJsonT: (data) => PinStatusResponse.fromJson(data as Map<String, dynamic>),
      );

      return response.data?.hasPin ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuat PIN 6-digit pertama kali
  Future<bool> setupPin({
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.pinSetup,
      body: {
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
      withAuth: true,
    );

    if (response.success) {
      return true;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal membuat PIN',
      errors: response.errors,
    );
  }

  /// Memverifikasi PIN transaksi
  Future<bool> verifyPin(String pin) async {
    final response = await ApiClient.post(
      ApiConstants.pinVerify,
      body: {
        'pin': pin,
      },
      withAuth: true,
    );

    if (response.success) {
      return true;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'PIN yang Anda masukkan salah',
      errors: response.errors,
    );
  }

  /// Mengubah PIN transaksi yang sudah ada
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
    required String newPinConfirmation,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.pinChange,
      body: {
        'old_pin': oldPin,
        'pin': newPin,
        'pin_confirmation': newPinConfirmation,
      },
      withAuth: true,
    );

    if (response.success) {
      return true;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal mengubah PIN',
      errors: response.errors,
    );
  }
}
