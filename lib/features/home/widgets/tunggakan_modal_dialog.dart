import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../payment/screens/top_up_screen.dart';
import '../models/dashboard_model.dart';

class TunggakanModalDialog extends StatelessWidget {
  final DashboardAnggota anggota;

  const TunggakanModalDialog({
    super.key,
    required this.anggota,
  }) : super();

  static Future<void> show(BuildContext context, DashboardAnggota anggota) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TunggakanModalDialog(anggota: anggota),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = anggota.tunggakanWajib;
    final totalNominal = anggota.totalTunggakanWajib > 0
        ? anggota.totalTunggakanWajib
        : list.length * 2500;
    final jumlahBulan = anggota.jumlahBulanMenunggak > 0
        ? anggota.jumlahBulanMenunggak
        : list.length;

    // Ambil bulan pertama dan terakhir jika ada
    int? firstMonth;
    int? lastMonth;
    int? year;
    if (list.isNotEmpty) {
      firstMonth = list.first.bulan;
      lastMonth = list.last.bulan;
      year = list.first.tahun;
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Banner with warm Amber/Rose gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF59E0B)], // Warm Amber-Orange
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 15),
                            SizedBox(width: 5),
                            Text(
                              'STATUS: MENUNGGAK',
                              style: TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tunggakan Simpanan Wajib',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Info
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
                          children: [
                            const TextSpan(text: 'Assalamu\'alaikum, '),
                            TextSpan(
                              text: '${anggota.nama}. ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            TextSpan(
                              text: jumlahBulan > 0
                                  ? 'Anda memiliki kewajiban Simpanan Wajib yang belum terbayar sebanyak '
                                  : 'Anda memiliki kewajiban Simpanan Wajib yang belum terselesaikan.',
                            ),
                            if (jumlahBulan > 0)
                              TextSpan(
                                text: '$jumlahBulan bulan.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Months Box
                      if (list.isNotEmpty) ...[
                        const Text(
                          'Rincian Bulan Tunggakan:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: list.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7), // Warm light amber
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month_outlined, size: 13, color: Color(0xFFB45309)),
                                      const SizedBox(width: 5),
                                      Text(
                                        item.label.isNotEmpty ? item.label : '${item.bulan}/${item.tahun}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '(${AppCurrency.format(item.nominal)})',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF92400E).withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Total Bill Summary
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED), // Light orange background
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Tunggakan',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF7C2D12), fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Simpanan Wajib',
                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF9A3412)),
                                ),
                              ],
                            ),
                            Text(
                              AppCurrency.format(totalNominal),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Educational notice
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pembayaran Simpanan Wajib rutin menjaga status keanggotaan Anda tetap aktif di koperasi.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons (CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TopUpScreen(
                                  initialType: 'simpanan_wajib',
                                  initialStartMonth: firstMonth,
                                  initialEndMonth: lastMonth,
                                  initialYear: year,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_rounded, size: 19),
                              SizedBox(width: 8),
                              Text(
                                'Bayar Tunggakan Sekarang',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Secondary dismiss button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Nanti Saja',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
