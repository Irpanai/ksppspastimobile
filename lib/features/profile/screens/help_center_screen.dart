import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../auth/widgets/cabang_map_modal.dart';
import '../../auth/services/cabang_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  Future<void> _openCabangMap() async {
    try {
      final allCabangs = await CabangService.getAllCabangs();
      if (!mounted) return;
      CabangMapModal.show(
        context: context,
        allCabangs: allCabangs,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat peta kantor cabang.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _launchExternal(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka tautan layanan.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Pusat Bantuan'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF065F46), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Butuh Bantuan Layanan?',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tim Customer Service KSPPS PASTI siap membantu transaksi, simpanan, dan informasi akun Anda.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title: Kanal Bantuan
                  _buildSectionHeader('KANAL BANTUAN RESMI', Icons.headset_mic_rounded),
                  const SizedBox(height: 12),

                  // Contact Cards
                  _buildContactCard(
                    title: 'WhatsApp Layanan Anggota',
                    subtitle: 'Respon cepat chat resmi admin KSPPS PASTI',
                    actionText: 'Chat WhatsApp',
                    icon: Icons.chat_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    onTap: () => _launchExternal('https://wa.me/6281234567890?text=Halo%20Admin%20KSPPS%20PASTI,%20saya%20butuh%20bantuan...'),
                  ),
                  const SizedBox(height: 10),

                  _buildContactCard(
                    title: 'Call Center Telepon',
                    subtitle: '(0265) 7524000 • Jam kerja operasional',
                    actionText: 'Hubungi',
                    icon: Icons.phone_in_talk_rounded,
                    iconBg: const Color(0xFFCCFBF1),
                    iconColor: const Color(0xFF0F766E),
                    onTap: () => _launchExternal('tel:02657524000'),
                  ),
                  const SizedBox(height: 10),

                  _buildContactCard(
                    title: 'Email Pengaduan & Bantuan',
                    subtitle: 'layanan@ksppspasti.com',
                    actionText: 'Kirim Email',
                    icon: Icons.mail_outline_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => _launchExternal('mailto:layanan@ksppspasti.com?subject=Pengaduan%20Layanan%20Si%20Hijau'),
                  ),
                  const SizedBox(height: 10),

                  _buildContactCard(
                    title: 'Kunjungi Kantor Cabang Terdekat',
                    subtitle: 'Lihat sebaran lokasi & alamat kantor operasional',
                    actionText: 'Buka Peta',
                    icon: Icons.storefront_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    onTap: _openCabangMap,
                  ),

                  const SizedBox(height: 28),

                  // Section Title: FAQ
                  _buildSectionHeader('PERTANYAAN UMUM (FAQ)', Icons.help_outline_rounded),
                  const SizedBox(height: 12),

                  _buildFaqItem(
                    question: 'Bagaimana cara setor atau top up simpanan?',
                    answer: 'Anda dapat melakukan setor simpanan melalui menu "Setor & Top Up Simpanan". Pilih jenis simpanan (Sirela/Pokok/Wajib), masukkan nominal, lalu pilih metode transfer Virtual Account (BSI, BCA, Mandiri, BRI) atau scan QRIS.',
                  ),
                  _buildFaqItem(
                    question: 'Berapa lama verifikasi setoran Virtual Account & QRIS?',
                    answer: 'Sistem KSPPS PASTI terhubung otomatis 24 jam real-time. Saldo simpanan Anda akan langsung bertambah seketika setelah pembayaran berhasil tanpa perlu konfirmasi manual atau upload bukti transfer.',
                  ),
                  _buildFaqItem(
                    question: 'Bagaimana cara mencairkan saldo Simpanan Sukarela (Sirela)?',
                    answer: 'Pencairan dana Sirela dapat dilakukan kapan saja melalui menu "Tarik Simpanan" ke rekening bank yang sudah Anda daftarkan dan verifikasi pada menu Profil Rekening Bank.',
                  ),
                  _buildFaqItem(
                    question: 'Apa keunggulan Simpanan Berjangka (Sijaka)?',
                    answer: 'Sijaka adalah simpanan investasi syariah dengan akad Mudharabah Mutlaqah. Memberikan bagi hasil kompetitif setiap bulan yang ditransfer otomatis ke saldo Sirela atau rekening bank Anda dengan pilihan tenor 1, 6, atau 12 bulan.',
                  ),
                  _buildFaqItem(
                    question: 'Bagaimana jika lupa PIN Transaksi atau Password?',
                    answer: 'Untuk reset password, gunakan tombol "Lupa Password" pada halaman Login. Untuk mengubah atau mereset PIN transaksi 6-digit, buka menu Profil > Pengaturan Akun & Keamanan > Ganti PIN.',
                  ),

                  const SizedBox(height: 24),

                  // Jam Layanan Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Jam Layanan Kantor Koperasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Senin - Jumat : 08.00 - 15.30 WIB\nSabtu : 08.00 - 12.00 WIB\nMinggu & Hari Libur Nasional : Tutup\n(Layanan Transaksi Digital Aplikasi Si Hijau aktif 24 jam).',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required String actionText,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0F766E)),
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

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: const Color(0xFF0F766E),
          collapsedIconColor: const Color(0xFF94A3B8),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}