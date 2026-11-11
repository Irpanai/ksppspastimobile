import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../providers/promo_provider.dart';
import '../widgets/promo_detail_sheet.dart';

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
                ? const AppSkeletonPromoList(count: 3)
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
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => showPromoDetailSheet(context, promo),
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
                                              return const AppShimmer(
                                                child: AppSkeletonBox(
                                                  width: double.infinity,
                                                  height: 150,
                                                  borderRadius: 0,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Card promo image error: $error (URL: ${promo.gambarBanner})');
                                              return PromoPlaceholderBanner(promo: promo);
                                            },
                                          )
                                        else
                                          PromoPlaceholderBanner(promo: promo),

                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  PromoCategoryBadge(promo: promo),
                                                  const SizedBox(width: 8),
                                                  if (promo.formattedTanggalBerakhir != null)
                                                    Flexible(
                                                      child: Text(
                                                        's/d ${promo.formattedTanggalBerakhir}',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    )
                                                  else if (promo.createdAt != null)
                                                    Flexible(
                                                      child: Text(
                                                        promo.createdAt!,
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
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
                                              if (promo.plainTextPreview.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  promo.plainTextPreview,
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
                color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
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
