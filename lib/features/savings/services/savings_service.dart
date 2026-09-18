import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/simpanan_riwayat_model.dart';

class SavingsService {
  Future<SimpananRiwayatPagination> getRiwayatSimpanan({
    String? jenis,
    String? tipe,
    String? tglMulai,
    String? tglSelesai,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (jenis != null && jenis.isNotEmpty) {
      queryParams['jenis'] = jenis;
    }
    if (tipe != null && tipe.isNotEmpty) {
      queryParams['tipe'] = tipe;
    }
    if (tglMulai != null && tglMulai.isNotEmpty) {
      queryParams['tgl_mulai'] = tglMulai;
    }
    if (tglSelesai != null && tglSelesai.isNotEmpty) {
      queryParams['tgl_selesai'] = tglSelesai;
    }

    final response = await ApiClient.get<SimpananRiwayatPagination>(
      ApiConstants.simpananRiwayat,
      queryParams: queryParams,
      withAuth: true,
      fromJsonT: (data) => SimpananRiwayatPagination.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat riwayat simpanan',
    );
  }
}
