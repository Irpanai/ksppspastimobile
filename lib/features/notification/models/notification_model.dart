import 'package:flutter/material.dart';

class NotificationListResponse {
  final int unreadCount;
  final List<NotificationModel> notifications;

  NotificationListResponse({
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse('${json['unread_count']}') ?? 0,
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // 'account', 'tunggakan', 'payment', 'sijaka', 'promo', 'system'
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? createdAt;
  final String timeAgo;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    this.createdAt,
    required this.timeAgo,
  });

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    String? createdAt,
    String? timeAgo,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
      createdAt: json['created_at']?.toString(),
      timeAgo: json['time_ago']?.toString() ?? 'Baru saja',
    );
  }

  IconData get icon {
    switch (type) {
      case 'account':
        return Icons.verified_user_rounded;
      case 'pokok':
        return Icons.account_balance_wallet_rounded;
      case 'tunggakan':
        return Icons.warning_amber_rounded;
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'sijaka':
        return Icons.account_balance_rounded;
      case 'promo':
        return Icons.campaign_rounded;
      case 'system':
      default:
        return Icons.shield_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'account':
        return const Color(0xFF16A34A); // Emerald green
      case 'pokok':
        return const Color(0xFF0E7955); // KSPPS Green
      case 'tunggakan':
        return const Color(0xFFDC2626); // Crimson red
      case 'payment':
        return const Color(0xFF0284C7); // Sky blue
      case 'sijaka':
        return const Color(0xFF7C3AED); // Purple
      case 'promo':
        return const Color(0xFFD97706); // Amber
      case 'system':
      default:
        return const Color(0xFF0D9488); // Teal
    }
  }

  Color get iconBgColor {
    return iconColor.withValues(alpha: 0.12);
  }

  String get categoryLabel {
    switch (type) {
      case 'account':
        return 'Aktivasi Akun';
      case 'pokok':
        return 'Simpanan Pokok';
      case 'tunggakan':
        return 'Tunggakan';
      case 'payment':
        return 'Transaksi';
      case 'sijaka':
        return 'Deposito SIJAKA';
      case 'promo':
        return 'Info & Promo';
      case 'system':
      default:
        return 'Keamanan';
    }
  }
}
