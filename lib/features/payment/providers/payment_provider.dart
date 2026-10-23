import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_channel_model.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../../../core/services/storage_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  PaymentProvider() {
    _loadSavedPendingPayments();
  }

  List<SnapTokenResponse> _pendingPayments = [];
  bool _isCreatingToken = false;
  bool _isCheckingStatus = false;
  bool _isLoadingChannels = false;
  String? _errorMessage;
  PaymentStatusResponse? _lastStatus;
  List<PaymentChannelModel> _activeChannels = PaymentChannelModel.defaultChannels;

  List<SnapTokenResponse> get pendingPayments => _pendingPayments;
  SnapTokenResponse? get activePayment => _pendingPayments.isNotEmpty ? _pendingPayments.first : null;
  bool get isCreatingToken => _isCreatingToken;
  bool get isCheckingStatus => _isCheckingStatus;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get errorMessage => _errorMessage;
  PaymentStatusResponse? get lastStatus => _lastStatus;
  List<PaymentChannelModel> get activeChannels => _activeChannels;

  Future<void> _loadSavedPendingPayments() async {
    try {
      final list = await StorageService.getPendingPaymentsList();
      final List<SnapTokenResponse> validList = [];
      bool hadExpired = false;

      final nowUtc = DateTime.now().toUtc();
      for (final json in list) {
        try {
          final payment = SnapTokenResponse.fromJson(json);
          if (payment.expiredDate != null && payment.expiredDate!.isNotEmpty) {
            final exp = DateTime.tryParse(payment.expiredDate!);
            if (exp != null && exp.isBefore(nowUtc)) {
              hadExpired = true;
              continue; // Lewati transaksi yang sudah kedaluwarsa
            }
          }
          validList.add(payment);
        } catch (_) {}
      }

      _pendingPayments = validList;

      if (hadExpired) {
        await StorageService.clearPendingPayment();
        for (final p in _pendingPayments.reversed) {
          await StorageService.savePendingPayment(p.toJson());
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Membatalkan salah satu transaksi pending
  Future<void> cancelPendingPayment(String orderId) async {
    _pendingPayments.removeWhere((p) => p.orderId == orderId);
    await StorageService.removePendingPayment(orderId);
    notifyListeners();
  }

  /// Membersihkan transaksi pending teratas (atau spesifik)
  Future<void> clearActivePayment() async {
    if (_pendingPayments.isNotEmpty) {
      final topOrderId = _pendingPayments.first.orderId;
      await cancelPendingPayment(topOrderId);
    } else {
      await StorageService.clearPendingPayment();
      notifyListeners();
    }
  }

  /// Membersihkan seluruh antrean pembayaran
  Future<void> clearAllPayments() async {
    _pendingPayments.clear();
    await StorageService.clearPendingPayment();
    notifyListeners();
  }

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
    _lastStatus = null;
    notifyListeners();
  }

  /// Request Snap Token for Midtrans / DOKU
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

      // Simpan ke daftar antrean pending transaksi
      _pendingPayments.removeWhere((p) => p.orderId == result.orderId);
      _pendingPayments.insert(0, result);
      await StorageService.savePendingPayment(result.toJson());

      _isCreatingToken = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isCreatingToken = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem: ';
      _isCreatingToken = false;
      notifyListeners();
      return null;
    }
  }

  /// Check payment status from Midtrans / DOKU / backend
  Future<PaymentStatusResponse?> checkStatus(String orderId) async {
    _isCheckingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _service.checkPaymentStatus(orderId);
      _lastStatus = status;
      if (status.isSettled) {
        _pendingPayments.removeWhere((p) => p.orderId == orderId);
        await StorageService.removePendingPayment(orderId);
      }
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
