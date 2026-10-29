import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../widgets/gadai_transaction_card.dart';

class GadaiScreen extends StatefulWidget {
  final bool? showBackButton;

  const GadaiScreen({
    super.key,
    this.showBackButton,
  });

  @override
  State<GadaiScreen> createState() => _GadaiScreenState();
}

class _GadaiScreenState extends State<GadaiScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Aktif, 2: Selesai

  final List<Map<String, dynamic>> _allTransactions = [
    {
      'noAkad': 'RHN/2026/08/014',
      'itemName': 'Logam Mulia Antam 5 Gram',
      'category': 'Emas Batangan 24K',
      'taksiran': 'Rp 6.200.000',
      'loanAmount': 'Rp 4.500.000',
      'ujrah': 'Rp 45.000 / bln',
      'dueDate': '15 Sep 2026',
      'status': 'Aktif',
      'icon': Icons.diamond_outlined,
      'color': Color(0xFFD97706),
      'lokasi': 'Brankas Khazanah Cabang Utama',
      'tglAkad': '15 Mei 2026',
    },
    {
      'noAkad': 'RHN/2026/08/022',
      'itemName': 'BPKB Motor Honda Beat 2022',
      'category': 'Kendaraan Bermotor (Roda 2)',
      'taksiran': 'Rp 10.000.000',
      'loanAmount': 'Rp 7.000.000',
      'ujrah': 'Rp 70.000 / bln',
      'dueDate': '20 Sep 2026',
      'status': 'Aktif',
      'icon': Icons.two_wheeler_outlined,
      'color': Color(0xFF047857),
      'lokasi': 'Deposit Box Dokumen Berharga',
      'tglAkad': '20 Mei 2026',
    },
    {
      'noAkad': 'RHN/2026/06/007',
      'itemName': 'Laptop ASUS ROG Strix G15',
      'category': 'Elektronik & Gadget',
      'taksiran': 'Rp 7.500.000',
      'loanAmount': 'Rp 5.000.000',
      'ujrah': 'Rp 50.000 / bln',
      'dueDate': '10 Agu 2026',
      'status': 'Selesai',
      'icon': Icons.laptop_mac_outlined,
      'color': Color(0xFF64748B),
      'lokasi': 'Sudah Diambil Pemilik',
      'tglAkad': '10 Feb 2026',
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilterIndex == 1) {
      return _allTransactions.where((t) => t['status'] == 'Aktif').toList();
    } else if (_selectedFilterIndex == 2) {
      return _allTransactions.where((t) => t['status'] == 'Selesai').toList();
    }
    return _allTransactions;
  }

  void _showAkadInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prinsip Gadai Syariah (Rahn)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Sesuai Fatwa DSN-MUI No. 25/DSN-MUI/III/2002',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '1. Akad Rahn (Jaminan)\nBarang yang Anda jaminkan (Marhun) tetap menjadi milik sah nasabah. Koperasi memegang fisik barang semata-mata sebagai jaminan atas pinjaman (Marhun Bih).\n\n2. Akad Ijarah (Biaya Pemeliharaan)\nKSPPS PASTI tidak mengenakan bunga (bebas riba). Biaya yang timbul hanyalah biaya jasa penyimpanan, keamanan, dan asuransi pemeliharaan barang berdasarkan taksiran barang, bukan berdasar jumlah pinjaman.\n\n3. Perlindungan & Asuransi Marhun\nBarang jaminan Anda disimpan di ruang khazanah brankas tahan api serta dilindungi asuransi syariah penuh.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Saya Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item['icon'] as IconData, size: 28, color: item['color'] as Color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['itemName'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'No. Akad: ${item['noAkad']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Kategori Barang', item['category'] as String),
                  _buildDetailDivider(),
                  _buildDetailRow('Tanggal Akad', item['tglAkad'] as String),
                  _buildDetailDivider(),
                  _buildDetailRow('Nilai Taksiran', item['taksiran'] as String),
                  _buildDetailDivider(),
                  _buildDetailRow('Uang Pinjaman', item['loanAmount'] as String, isHighlight: true),
                  _buildDetailDivider(),
                  _buildDetailRow('Biaya Titip (Ujrah)', item['ujrah'] as String),
                  _buildDetailDivider(),
                  _buildDetailRow('Jatuh Tempo', item['dueDate'] as String),
                  _buildDetailDivider(),
                  _buildDetailRow('Lokasi Penyimpanan', item['lokasi'] as String),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (item['status'] == 'Aktif')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBayarModal(item, isPelunasan: false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF047857),
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Perpanjang Ujrah', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBayarModal(item, isPelunasan: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tebus Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBayarModal(Map<String, dynamic> item, {required bool isPelunasan}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isPelunasan ? 'Konfirmasi Tebus & Pelunasan' : 'Konfirmasi Bayar Ujrah',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              isPelunasan
                  ? 'Anda akan melunasi pokok pinjaman ${item['loanAmount']} untuk mengambil kembali ${item['itemName']}.'
                  : 'Pembayaran biaya pemeliharaan & penyimpanan (${item['ujrah']}) untuk memperpanjang masa gadai selama 30 hari.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF047857), size: 22),
                  const SizedBox(width: 10),
                  const Text('Metode Pembayaran: ', style: TextStyle(fontSize: 12.5, color: Color(0xFF065F46))),
                  const Spacer(),
                  const Text('Saldo Simpanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPelunasan
                                  ? 'Pengajuan tebus ${item['itemName']} berhasil diproses!'
                                  : 'Pembayaran ujrah ${item['itemName']} berhasil!',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF047857),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isPelunasan ? 'Proses Pelunasan' : 'Bayar Sekarang',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAjukanRahnModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ajukan Rahn / Gadai Syariah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dapatkan dana cepat dan berkah dengan menitipkan barang jaminan berharga Anda.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              _buildCategorySelect(),
              const SizedBox(height: 16),
              const Text(
                'Nama & Deskripsi Barang Jaminan',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Contoh: Kalung Emas 10 Gram / BPKB Vario 2021',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Perkiraan Nilai / Kebutuhan Dana (Rp)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Rp 5.000.000',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Pengajuan Gadai Rahn diterima! Petugas penaksir kami akan segera menghubungi Anda.'),
                        backgroundColor: const Color(0xFF047857),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Kirim Pengajuan Gadai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelect() {
    return Row(
      children: [
        _buildCatItem(Icons.diamond_outlined, 'Emas / Logam', true),
        const SizedBox(width: 8),
        _buildCatItem(Icons.two_wheeler_outlined, 'BPKB Kendaraan', false),
        const SizedBox(width: 8),
        _buildCatItem(Icons.laptop_mac_outlined, 'Elektronik', false),
      ],
    );
  }

  Widget _buildCatItem(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? const Color(0xFF047857) : const Color(0xFF64748B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? const Color(0xFF047857) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailDivider() {
    return const Divider(height: 8, thickness: 0.8, color: Color(0xFFF1F5F9));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Premium Header with syariah branding & info icon
          PremiumHeader(
            title: 'Gadai Syariah (Rahn)',
            showBackButton: widget.showBackButton,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                tooltip: 'Informasi Akad Syariah',
                onPressed: _showAkadInfoModal,
              ),
            ],
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. Hero Portfolio Card (Lush Gradient & Syariah Badges)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Watermark Icon
                          Positioned(
                            right: -10,
                            bottom: -15,
                            child: Icon(
                              Icons.handshake_rounded,
                              size: 130,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Tag: Syariah Compliance
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          'Fatwa DSN-MUI Bebas Riba',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Title & Big Value
                              const Text(
                                'Total Pinjaman Rahn Aktif (Marhun Bih)',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Rp 11.500.000',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Secondary Metrics in Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Nilai Taksiran Barang',
                                          style: TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Rp 16.200.000',
                                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 26, color: Colors.white24),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: const [
                                        Text(
                                          'Biaya Pemeliharaan',
                                          style: TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Rp 115.000 / bln',
                                          style: TextStyle(color: Color(0xFFFDE047), fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Quick Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildQuickActionBtn(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Ajukan Rahn',
                          color: primaryColor,
                          onTap: _showAjukanRahnModal,
                        ),
                        const SizedBox(width: 10),
                        _buildQuickActionBtn(
                          icon: Icons.calculate_outlined,
                          label: 'Simulasi Nilai',
                          color: const Color(0xFFD97706),
                          onTap: () {
                            _showAjukanRahnModal();
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildQuickActionBtn(
                          icon: Icons.menu_book_rounded,
                          label: 'Fatwa Akad',
                          color: const Color(0xFF0284C7),
                          onTap: _showAkadInfoModal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Filter Segmented Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _buildFilterTab(0, 'Semua (3)'),
                          _buildFilterTab(1, 'Aktif (2)'),
                          _buildFilterTab(2, 'Selesai (1)'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. List of Transactions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedFilterIndex == 0
                                  ? 'Semua Transaksi Rahn'
                                  : (_selectedFilterIndex == 1 ? 'Daftar Rahn Aktif' : 'Riwayat Telah Ditebus'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${_filteredTransactions.length} Barang',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._filteredTransactions.map((trx) {
                          return GadaiTransactionCard(
                            noAkad: trx['noAkad'] as String,
                            itemName: trx['itemName'] as String,
                            category: trx['category'] as String,
                            taksiran: trx['taksiran'] as String,
                            loanAmount: trx['loanAmount'] as String,
                            ujrah: trx['ujrah'] as String,
                            dueDate: trx['dueDate'] as String,
                            status: trx['status'] as String,
                            iconData: trx['icon'] as IconData,
                            colorTheme: trx['color'] as Color,
                            onTapDetail: () => _showDetailModal(trx),
                            onTapPay: () => _showBayarModal(trx, isPelunasan: false),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Syariah Security Guarantee Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF047857), size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amanah & Terlindungi Asuransi',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Barang jaminan Anda tersimpan di brankas berstandar perbankan syariah dengan asuransi penuh.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String title) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}