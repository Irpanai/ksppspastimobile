import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Syarat & Ketentuan'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Ketentuan Layanan KSPPS PASTI',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pembaruan Terakhir: Oktober 2026 • Versi 1.0\nHarap membaca ketentuan keanggotaan dan transaksi keuangan syariah ini secara seksama.',
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

                  // Section 1: Keanggotaan
                  _buildArticleCard(
                    number: '1',
                    title: 'Keanggotaan Koperasi Syariah',
                    icon: Icons.people_alt_outlined,
                    points: const [
                      'Anggota KSPPS PASTI adalah Warga Negara Indonesia (WNI) yang telah mendaftar, melengkapi verifikasi identitas (e-KTP & Foto Selfie Wajah), serta disetujui oleh pengurus koperasi.',
                      'Simpanan Pokok wajib disetorkan sekali di awal keanggotaan dan merupakan bukti sah keanggotaan koperasi yang tidak dapat ditarik selama masih menjadi anggota aktif.',
                      'Simpanan Wajib disetorkan secara rutin setiap bulan sesuai nominal yang ditetapkan dalam Anggaran Dasar dan Anggaran Rumah Tangga (AD/ART) Koperasi.',
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Section 2: Simpanan & Akad Syariah
                  _buildArticleCard(
                    number: '2',
                    title: 'Akad & Pengelolaan Simpanan',
                    icon: Icons.mosque_outlined,
                    points: const [
                      'Simpanan Sukarela (Sirela): Dikelola dengan akad Wadi\'ah Yad Dhamanah (titipan amanah). Saldo bebas disetor dan ditarik sewaktu-waktu tanpa potongan biaya administrasi bulanan.',
                      'Simpanan Berjangka (Sijaka): Dikelola dengan akad Mudharabah Mutlaqah (investasi bagi hasil). Modal simpanan disalurkan pada pembiayaan sektor produktif halal, dengan nisbah bagi hasil yang dibagikan setiap bulan sesuai tenor (1, 6, atau 12 bulan).',
                      'Seluruh produk simpanan diawasi oleh Dewan Pengawas Syariah (DPS) dan terbebas dari unsur Riba, Gharar, dan Maysir.',
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Section 3: Keamanan Akun
                  _buildArticleCard(
                    number: '3',
                    title: 'Keamanan Akun & Transaksi Digital',
                    icon: Icons.security_rounded,
                    points: const [
                      'Anggota bertanggung jawab penuh atas kerahasiaan Password, PIN Transaksi 6-digit, dan kode verifikasi (OTP) yang dikirimkan ke nomor ponsel terdaftar.',
                      'Seluruh transaksi yang diotorisasi menggunakan PIN Transaksi atau Password yang valid dianggap sebagai instruksi sah dan mengikat dari Anggota pemilik akun.',
                      'Petugas KSPPS PASTI tidak pernah meminta Password, PIN, atau kode OTP Anggota dalam kondisi apa pun.',
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Section 4: Penyetoran & Pencairan
                  _buildArticleCard(
                    number: '4',
                    title: 'Penyetoran & Pencairan Saldo',
                    icon: Icons.account_balance_wallet_outlined,
                    points: const [
                      'Penyetoran melalui Virtual Account (BSI, BCA, Mandiri, BRI) dan QRIS diproses secara otomatis real-time 24 jam.',
                      'Pencairan dana simpanan dilakukan ke nomor rekening bank yang terdaftar dan telah diverifikasi atas nama Anggota sendiri demi keamanan dan pencegahan penyalahgunaan dana.',
                      'Koperasi berhak membatalkan atau menunda transaksi yang terindikasi mencurigakan atau melanggar ketentuan hukum yang berlaku.',
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Section 5: Perubahan Ketentuan
                  _buildArticleCard(
                    number: '5',
                    title: 'Perubahan Regulasi & Ketentuan',
                    icon: Icons.gavel_rounded,
                    points: const [
                      'KSPPS PASTI berhak memperbarui dan menyelaraskan Syarat & Ketentuan ini sewaktu-waktu sesuai dengan regulasi Kementerian Koperasi dan UKM serta fatwa Dewan Syariah Nasional (DSN-MUI).',
                      'Pemberitahuan perubahan penting akan disampaikan melalui pengumuman resmi di aplikasi atau pesan siaran kepada Anggota.',
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom Agreement Box
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
                        Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dengan menggunakan aplikasi Si Hijau by INTIRA, Anggota dianggap telah membaca, memahami, dan menyetujui seluruh Syarat & Ketentuan ini.',
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
                ],
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