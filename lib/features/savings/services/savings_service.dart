import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/penarikan_model.dart';
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

  /// Pengajuan Penarikan Dana Simpanan
  Future<bool> ajukanPenarikan({
    required int nominal,
    String jenisSimpanan = 'sukarela',
    required String namaBank,
    required String noRekening,
    required String atasNama,
    String? catatanAnggota,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.simpananTarik,
      body: {
        'nominal': nominal,
        'jenis_simpanan': jenisSimpanan,
        'nama_bank': namaBank,
        'no_rekening': noRekening,
        'atas_nama': atasNama,
        if (catatanAnggota != null && catatanAnggota.isNotEmpty)
          'catatan_anggota': catatanAnggota,
      },
      withAuth: true,
    );

    if (response.success) {
      return true;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal mengajukan penarikan',
      errors: response.errors,
    );
  }

  /// Mengambil Riwayat Pengajuan Penarikan
  Future<PenarikanPaginationModel> getRiwayatPenarikan({
    int page = 1,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await ApiClient.get<PenarikanPaginationModel>(
      ApiConstants.simpananPenarikanRiwayat,
      queryParams: queryParams,
      withAuth: true,
      fromJsonT: (data) => PenarikanPaginationModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat riwayat penarikan',
    );
  }
}
