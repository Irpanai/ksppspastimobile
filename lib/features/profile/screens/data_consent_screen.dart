import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

/// Halaman Kebijakan Privasi & Kesediaan Penggunaan Data Pribadi Anggota
/// Sesuai Undang-Undang No. 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP)
/// dan Regulasi Kementerian Koperasi & UKM RI.
class DataConsentScreen extends StatelessWidget {
  final VoidCallback? onConsentAccepted;

  const DataConsentScreen({
    super.key,
    this.onConsentAccepted,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Kebijakan Data'),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Notice Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.privacy_tip_rounded, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Persetujuan Penggunaan Data Pribadi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Kepatuhan UU No. 27 Tahun 2022 (UU PDP) • Prinsip Amanah Syariah KSPPS PASTI.\nHarap membaca pernyataan kesediaan pemrosesan data ini dengan seksama sebelum melanjutkan.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 1: Landasan & Komitmen
                    _buildArticleCard(
                      number: '1',
                      title: 'Landasan Hukum & Amanah Syariah',
                      icon: Icons.gavel_rounded,
                      points: const [
                        'KSPPS PASTI berkomitmen penuh menjaga privasi dan kerahasiaan data pribadi Anggota sesuai ketentuan Undang-Undang Republik Indonesia Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP).',
                        'Dalam perspektif syariah, perlindungan data pribadi merupakan bentuk amanah dan penjagaan terhadap hak sesama (Hifzh al-Maal dan Hifzh al-\'Irdh) demi kemaslahatan bersama.',
                        'Pemrosesan data pribadi hanya dilakukan atas dasar persetujuan yang sah, transparan, dan dapat dipertanggungjawabkan kepada Anggota.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 2: Data yang Dikumpulkan
                    _buildArticleCard(
                      number: '2',
                      title: 'Kategori Data Pribadi yang Dikumpulkan',
                      icon: Icons.badge_outlined,
                      points: const [
                        'Data Identitas Resmi: Nomor Induk Kependudukan (NIK), Nama Lengkap sesuai KTP, Tempat dan Tanggal Lahir, Jenis Kelamin, Agama, Pekerjaan, serta Alamat Domisili lengkap.',
                        'Dokumen Verifikasi e-KYC: Foto fisik e-KTP dan foto selfie wajah guna verifikasi identitas resmi, pencegahan pemalsuan akun (anti-fraud), dan memenuhi kepatuhan regulasi Koperasi Simpan Pinjam Syariah.',
                        'Data Kontak & Komunikasi: Nomor telepon seluler aktif (WhatsApp) dan alamat email resmi untuk pengiriman kode verifikasi (OTP), bukti transaksi, dan notifikasi keanggotaan.',
                        'Data Rekening Finansial: Nama bank dan nomor rekening atas nama Anggota yang digunakan untuk penyaluran penarikan simpanan, bagi hasil, serta mutasi simpanan sukarela.',
                        'Data Perangkat & Lokasi: Koordinat lokasi GPS (hanya digunakan saat mencari kantor cabang terdekat atas izin Anggota) dan sensor sidik jari perangkat lokal untuk fitur login biometrik.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 3: Tujuan Penggunaan Data
                    _buildArticleCard(
                      number: '3',
                      title: 'Tujuan Pemrosesan & Penggunaan Data',
                      icon: Icons.checklist_rtl_rounded,
                      points: const [
                        'Verifikasi Keanggotaan: Menilai kelayakan dan memvalidasi calon anggota sebagai pemilik sah rekening simpanan KSPPS PASTI.',
                        'Penyelenggaraan Transaksi Syariah: Memproses setoran Simpanan Pokok, Simpanan Wajib, Simpanan Sukarela (Sirela), dan Simpanan Berjangka (Sijaka) serta penarikan saldo dan pencairan bagi hasil bulanan.',
                        'Keamanan Transaksi & Akun: Mengotentikasi login, PIN transaksi 6-digit, dan verifikasi biometrik sidik jari untuk mencegah transaksi tidak sah.',
                        'Pelaporan Kepatuhan Regulasi: Menyusun laporan agregat kelembagaan kepada Kementerian Koperasi dan UKM RI serta instansi pembina sesuai peraturan perundang-undangan.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 4: Jaminan Keamanan & Perlindungan
                    _buildArticleCard(
                      number: '4',
                      title: 'Kerahasiaan & Keamanan Data (Zero Selling)',
                      icon: Icons.shield_rounded,
                      points: const [
                        'Larangan Penjualan Data: KSPPS PASTI TIDAK AKAN PERNAH menjual, menyewakan, meminjamkan, atau memperdagangkan data pribadi Anggota kepada pihak ketiga manapun untuk keperluan komersial, periklanan, atau telemarketing.',
                        'Enkripsi Data Standar Perbankan: Seluruh pertukaran data antara aplikasi mobile dan server KSPPS PASTI dilindungi enkripsi Secure Sockets Layer / Transport Layer Security (SSL/TLS 256-bit).',
                        'Proteksi Kredensial: Password akun dan PIN Transaksi disimpan dalam bentuk enkripsi satu arah (cryptographic hashing) yang tidak dapat dibaca oleh staf atau pengurus koperasi sekalipun.',
                        'Pencegahan Rekayasa Sosial: KSPPS PASTI tidak pernah meminta Password, PIN, atau kode OTP melalui telepon, SMS, maupun pesan instan pribadi.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 5: Hak Anggota atas Data Pribadi
                    _buildArticleCard(
                      number: '5',
                      title: 'Hak-Hak Anggota atas Data Pribadi',
                      icon: Icons.manage_accounts_outlined,
                      points: const [
                        'Hak Akses & Pembaruan: Anggota berhak melihat dan memperbarui data profil, data alamat domisili, nomor rekening bank, serta data ahli waris melalui menu pengaturan profil di aplikasi.',
                        'Hak Kerahasiaan Riwayat: Anggota berhak atas kerahasiaan seluruh catatan transaksi dan saldo simpanan yang tersimpan dalam sistem koperasi.',
                        'Hak Penghapusan & Pengunduran Diri: Anggota berhak mengajukan permohonan pengunduran diri dan penutupan akun secara resmi melalui menu "Keluar Keanggotaan" sesuai ketentuan AD/ART KSPPS PASTI.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 6: Pernyataan Kesediaan
                    _buildArticleCard(
                      number: '6',
                      title: 'Pernyataan Kesediaan & Persetujuan Sah',
                      icon: Icons.handshake_outlined,
                      points: const [
                        'Dengan mendaftar, mengunggah data e-KYC, dan mencentang persetujuan pada aplikasi Si Hijau by INTIRA, Anggota secara sadar, sukarela, dan tanpa paksaan memberikan kesediaan dan izin kepada KSPPS PASTI untuk memproses data pribadi sesuai ketentuan kebijakan ini.',
                        'Persetujuan ini berlaku selama Anggota terdaftar sebagai anggota aktif KSPPS PASTI atau hingga adanya pengajuan resmi pengunduran diri dari keanggotaan koperasi.',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bottom Agreement Notice Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.verified_rounded, color: primaryColor, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data pribadi Anda terlindungi, amanah, dan terjamin kerahasiaannya dalam ekosistem digital syariah KSPPS PASTI.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF065F46),
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (onConsentAccepted != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onConsentAccepted!();
                          },
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Saya Setuju & Lanjutkan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard({
    required String number,
    required String title,
    required IconData icon,
    required List<String> points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.45,
                      ),
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
}

