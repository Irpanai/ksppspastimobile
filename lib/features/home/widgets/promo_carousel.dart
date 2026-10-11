import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../promo/providers/promo_provider.dart';
import '../../promo/screens/promo_screen.dart';

class PromoCarousel extends StatelessWidget {
  const PromoCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    final livePromos = promoProvider.promos;

    final fallbackTitles = [
      'Buka Simpanan Sijaka, Nikmati Nisbah Ekstra!',
      'Info: Penyesuaian Jam Operasional Layanan',
      'Promo Pembiayaan Umroh Tanpa Margin',
    ];

    final itemCount = livePromos.isNotEmpty ? livePromos.length : fallbackTitles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Info & Promo Koperasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PromoScreen()));
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final isLive = livePromos.isNotEmpty;
              final title = isLive ? livePromos[index].judul : fallbackTitles[index];
              final bannerUrl = isLive ? livePromos[index].gambarBanner : null;
              final isPromo = isLive ? livePromos[index].isPromo : true;

              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Base gradient background (always present as fallback)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPromo
                                  ? const [Color(0xFF1B5E20), Color(0xFF388E3C)]
                                  : const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Transform.translate(
                              offset: const Offset(15, 15),
                              child: Icon(
                                isPromo ? Icons.percent_rounded : Icons.campaign_rounded,
                                size: 110,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Live Banner Image from API/Web jika ada
                      if (bannerUrl != null && bannerUrl.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            bannerUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Carousel image error: $error for $bannerUrl');
                              return const SizedBox();
                            },
                          ),
                        ),

                      // Dark bottom gradient overlay for maximum readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // InkWell overlay for click interaction
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PromoScreen()));
                            },
                          ),
                        ),
                      ),

                      // Badge Tag (PROMO / INFORMASI)
                      Positioned(
                        top: 14,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPromo
                                ? const Color(0xFF10B981).withValues(alpha: 0.95)
                                : const Color(0xFF3B82F6).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            isPromo ? 'PROMO' : 'INFORMASI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Title Text
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
