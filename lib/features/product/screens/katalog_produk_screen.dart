import 'package:flutter/material.dart';
import '../../sijaka/screens/sijaka_portfolio_screen.dart';
import '../../../../shared/widgets/premium_header.dart';

class KatalogProdukScreen extends StatelessWidget {
  const KatalogProdukScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey-blue background as in mockup
      body: Column(
        children: [
          const PremiumHeader(title: 'Katalog Produk & Layanan'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            _buildSectionTitle(Icons.account_balance_rounded, 'Simpanan'),
            const SizedBox(height: 20),
            _buildSimpananGrid(context),
            const SizedBox(height: 40),
            _buildSectionTitle(Icons.diamond_outlined, 'Pembiayaan'),
            const SizedBox(height: 20),
            _buildPembiayaanList(context),
            const SizedBox(height: 40),
            _buildSectionTitle(Icons.mosque_outlined, 'Zakat & Infaq'),
            const SizedBox(height: 20),
            _buildZakatCard(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
      ),
    ],
    ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF166534)), // Dark teal
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpananGrid(BuildContext context) {
    final items = [
      {
        'title': 'Simpanan Sukarela (Sirela)',
        'subtitle': 'Simpanan fleksibel dengan akad Wadiah Yad Dhamanah. Bebas disetor dan ditarik kapan saja tanpa potongan biaya.',
        'icon': Icons.payments_outlined,
        'badge': 'Fleksibel',
      },
      {
        'title': 'Simpanan Pendidikan',
        'subtitle': 'Perencanaan dana pendidikan masa depan terencana dan aman untuk putra-putri tercinta.',
        'icon': Icons.school_outlined,
        'badge': 'Terencana',
      },
      {
        'title': 'Simpanan Qurban',
        'subtitle': 'Tabungan teratur dan berkah untuk persiapan ibadah qurban Idul Adha tahunan dengan lebih ringan.',
        'icon': Icons.pets_outlined,
        'badge': 'Ibadah',
      },
      {
        'title': 'Sijaka (Simpanan Berjangka)',
        'subtitle': 'Investasi deposito syariah berjangka dengan bagi hasil bulanan kompetitif dan amanah.',
        'icon': Icons.trending_up_rounded,
        'badge': 'Bagi Hasil',
      },
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (item['title'] == 'Sijaka (Simpanan Berjangka)') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SijakaPortfolioScreen(showBackButton: true)),
                  );
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF166534),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  item['badge'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0E7955),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPembiayaanList(BuildContext context) {
    return Column(
      children: [
        _buildPembiayaanImageCard(
          context,
          title: 'Murabahah',
          subtitle: 'Modal usaha syariah dengan prinsip jual beli transparan.',
          icon: Icons.storefront_outlined,
          imageUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?q=80&w=600&auto=format&fit=crop', // Desk with charts
        ),
        const SizedBox(height: 20),
        _buildPembiayaanImageCard(
          context,
          title: 'Multijasa',
          subtitle: 'Solusi pembiayaan untuk pendidikan dan kesehatan keluarga.',
          icon: Icons.health_and_safety_outlined,
          imageUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=600&auto=format&fit=crop', // Graduation/education
        ),
        const SizedBox(height: 20),
        _buildPembiayaanImageCard(
          context,
          title: 'Ijarah',
          subtitle: 'Sewa menyewa aset produktif untuk kebutuhan bisnis Anda.',
          icon: Icons.vpn_key_outlined,
          imageUrl: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?q=80&w=600&auto=format&fit=crop', // Keys / Property
        ),
      ],
    );
  }

  Widget _buildPembiayaanImageCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String imageUrl}) {
    return Container(
      height: 200, // Fixed height as in mockup
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark Gradient Overlay from bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF064E3B).withOpacity(0.9), // Very dark green at bottom
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Glassmorphism button
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'Ajukan Sekarang',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZakatCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B), // Very dark, deep green
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sucikan Harta,\nBerbagi Berkah',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Salurkan zakat, infaq, dan shadaqah Anda dengan mudah dan tepat sasaran melalui lembaga amil terpercaya.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF064E3B),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Tunaikan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
