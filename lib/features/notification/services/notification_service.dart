import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<NotificationListResponse> getNotifications({String? filter}) async {
    final queryParams = <String, dynamic>{};
    if (filter != null && filter.isNotEmpty && filter != 'all') {
      queryParams['filter'] = filter;
    }

    final response = await ApiClient.get<NotificationListResponse>(
      ApiConstants.memberNotifications,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      fromJsonT: (data) {
        if (data is Map<String, dynamic>) {
          return NotificationListResponse.fromJson(data);
        }
        return NotificationListResponse(unreadCount: 0, notifications: []);
      },
    );

    if (response.data != null) {
      return response.data!;
    }

    throw ApiException(
      message: response.message.isNotEmpty ? response.message : 'Gagal memuat notifikasi.',
    );
  }

  Future<int> markAsRead(int id) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiConstants.memberNotificationRead(id),
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    final unread = response.data?['unread_count'];
    return unread is int ? unread : int.tryParse('$unread') ?? 0;
  }

  Future<void> markAllAsRead() async {
    await ApiClient.post<dynamic>(
      ApiConstants.memberNotificationReadAll,
    );
  }

  Future<int> deleteNotification(int id) async {
    final response = await ApiClient.delete<Map<String, dynamic>>(
      ApiConstants.memberNotificationDelete(id),
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    final unread = response.data?['unread_count'];
    return unread is int ? unread : int.tryParse('$unread') ?? 0;
  }
}
