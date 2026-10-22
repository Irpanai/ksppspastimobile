import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_channel_model.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  bool _isCreatingToken = false;
  bool _isCheckingStatus = false;
  bool _isLoadingChannels = false;
  String? _errorMessage;
  SnapTokenResponse? _activePayment;
  PaymentStatusResponse? _lastStatus;
  List<PaymentChannelModel> _activeChannels = PaymentChannelModel.defaultChannels;

  bool get isCreatingToken => _isCreatingToken;
  bool get isCheckingStatus => _isCheckingStatus;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get errorMessage => _errorMessage;
  SnapTokenResponse? get activePayment => _activePayment;
  PaymentStatusResponse? get lastStatus => _lastStatus;
  List<PaymentChannelModel> get activeChannels => _activeChannels;

  /// Memuat daftar kanal pembayaran aktif dari Admin
  Future<void> fetchPaymentChannels() async {
    _isLoadingChannels = true;
    notifyListeners();

    try {
      final channels = await _service.getPaymentChannels();
      if (channels.isNotEmpty) {
        _activeChannels = channels;
      }
    } catch (_) {
      // Pertahankan default fallback channels jika offline
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }

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
    String? paymentMethod,
    String? bank,
    int? bulan,
    int? tahun,
    int? sijakaProdukId,
    String? namaAhliWaris,
    String? hubunganAhliWaris,
    String? nikAhliWaris,
    String? namaBank,
    String? noRekening,
    String? atasNamaRekening,
    String? metodePenyerahanBagihasil,
  }) async {
    _isCreatingToken = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.createSnapToken(
        type: type,
        nominal: nominal,
        paymentMethod: paymentMethod,
        bank: bank,
        bulan: bulan,
        tahun: tahun,
        sijakaProdukId: sijakaProdukId,
        namaAhliWaris: namaAhliWaris,
        hubunganAhliWaris: hubunganAhliWaris,
        nikAhliWaris: nikAhliWaris,
        namaBank: namaBank,
        noRekening: noRekening,
        atasNamaRekening: atasNamaRekening,
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
