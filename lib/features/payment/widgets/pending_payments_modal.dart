import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../screens/doku_webview_screen.dart';
import '../screens/native_payment_detail_screen.dart';
import '../screens/native_qris_screen.dart';

class PendingPaymentsModal extends StatelessWidget {
  const PendingPaymentsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PendingPaymentsModal(),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(' berhasil disalin'),
          ],
        ),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getChannelColor(BuildContext context, SnapTokenResponse item) {
    try {
      final channels = context.read<PaymentProvider>().activeChannels;
      if (item.isDirectQris) {
        final matched = channels.firstWhere((c) => c.code.toLowerCase() == 'qris');
        return matched.tagColor;
      }
      if (item.isDirectVa && item.bank != null) {
        final matched = channels.firstWhere((c) => c.code.toLowerCase() == item.bank!.toLowerCase());
        return matched.tagColor;
      }
    } catch (_) {}
    if (item.isDirectQris) return const Color(0xFFDC2626);
    if (item.bank?.toLowerCase() == 'bsi') return const Color(0xFF00A39D);
    return const Color(0xFF388E3C);
  }

  void _resumePayment(BuildContext context, SnapTokenResponse payment) {
    Navigator.pop(context); // Tutup modal

    final Widget targetScreen = payment.isDirectQris
        ? NativeQrisScreen(paymentResponse: payment)
        : (payment.isDirectVa
            ? NativePaymentDetailScreen(paymentResponse: payment)
            : DokuWebViewScreen(paymentResponse: payment));

    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
  }

  Future<void> _cancelPayment(BuildContext context, SnapTokenResponse payment) async {
    final confirm = await AppDialog.showConfirmation(
      context,
      title: 'Batalkan Transaksi?',
      message: 'Apakah Anda yakin ingin membatalkan transaksi sebesar ${payment.nominalFormat}?',
      confirmText: 'Ya, Batalkan',
      cancelText: 'Kembali',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFDC2626),
      iconBgColor: const Color(0xFFFEE2E2),
    );

    if (confirm == true && context.mounted) {
      await context.read<PaymentProvider>().cancelPendingPayment(payment.orderId);
      if (context.mounted) {
        final remaining = context.read<PaymentProvider>().pendingPayments;
        if (remaining.isEmpty) {
          Navigator.pop(context); // Tutup modal jika tidak ada transaksi tersisa
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>().pendingPayments;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Indicator
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Menunggu Pembayaran',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${payments.length} transaksi belum selesai',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body List
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak Ada Pembayaran Menunggu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Semua transaksi pembayaran Anda telah selesai atau dibatalkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
                shrinkWrap: true,
                itemCount: payments.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = payments[index];
                  final isQris = item.isDirectQris;
                  final isVa = item.isDirectVa;
                  final channelColor = _getChannelColor(context, item);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Bar: Icon, Metode & Status
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: channelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isQris
                                    ? Icons.qr_code_2_rounded
                                    : (isVa ? Icons.account_balance_rounded : Icons.credit_card_rounded),
                                color: channelColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayPaymentMethod,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    item.displayType,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text(
                                'Menunggu',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Nominal & Rincian
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nominal Tagihan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  item.nominalFormat,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                            if (isVa && item.vaNumber != null && item.vaNumber!.isNotEmpty)
                              InkWell(
                                onTap: () => _copyToClipboard(context, item.vaNumber!, 'Nomor VA'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'VA: ${item.vaNumber}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Order ID info
                        Row(
                          children: [
                            const Text('Order ID: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            Expanded(
                              child: Text(
                                item.orderId,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(context, item.orderId, 'Order ID'),
                              child: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Action Buttons: Batalkan & Lanjutkan
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: () => _cancelPayment(context, item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Batalkan',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: () => _resumePayment(context, item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: channelColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Lanjutkan',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
