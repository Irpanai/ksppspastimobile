import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/sijaka_model.dart';

class SijakaService {
  Future<List<BilyetSijakaItem>> getBilyetList() async {
    final response = await ApiClient.get<List<BilyetSijakaItem>>(
      ApiConstants.sijaka,
      withAuth: true,
      fromJsonT: (data) {
        if (data is List) {
          return data
              .map((e) => BilyetSijakaItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat daftar Bilyet Sijaka',
    );
  }

  Future<BilyetSijakaDetail> getBilyetDetail(int rekeningId) async {
    final response = await ApiClient.get<BilyetSijakaDetail>(
      ApiConstants.sijakaDetail(rekeningId),
      withAuth: true,
      fromJsonT: (data) => BilyetSijakaDetail.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat detail Bilyet Sijaka',
    );
  }
}
