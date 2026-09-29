import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_model.dart';

class PaymentService {
  /// 6.1 Generate Snap Token for payment
  Future<SnapTokenResponse> createSnapToken({
    required String type,
    required int nominal,
    int? bulan,
    int? tahun,
    int? sijakaProdukId,
    String? namaAhliWaris,
    String? hubunganAhliWaris,
    String? metodePenyerahanBagihasil,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'nominal': nominal,
    };

    if (type == 'simpanan_wajib') {
      if (bulan != null) body['bulan'] = bulan;
      if (tahun != null) body['tahun'] = tahun;
    }

    if (type == 'pembukaan_sijaka') {
      if (sijakaProdukId != null) body['sijaka_produk_id'] = sijakaProdukId;
      if (namaAhliWaris != null && namaAhliWaris.isNotEmpty) body['nama_ahli_waris'] = namaAhliWaris;
      if (hubunganAhliWaris != null && hubunganAhliWaris.isNotEmpty) body['hubungan_ahli_waris'] = hubunganAhliWaris;
      if (metodePenyerahanBagihasil != null && metodePenyerahanBagihasil.isNotEmpty) {
        body['metode_penyerahan_bagihasil'] = metodePenyerahanBagihasil;
      }
    }

    final response = await ApiClient.post<SnapTokenResponse>(
      ApiConstants.snapToken,
      body: body,
      withAuth: true,
      fromJsonT: (data) => SnapTokenResponse.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal membuat transaksi pembayaran',
    );
  }

  /// 6.3 Check Live Transaction Status
  Future<PaymentStatusResponse> checkPaymentStatus(String orderId) async {
    final response = await ApiClient.get<PaymentStatusResponse>(
      ApiConstants.paymentStatus(orderId),
      withAuth: true,
      fromJsonT: (data) => PaymentStatusResponse.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memeriksa status pembayaran',
    );
  }

  /// 6.4 Get Digital Payment History
  Future<List<PaymentHistoryItem>> getPaymentHistory({
    String? status,
    String? type,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (type != null && type.isNotEmpty) query['type'] = type;

    final response = await ApiClient.get<List<PaymentHistoryItem>>(
      ApiConstants.paymentHistory,
      queryParams: query,
      withAuth: true,
      fromJsonT: (data) {
        if (data is List) {
          return data.map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List).map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List).map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    return response.data ?? [];
  }
}
