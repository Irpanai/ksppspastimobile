import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/premium_header.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../home/widgets/wajib_simpanan_modal_dialog.dart';
import '../../promo/screens/promo_screen.dart';
import '../../payment/screens/top_up_screen.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });
  }

  void _showNotificationDetail(BuildContext context, NotificationModel notif) {
    context.read<NotificationProvider>().markAsRead(notif);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: notif.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notif.icon, color: notif.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: notif.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.categoryLabel,
                            style: TextStyle(
                              color: notif.iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.createdAt ?? notif.timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notif.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notif.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (notif.type == 'pokok')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                    label: const Text(
                      'Bayar Simpanan Pokok',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TopUpScreen(initialType: 'pokok'),
                        ),
                      );
                    },
                  ),
                )
              else if (notif.type == 'tunggakan')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: const Text(
                      'Bayar Simpanan Wajib',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      WajibSimpananModalDialog.show(context);
                    },
                  ),
                )
              else if (notif.type == 'promo')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.campaign_rounded, size: 20),
                    label: const Text(
                      'Lihat Info & Promo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PromoScreen()),
                      );
                    },
                  ),
                )
              else if (notif.type == 'payment')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: const Text(
                      'Lihat Riwayat Transaksi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                      );
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup', style: TextStyle(color: Color(0xFF334155))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          PremiumHeader(
            title: 'Notifikasi',
            showBackButton: true,
            actions: [
              if (provider.unreadCount > 0)
                IconButton(
                  tooltip: 'Tandai Semua Dibaca',
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    provider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua notifikasi ditandai telah dibaca'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),

          // Filter bar
          _buildFilterBar(provider),

          // List content
          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                await provider.fetchNotifications(refresh: true);
              },
              child: _buildListContent(provider, notifications),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(NotificationProvider provider) {
    final filters = [
      {'key': 'all', 'label': 'Semua'},
      {'key': 'unread', 'label': 'Belum Dibaca'},
      {'key': 'account', 'label': 'Aktivasi & Akun'},
      {'key': 'pokok', 'label': 'Simpanan Pokok'},
      {'key': 'tunggakan', 'label': 'Tunggakan'},
      {'key': 'payment', 'label': 'Transaksi'},
      {'key': 'promo', 'label': 'Promo'},
      {'key': 'system', 'label': 'Keamanan'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = provider.activeFilter == item['key'];

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => provider.setFilter(item['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    if (item['key'] == 'unread' && provider.unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListContent(NotificationProvider provider, List<NotificationModel> notifications) {
    if (provider.isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => provider.fetchNotifications(refresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.activeFilter == 'unread'
                    ? 'Semua notifikasi telah Anda baca.'
                    : 'Aktivitas transaksi, info keanggotaan, dan promo akan muncul di sini.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 36 + MediaQuery.of(context).padding.bottom),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notif = notifications[index];

        return Dismissible(
          key: Key('notif_${notif.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ),
          onDismissed: (_) {
            provider.deleteNotification(notif);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifikasi telah dihapus'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNotificationDetail(context, notif),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notif.isRead
                      ? Colors.grey.shade200
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                  width: notif.isRead ? 1.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: notif.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notif.icon, color: notif.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: notif.iconColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                notif.categoryLabel,
                                style: TextStyle(
                                  color: notif.iconColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              notif.timeAgo,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: notif.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
