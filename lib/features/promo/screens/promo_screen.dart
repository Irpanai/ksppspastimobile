import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../models/promo_model.dart';
import '../providers/promo_provider.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoProvider>().fetchPromos();
    });
  }

  void _showDetailBottomSheet(BuildContext context, PromoModel promo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Banner Image jika ada
            if (promo.gambarBanner != null && promo.gambarBanner!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  promo.gambarBanner!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Modal promo image error: $error (URL: ${promo.gambarBanner})');
                    return _buildPlaceholderBanner(promo);
                  },
                ),
              )
            else
              _buildPlaceholderBanner(promo),

            const SizedBox(height: 16),

            // Badge & Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryBadge(promo),
                if (promo.tanggalBerakhir != null)
                  Text(
                    'Berlaku s/d ${promo.tanggalBerakhir}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  )
                else if (promo.createdAt != null)
                  Text(
                    promo.createdAt!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Judul
            Text(
              promo.judul,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // Deskripsi
            if (promo.deskripsi != null && promo.deskripsi!.isNotEmpty)
              Text(
                promo.deskripsi!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.6,
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
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
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(PromoModel promo) {
    final isPromo = promo.isPromo;
    final color = isPromo ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final text = isPromo ? 'PROMO' : 'INFORMASI';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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

  Widget _buildPlaceholderBanner(PromoModel promo) {
    final isPromo = promo.isPromo;
    final startColor = isPromo ? const Color(0xFF1B5E20) : const Color(0xFF1E3A8A);
    final endColor = isPromo ? const Color(0xFF388E3C) : const Color(0xFF3B82F6);

    return Container(
      height: 140,
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
              color: Colors.white.withOpacity(0.12),
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
                    color: Colors.white.withOpacity(0.85),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final promos = provider.filteredPromos;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;
    final selectedCategory = provider.selectedCategory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Info & Promo Koperasi'),

          // Filter Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                _buildFilterChip('Semua', selectedCategory == 'Semua', () {
                  provider.setCategory('Semua');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Promo', selectedCategory == 'Promo', () {
                  provider.setCategory('Promo');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Informasi', selectedCategory == 'Informasi', () {
                  provider.setCategory('Informasi');
                }),
              ],
            ),
          ),

          Expanded(
            child: isLoading && promos.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  )
                : errorMessage != null && promos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFDC2626)),
                              const SizedBox(height: 14),
                              Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.fetchPromos(refresh: true),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : promos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
                                SizedBox(height: 12),
                                Text(
                                  'Belum ada info atau promo aktif',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchPromos(refresh: true),
                            color: const Color(0xFF1B5E20),
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(20, 8, 20, 36 + MediaQuery.of(context).padding.bottom),
                              itemCount: promos.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final promo = promos[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _showDetailBottomSheet(context, promo),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Image or Gradient Banner
                                        if (promo.gambarBanner != null && promo.gambarBanner!.isNotEmpty)
                                          Image.network(
                                            promo.gambarBanner!,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 150,
                                                color: const Color(0xFFF1F5F9),
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Card promo image error: $error (URL: ${promo.gambarBanner})');
                                              return _buildPlaceholderBanner(promo);
                                            },
                                          )
                                        else
                                          _buildPlaceholderBanner(promo),

                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildCategoryBadge(promo),
                                                  if (promo.tanggalBerakhir != null)
                                                    Text(
                                                      's/d ${promo.tanggalBerakhir}',
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                                    )
                                                  else if (promo.createdAt != null)
                                                    Text(
                                                      promo.createdAt!,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                promo.judul,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                  height: 1.3,
                                                ),
                                              ),
                                              if (promo.deskripsi != null && promo.deskripsi!.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  promo.deskripsi!,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
