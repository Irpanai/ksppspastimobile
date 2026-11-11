import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../../core/services/in_app_update_service.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = ApiConstants.appVersion;
  String _buildNumber = ApiConstants.appBuildNumber;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // Jangan timpa jika hasil platform mengembalikan versi lama (misal cache web lama)
      if (mounted && info.version.isNotEmpty && _compareVersion(info.version, ApiConstants.appVersion) >= 0) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  int _compareVersion(String a, String b) {
    try {
      final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final pA = i < aParts.length ? aParts[i] : 0;
        final pB = i < bParts.length ? bParts[i] : 0;
        if (pA > pB) return 1;
        if (pA < pB) return -1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.ksppspasti.mobile');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'Tidak Dapat Membuka Play Store',
            message: 'Tautan Google Play Store tidak dapat dibuka pada perangkat ini.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Gagal Membuka Play Store',
          message: 'Terjadi kesalahan saat membuka Play Store: $e',
        );
      }
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      await InAppUpdateService.checkAndShowUpdateDialog(context, forceCheck: true);
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);

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
                    // 1. Logo & Brand Header Card
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
                                  color: primaryColor.withValues(alpha: 0.15),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              'Versi $_version (Build $_buildNumber) • Mobile Syariah',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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

                    // 2. Profile Lembaga Card
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
                                child: const Icon(Icons.account_balance_rounded, color: primaryColor, size: 20),
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

                    // 3. Catatan Pembaruan Terkini (Play Store Changelog)
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CATATAN PEMBARUAN TERKINI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Rilis v$_version',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildUpdateItem(
                            icon: Icons.qr_code_2_rounded,
                            iconColor: const Color(0xFF9333EA),
                            title: 'Loading QRIS Shimmer Tanpa Kedip',
                            desc: 'Pembayaran QRIS menampilkan skeleton loading shimmer hingga kode QR siap dipindai.',
                          ),
                          const SizedBox(height: 10),
                          _buildUpdateItem(
                            icon: Icons.article_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Info & Promo Rich Content + Tabel',
                            desc: 'Detail info dan promo dapat digulir penuh dengan dukungan teks tebal, miring, dan tabel rapi.',
                          ),
                          const SizedBox(height: 10),
                          _buildUpdateItem(
                            icon: Icons.style_rounded,
                            iconColor: const Color(0xFFD97706),
                            title: 'Desain Banner & Modal Popup Seragam',
                            desc: 'Notifikasi status, peringatan tunggakan, dan dialog konfirmasi serasi di seluruh layar.',
                          ),
                          const SizedBox(height: 10),
                          _buildUpdateItem(
                            icon: Icons.date_range_rounded,
                            iconColor: primaryColor,
                            title: 'Bayar Batch & Pemilih Bulan Modern',
                            desc: 'Deteksi otomatis tunggakan akun dengan tombol lunasi cepat dan bottom sheet 12 bulan.',
                          ),
                          const SizedBox(height: 10),
                          _buildUpdateItem(
                            icon: Icons.verified_user_rounded,
                            iconColor: const Color(0xFF16A34A),
                            title: 'Kepatuhan UU PDP No. 27/2022',
                            desc: 'Persetujuan digital perlindungan data pribadi anggota yang aman dan transparan.',
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isCheckingUpdate ? null : _checkUpdate,
                                  icon: _isCheckingUpdate
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                        )
                                      : const Icon(Icons.sync_rounded, size: 16),
                                  label: const Text('Cek Pembaruan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _openPlayStore,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: const Text('Play Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. Fitur Utama Card (Syariah-compliant Icons, Celengan Babi Diganti)
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
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: primaryColor,
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
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFFD97706),
                            title: 'Bagi Hasil & Portofolio Bilyet',
                            desc: 'Monitoring bagi hasil bulanan dan cetak dokumen akad & bilyet secara digital.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            icon: Icons.verified_user_rounded,
                            iconColor: const Color(0xFF16A34A),
                            title: 'Standar Keamanan Tinggi',
                            desc: 'Otorisasi PIN transaksi 6-digit, enkripsi data, dan verifikasi e-KTP AI OCR.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. Legal & Info Singkat
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

  Widget _buildUpdateItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
      ],
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
