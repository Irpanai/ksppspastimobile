import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class SijakaSubmissionScreen extends StatefulWidget {
  const SijakaSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<SijakaSubmissionScreen> createState() => _SijakaSubmissionScreenState();
}

class _SijakaSubmissionScreenState extends State<SijakaSubmissionScreen> {
  int _selectedTenor = 6;
  String _selectedAro = 'ARO Pokok Saja';
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          const PremiumHeader(title: 'Pengajuan Sijaka'),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: const [
                  Text(
                    'Simpanan Berjangka Syariah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Investasi amanah dengan bagi hasil kompetitif.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionCard(
              title: 'Nominal Simpanan',
              icon: Icons.money_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: '10.000.000',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('*Minimum penempatan Rp 1.000.000', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Pilih Tenor',
              icon: Icons.calendar_today_rounded,
              child: Row(
                children: [
                  _buildTenorOption(1),
                  const SizedBox(width: 12),
                  _buildTenorOption(6),
                  const SizedBox(width: 12),
                  _buildTenorOption(12),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Sistem Perpanjangan (ARO)',
              icon: Icons.autorenew_rounded,
              child: Column(
                children: [
                  _buildAroOption('ARO Pokok Saja', 'Bagi hasil ditransfer ke rekening utama, pokok diperpanjang otomatis.'),
                  const SizedBox(height: 12),
                  _buildAroOption('ARO Pokok + Bagi Hasil', 'Pokok dan bagi hasil diperpanjang otomatis menambah saldo Sijaka.'),
                  const SizedBox(height: 12),
                  _buildAroOption('Non-ARO', 'Pokok dan bagi hasil ditransfer ke rekening utama saat jatuh tempo.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSimulationCard(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (val) => setState(() => _agreed = val!),
                    activeColor: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Saya menyetujui Syarat & Ketentuan pembukaan rekening Sijaka dan akad Mudharabah Mutlaqah.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.5),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _agreed ? () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan Sijaka Berhasil!')));
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534), // Dark Teal
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Ajukan Sijaka Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF166534)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTenorOption(int months) {
    final isSelected = _selectedTenor == months;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTenor = months),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF166534) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF166534) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Text(
                '$months',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bulan',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAroOption(String title, String subtitle) {
    final isSelected = _selectedAro == title;
    return InkWell(
      onTap: () => setState(() => _selectedAro = title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white, // Very light green bg
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF166534) : Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF166534) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF166534) : const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.4)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF166534),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Simulasi Bagi Hasil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Estimasi Nisbah/Bulan', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    SizedBox(height: 4),
                    Text('~Rp 55.000', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Total di Akhir Tenor', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    SizedBox(height: 4),
                    Text('Rp 10.330.000', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Indicative Rate (Equivalent):', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('6.5% p.a', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
