import 'package:flutter/material.dart';
import 'sijaka_submission_screen.dart';
import 'shu_report_screen.dart';
import '../../../../shared/widgets/premium_header.dart';

class SijakaPortfolioScreen extends StatelessWidget {
  const SijakaPortfolioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Portofolio Sijaka',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring status dan rincian Simpanan Berjangka Anda.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
            const SizedBox(height: 24),
            _buildTotalPortfolioCard(context),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SijakaSubmissionScreen()));
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Ajukan Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShuReportScreen()));
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Slip Bilyet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Daftar Bilyet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            _buildBilyetCard(
              context,
              nomor: 'SJ/2024/001',
              nominal: 'Rp 10.000.000',
              tenor: '12 Bulan',
              jatuhTempo: '15 Jan 2025',
              nisbah: '65 : 35',
              isActive: true,
            ),
            const SizedBox(height: 16),
            _buildBilyetCard(
              context,
              nomor: 'SJ/2024/045',
              nominal: 'Rp 25.000.000',
              tenor: '6 Bulan',
              jatuhTempo: '20 Jul 2024',
              nisbah: '60 : 40',
              isActive: true,
            ),
            const SizedBox(height: 16),
            _buildBilyetCard(
              context,
              nomor: 'SJ/2023/112',
              nominal: 'Rp 15.000.000',
              tenor: '12 Bulan',
              jatuhTempo: '15 Jan 2024',
              nisbah: '65 : 35',
              isActive: false,
            ),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }

  Widget _buildTotalPortfolioCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF166534), Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 120,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL PORTFOLIO AKTIF',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rp 50.000.000',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      '3 Bilyet Aktif',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBilyetCard(BuildContext context, {
    required String nomor,
    required String nominal,
    required String tenor,
    required String jatuhTempo,
    required String nisbah,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.transparent),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomor Bilyet', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(nomor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF166534) : const Color(0xFF94A3B8))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF166534).withOpacity(0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Selesai',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF166534) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Nominal', nominal, isActive),
              _buildDetailItem('Tenor', tenor, isActive),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Jatuh Tempo', jatuhTempo, isActive),
              _buildDetailItem(isActive ? 'Nisbah Indikatif' : 'Nisbah Realisasi', nisbah, isActive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isActive) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
