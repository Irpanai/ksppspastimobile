import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promos = [
      {
        'title': 'Buka Simpanan Sijaka, Nikmati Nisbah Ekstra!',
        'date': '12 Okt 2026',
        'desc': 'Dapatkan tambahan nisbah bagi hasil hingga 2% khusus untuk pembukaan rekening Sijaka (Simpanan Berjangka) di bulan ini. Syarat dan ketentuan berlaku.',
        'image': 'https://picsum.photos/seed/21/640/320',
        'category': 'Promo',
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Info: Penyesuaian Jam Operasional Libur Nasional',
        'date': '05 Okt 2026',
        'desc': 'Sehubungan dengan hari libur nasional, kantor layanan KSPPS PASTI akan beroperasi setengah hari pada tanggal 10 Oktober 2026.',
        'image': 'https://picsum.photos/seed/22/640/320',
        'category': 'Informasi',
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Promo Pembiayaan Umroh Tanpa Margin',
        'date': '28 Sep 2026',
        'desc': 'Wujudkan niat suci Anda ke Baitullah dengan program pembiayaan umroh khusus anggota tanpa margin selama periode promo.',
        'image': 'https://picsum.photos/seed/23/640/320',
        'category': 'Promo',
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Rapat Anggota Tahunan (RAT) 2025/2026',
        'date': '15 Sep 2026',
        'desc': 'Undangan kepada seluruh anggota KSPPS PASTI untuk menghadiri RAT yang akan diselenggarakan secara hybrid (online & offline).',
        'image': 'https://picsum.photos/seed/24/640/320',
        'category': 'Berita',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Info & Promo Koperasi'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: promos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // Detail page if any
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(promo['image'] as String),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (promo['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      promo['category'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: promo['color'] as Color,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    promo['date'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                promo['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['desc'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
