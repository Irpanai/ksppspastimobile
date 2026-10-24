import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Tentang Aplikasi'),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                children: [
                  // Logo & Brand Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/logo-kspps-pasti.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/logo.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Si Hijau by INTIRA',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Versi 1.0.1 (Build 2) • Mobile Syariah',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aplikasi Layanan Keuangan Digital KSPPS PASTI yang Amanah, Transparan, dan Modern.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profile Lembaga Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0F766E), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'KSPPS PASTI',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildMiniTag('⚖️ Berizin Kemenkop UKM'),
                            _buildMiniTag('🕌 Pengawasan DSN-MUI'),
                            _buildMiniTag('🛡️ Prinsip Syariah'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Koperasi Simpan Pinjam dan Pembiayaan Syariah (KSPPS) PASTI berkomitmen memberikan solusi finansial yang adil dan memberdayakan seluruh anggota dengan asas tolong-menolong (ta\'awun) dan bebas dari unsur riba.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fitur Utama Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FITUR UTAMA APLIKASI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureRow(
                          icon: Icons.savings_outlined,
                          iconColor: const Color(0xFF0F766E),
                          title: 'Simpanan Syariah Terpadu',
                          desc: 'Sirela (Sukarela), Simpanan Pokok, Simpanan Wajib, dan Investasi Sijaka Berjangka.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Kanal Pembayaran Otomatis 24 Jam',
                          desc: 'Setoran instan via BSI Syariah, BCA, Mandiri, BRI, dan QRIS Nasional.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.auto_graph_rounded,
                          iconColor: const Color(0xFFD97706),
                          title: 'Bagi Hasil & Portofolio Bilyet',
                          desc: 'Monitoring bagi hasil bulanan dan cetak dokumen akad & bilyet secara digital.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFF16A34A),
                          title: 'Standar Keamanan Tinggi',
                          desc: 'Otorisasi PIN transaksi 6-digit, enkripsi data, dan verifikasi e-KTP AI OCR.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Legal & Info Singkat
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Dikembangkan oleh Tim Digitalisasi KSPPS PASTI (INTIRA)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '© 2026 KSPPS PASTI. Seluruh hak cipta dilindungi undang-undang.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}