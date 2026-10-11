import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/promo_model.dart';

class PromoService {
  Future<List<PromoModel>> getPromos({String? tipe}) async {
    final endpoint = tipe != null ? '${ApiConstants.promos}?tipe=$tipe' : ApiConstants.promos;
    final response = await ApiClient.get<List<PromoModel>>(
      endpoint,
      withAuth: false,
      fromJsonT: (data) {
        if (data is List) {
          return data.map((e) => PromoModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat daftar info & promo',
    );
  }
}
