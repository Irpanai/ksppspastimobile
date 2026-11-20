import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class PinStatusResponse {
  final bool hasPin;
  final String? pinSetAt;
  final bool isLocked;
  final int failedAttempts;
  final int remainingAttempts;

  PinStatusResponse({
    required this.hasPin,
    this.pinSetAt,
    this.isLocked = false,
    this.failedAttempts = 0,
    this.remainingAttempts = 5,
  });

  factory PinStatusResponse.fromJson(Map<String, dynamic> json) {
    return PinStatusResponse(
      hasPin: json['has_pin'] == true || json['has_pin'] == 1 || json['has_pin'] == 'true',
      pinSetAt: json['pin_set_at']?.toString(),
      isLocked: json['is_locked'] == true || json['is_locked'] == 1 || json['is_locked'] == 'true',
      failedAttempts: (json['failed_attempts'] as num?)?.toInt() ?? 0,
      remainingAttempts: (json['remaining_attempts'] as num?)?.toInt() ?? 5,
    );
  }
}

class PinService {
  /// Cek status lengkap PIN user (termasuk status terkunci / rate limiting)
  Future<PinStatusResponse?> getPinStatus() async {
    try {
      final response = await ApiClient.get<PinStatusResponse>(
        ApiConstants.pinStatus,
        withAuth: true,
        fromJsonT: (data) => PinStatusResponse.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Cek status apakah user sudah memiliki PIN
  Future<bool> checkHasPin() async {
    try {
      final status = await getPinStatus();
      return status?.hasPin ?? false;
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

  /// Meminta pengiriman kode 6-digit OTP ke email user untuk reset PIN yang terblokir atau lupa PIN
  Future<Map<String, dynamic>> requestForgotPinOtp() async {
    final response = await ApiClient.post(
      ApiConstants.pinForgotOtp,
      body: {},
      withAuth: true,
    );

    if (response.success && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal mengirim kode OTP reset PIN ke email',
      errors: response.errors,
    );
  }

  /// Mereset PIN transaksi baru menggunakan kode OTP email
  Future<bool> resetPinWithOtp({
    required String otp,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.pinResetOtp,
      body: {
        'otp': otp,
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
      withAuth: true,
    );

    if (response.success) {
      return true;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal mereset PIN dengan OTP',
      errors: response.errors,
    );
  }
}
