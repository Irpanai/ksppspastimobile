import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  bool _isCreatingToken = false;
  bool _isCheckingStatus = false;
  String? _errorMessage;
  SnapTokenResponse? _activePayment;
  PaymentStatusResponse? _lastStatus;

  bool get isCreatingToken => _isCreatingToken;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get errorMessage => _errorMessage;
  SnapTokenResponse? get activePayment => _activePayment;
  PaymentStatusResponse? get lastStatus => _lastStatus;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _isCreatingToken = false;
    _isCheckingStatus = false;
    _errorMessage = null;
    _activePayment = null;
    _lastStatus = null;
    notifyListeners();
  }

  /// Request Snap Token for Midtrans
  Future<SnapTokenResponse?> createPayment({
    required String type,
    required int nominal,
    int? bulan,
    int? tahun,
    int? sijakaProdukId,
    String? namaAhliWaris,
    String? hubunganAhliWaris,
    String? metodePenyerahanBagihasil,
  }) async {
    _isCreatingToken = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.createSnapToken(
        type: type,
        nominal: nominal,
        bulan: bulan,
        tahun: tahun,
        sijakaProdukId: sijakaProdukId,
        namaAhliWaris: namaAhliWaris,
        hubunganAhliWaris: hubunganAhliWaris,
        metodePenyerahanBagihasil: metodePenyerahanBagihasil,
      );
      _activePayment = result;
      _isCreatingToken = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isCreatingToken = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem: $e';
      _isCreatingToken = false;
      notifyListeners();
      return null;
    }
  }

  /// Check payment status from Midtrans / backend
  Future<PaymentStatusResponse?> checkStatus(String orderId) async {
    _isCheckingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _service.checkPaymentStatus(orderId);
      _lastStatus = status;
      _isCheckingStatus = false;
      notifyListeners();
      return status;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isCheckingStatus = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Gagal memeriksa status pembayaran.';
      _isCheckingStatus = false;
      notifyListeners();
      return null;
    }
  }
}
