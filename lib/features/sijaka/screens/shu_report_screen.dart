import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class ShuReportScreen extends StatelessWidget {
  const ShuReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish background for the document look
      body: Column(
        children: [
          PremiumHeader(
            title: 'Slip SHU Digital',
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                onPressed: () {},
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.share, size: 14, color: Color(0xFF166534)),
                SizedBox(width: 4),
                Text('DOKUMEN RESMI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Laporan SHU Tahunan 2023', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Rapat Anggota Tahunan (RAT) Tahun Buku 2023', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
              label: const Text('Download PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(140, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 24),
            _buildSlipDocument(context),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: const [
                  Text('Semoga berkah dan bermanfaat.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(height: 4),
                  Text(
                    'Mari tingkatkan simpanan dan pembiayaan untuk SHU\nyang lebih besar tahun depan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }

  Widget _buildSlipDocument(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Top green line
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF166534),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Slip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4), // Light green bg
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF166534), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SLIP PENERIMAAN SHU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          const Text('NO: SHU/2023/10293847', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3), // Light yellow
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline, size: 12, color: Color(0xFFCA8A04)),
                                SizedBox(width: 4),
                                Text('Sudah Diposting ke Sukarela', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFCA8A04))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('TGL: 15 MAR 2024', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Member details box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMemberInfo('Nama Anggota', 'Ahmad Fauzi'),
                      const SizedBox(height: 16),
                      _buildMemberInfo('Nomor Anggota', '10293847'),
                      const SizedBox(height: 16),
                      _buildMemberInfo('Status Keanggotaan', 'Anggota Reguler (Aktif)'),
                      const SizedBox(height: 16),
                      _buildMemberInfo('Cabang', 'KCU Jakarta Pusat'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('RINCIAN PERHITUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 16),
                _buildCalculationRow(Icons.pie_chart_outline, 'Jasa Modal (Simpanan Pokok & Wajib)', 'Rp 1.250.000'),
                const SizedBox(height: 16),
                _buildCalculationRow(Icons.shopping_bag_outlined, 'Jasa Anggota (Partisipasi Pembiayaan)', 'Rp 850.000'),
                const SizedBox(height: 16),
                _buildCalculationRow(Icons.receipt_long_outlined, 'Pajak (0%) - Sesuai Ketentuan PP', 'Rp 0', isItalic: true),
                const SizedBox(height: 24),
                // Total Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), // Very light green
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('TOTAL SHU DITERIMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                      SizedBox(height: 4),
                      Text('Telah dikreditkan ke Rek. Simpanan Sukarela', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 12),
                      Text('Rp 2.100.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Footer & Barcode
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified_outlined, size: 16, color: Color(0xFF166534)),
                          SizedBox(width: 8),
                          Text('Dokumen ini diterbitkan secara otomatis', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Sah tanpa tanda tangan basah.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      const SizedBox(height: 16),
                      // Fake barcode
                      Container(
                        height: 40,
                        width: 150,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/UPC-A-036000291452.svg/1200px-UPC-A-036000291452.svg.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMemberInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildCalculationRow(IconData icon, String label, String amount, {bool isItalic = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF1E293B),
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              fontFamily: 'Courier', // monospaced style for amounts
            ),
          ),
        ),
      ],
    );
  }
}
