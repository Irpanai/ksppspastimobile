import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../payment/screens/top_up_screen.dart';
import '../models/dashboard_model.dart';

class TunggakanModalDialog extends StatelessWidget {
  final DashboardAnggota anggota;
  final num saldoPokok;

  const TunggakanModalDialog({
    super.key,
    required this.anggota,
    this.saldoPokok = 0,
  }) : super();

  static Future<void> show(BuildContext context, DashboardAnggota anggota, [num saldoPokok = 0]) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TunggakanModalDialog(anggota: anggota, saldoPokok: saldoPokok),
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

    final bool needsActivation = saldoPokok <= 0;
    final Color primaryAccent = needsActivation ? const Color(0xFF0E7955) : const Color(0xFFEA580C);
    final List<Color> headerGradient = needsActivation
        ? const [Color(0xFF0E7955), Color(0xFF10B981)]
        : const [Color(0xFFEA580C), Color(0xFFF59E0B)];

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
                // Top Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: headerGradient,
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
                        child: Center(
                          child: Icon(
                            needsActivation ? Icons.how_to_reg_rounded : Icons.notifications_active_rounded,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              needsActivation ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
                              color: primaryAccent,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                needsActivation ? 'STATUS: BELUM AKTIF' : 'STATUS: MENUNGGAK',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        needsActivation ? 'Aktivasi Keanggotaan' : 'Tunggakan Simpanan Wajib',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                              text: needsActivation
                                  ? 'Selamat bergabung! Silakan bayar Simpanan Pokok dan Simpanan Wajib awal agar akun Anda resmi terdaftar sebagai anggota dengan status Aktif.'
                                  : (jumlahBulan > 0
                                      ? 'Anda memiliki kewajiban Simpanan Wajib yang belum terbayar sebanyak '
                                      : 'Anda memiliki kewajiban Simpanan Wajib yang belum terselesaikan.'),
                            ),
                            if (!needsActivation && jumlahBulan > 0)
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

                      // Months Box / Rincian Kewajiban
                      if (needsActivation) ...[
                        const Text(
                          'Kewajiban Simpanan Pokok:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E7955),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF0E7955)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Simpanan Pokok Awal (1x bayar)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                ),
                              ),
                              Text(
                                'Rp 15.000',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0E7955)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (list.isNotEmpty) ...[
                        Text(
                          needsActivation ? 'Rincian Simpanan Wajib Awal:' : 'Rincian Bulan Tunggakan:',
                          style: const TextStyle(
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
                                      Flexible(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: item.label.isNotEmpty ? item.label : '${item.bulan}/${item.tahun}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF92400E),
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' (${AppCurrency.format(item.nominal)})',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF92400E).withValues(alpha: 0.85),
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                          color: needsActivation ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: needsActivation ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    needsActivation ? 'Total Aktivasi Awal' : 'Total Kewajiban',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: needsActivation ? const Color(0xFF065F46) : const Color(0xFF7C2D12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    needsActivation ? 'Simpanan Pokok & Wajib' : 'Simpanan Wajib',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: needsActivation ? const Color(0xFF047857) : const Color(0xFF9A3412),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppCurrency.format(totalNominal + (needsActivation ? 15000 : 0)),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Educational notice
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              needsActivation
                                  ? 'Bayar Simpanan Pokok & Wajib sekaligus dalam 1 transaksi agar lebih hemat biaya admin dan akun Anda langsung Aktif.'
                                  : 'Pembayaran Simpanan Wajib rutin menjaga status keanggotaan Anda tetap aktif di koperasi.',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
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
                                  initialType: needsActivation ? 'simpanan_pokok_wajib' : 'simpanan_wajib',
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 19),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  needsActivation ? 'Bayar Aktivasi Sekarang' : 'Bayar Tunggakan Sekarang',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
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
