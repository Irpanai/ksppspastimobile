import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/rich_article_viewer.dart';
import '../models/promo_model.dart';

/// Badge kategori PROMO / INFORMASI yang digunakan di kartu maupun detail sheet.
class PromoCategoryBadge extends StatelessWidget {
  final PromoModel promo;

  const PromoCategoryBadge({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    final isPromo = promo.isPromo;
    final color = isPromo ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final text = isPromo ? 'PROMO' : 'INFORMASI';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Banner gradien fallback saat gambar banner belum diisi atau gagal dimuat.
class PromoPlaceholderBanner extends StatelessWidget {
  final PromoModel promo;
  final double height;

  const PromoPlaceholderBanner({
    super.key,
    required this.promo,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final isPromo = promo.isPromo;
    final startColor = isPromo ? const Color(0xFF1B5E20) : const Color(0xFF1E3A8A);
    final endColor = isPromo ? const Color(0xFF388E3C) : const Color(0xFF3B82F6);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              isPromo ? Icons.percent_rounded : Icons.campaign_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPromo ? Icons.local_offer_rounded : Icons.info_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  isPromo ? 'Promo Spesial Koperasi' : 'Pemberitahuan Resmi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'KSPPS PASTI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Membuka detail Info / Promo dalam bottom sheet yang dapat di-scroll penuh
/// dan merender konten bergaya berita (bold, italic, daftar, kutipan, & tabel).
void showPromoDetailSheet(BuildContext context, PromoModel promo) {
  final accentColor = promo.isPromo ? const Color(0xFF1B5E20) : const Color(0xFF1D4ED8);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.90;
      final bottomPadding = MediaQuery.of(ctx).padding.bottom;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle & tombol tutup cepat di header modal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                      tooltip: 'Tutup',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // Area konten berita yang dapat di-scroll dengan leluasa
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (promo.gambarBanner != null && promo.gambarBanner!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            promo.gambarBanner!,
                            height: 185,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const AppShimmer(
                                child: AppSkeletonBox(
                                  width: double.infinity,
                                  height: 185,
                                  borderRadius: 16,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Modal promo image error: $error (URL: ${promo.gambarBanner})');
                              return PromoPlaceholderBanner(promo: promo);
                            },
                          ),
                        )
                      else
                        PromoPlaceholderBanner(promo: promo),

                      const SizedBox(height: 16),

                      // Kategori badge & tanggal/periode (responsif agar tidak overflow di font besar)
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            PromoCategoryBadge(promo: promo),
                            if (promo.formattedTanggalBerakhir != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Berlaku s/d ${promo.formattedTanggalBerakhir}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else if (promo.createdAt != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    promo.createdAt!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Headline Judul Berita / Promo
                      Text(
                        promo.judul,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.32,
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // Isi Konten Kaya Format (Bold, Italic, List, Kutipan, Tabel)
                      if (promo.deskripsi != null && promo.deskripsi!.trim().isNotEmpty)
                        RichArticleViewer(
                          content: promo.deskripsi!,
                          accentColor: accentColor,
                        )
                      else
                        const Text(
                          'Tidak ada keterangan tambahan.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ),

              // Tombol Tutup tetap mudah diakses di bagian bawah sheet
              Container(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 18 + bottomPadding),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

