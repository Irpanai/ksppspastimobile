import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  Future<DashboardData> getDashboard() async {
    final response = await ApiClient.get<DashboardData>(
      ApiConstants.dashboard,
      withAuth: true,
      fromJsonT: (data) => DashboardData.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat dashboard member',
    );
  }
}
