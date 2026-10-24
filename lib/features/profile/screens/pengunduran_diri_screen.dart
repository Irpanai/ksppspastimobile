import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_dialog.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/premium_header.dart';
import '../providers/profile_provider.dart';

class PengunduranDiriScreen extends StatefulWidget {
  const PengunduranDiriScreen({super.key});

  @override
  State<PengunduranDiriScreen> createState() => _PengunduranDiriScreenState();
}

class _PengunduranDiriScreenState extends State<PengunduranDiriScreen> {
  final _confirmController = TextEditingController();
  final String _targetText = 'SAYA YAKIN UNTUK MENGUNDURKAN DIRI';
  bool _isTextMatching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchPengunduranStatus();
    });

    _confirmController.addListener(() {
      final isMatch = _confirmController.text.trim() == _targetText;
      if (isMatch != _isTextMatching) {
        setState(() {
          _isTextMatching = isMatch;
        });
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitPengunduran() async {
    final confirm = await AppDialog.showConfirmation(
      context,
      title: 'Konfirmasi Pengunduran Diri',
      message: 'Apakah Anda benar-benar yakin ingin mengajukan pengunduran diri dari keanggotaan KSPPS PASTI?\n\nTindakan ini akan memproses pencairan hak simpanan dan menonaktifkan seluruh layanan koperasi Anda.',
      confirmText: 'Ya, Ajukan',
      cancelText: 'Batal',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFDC2626),
      iconBgColor: const Color(0xFFFEE2E2),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final provider = context.read<ProfileProvider>();
    final success = await provider.ajukanPengunduranDiri(_confirmController.text.trim());

    if (!mounted) return;
    if (success) {
      _confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pengajuan berhasil dikirim! Menunggu persetujuan petugas.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.errorMessage ?? 'Gagal mengajukan pengunduran diri.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final status = provider.pengunduranStatus;
    final isLoading = provider.isPengunduranLoading;
    final isSubmitting = provider.isSubmittingPengunduran;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header curved konsisten dengan menu lainnya
          const PremiumHeader(
            title: 'Keluar Keanggotaan',
            showBackButton: true,
          ),

          // Konten Body
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: isLoading && status == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0E7955)),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchPengunduranStatus(),
                      color: const Color(0xFF0E7955),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Keanggotaan Card
                          if (status != null) _buildStatusHeader(status),

                          const SizedBox(height: 16),

                          // Ringkasan Hak Simpanan Card
                          if (status != null) _buildHakSimpananCard(status),

                          const SizedBox(height: 16),

                          // Ketentuan Sesuai AD/ART Card
                          _buildKetentuanCard(),

                          const SizedBox(height: 16),

                          // Formulir Pengajuan / Notice Status
                          if (status != null && !status.isKeluar && !status.hasPending)
                            _buildFormPengajuan(isSubmitting)
                          else if (status != null && status.hasPending)
                            _buildPendingNotice(status)
                          else if (status != null && status.isKeluar)
                            _buildKeluarNotice(),

                          const SizedBox(height: 16),

                          // Riwayat Pengajuan
                          if (status != null && status.riwayat.isNotEmpty)
                            _buildRiwayatSection(status),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(dynamic status) {
    Color iconBg;
    Color iconColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;
    String badgeText;
    Color badgeBg;
    Color badgeTextColor;

    if (status.isKeluar) {
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
      statusTitle = 'Keanggotaan Nonaktif';
      statusSubtitle = 'Status Anda telah keluar dari KSPPS PASTI';
      badgeText = 'NONAKTIF';
      badgeBg = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
    } else if (status.hasPending) {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.hourglass_top_rounded;
      statusTitle = 'Pengajuan Dalam Proses';
      statusSubtitle = 'Menunggu verifikasi dan persetujuan pengurus';
      badgeText = 'DIPROSES';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
    } else {
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
      icon = Icons.verified_user_rounded;
      statusTitle = 'Status: Anggota Aktif';
      statusSubtitle = 'Keanggotaan Anda terdaftar resmi di KSPPS PASTI';
      badgeText = 'AKTIF';
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: badgeTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHakSimpananCard(dynamic status) {
    final ringkasan = status.ringkasanSaldo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0E7955), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi Pengembalian Simpanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'Akumulasi saldo simpanan yang dapat dicairkan',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Detail Rincian
          _buildRowSimpanan('Simpanan Pokok', ringkasan.saldoPokok, Icons.lock_outline_rounded),
          _buildRowSimpanan('Simpanan Wajib', ringkasan.saldoWajib, Icons.calendar_month_outlined),
          _buildRowSimpanan('Simpanan Sukarela (Sirela)', ringkasan.saldoSukarela, Icons.savings_outlined),
          if (ringkasan.saldoSijaka > 0)
            _buildRowSimpanan('Modal Sijaka Aktif', ringkasan.saldoSijaka, Icons.inventory_2_outlined),

          const SizedBox(height: 14),

          // Highlight Box Total Dana Dikembalikan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Dana Dikembalikan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hak pencairan dana anggota',
                      style: TextStyle(fontSize: 11, color: Color(0xFF4ADE80)),
                    ),
                  ],
                ),
                Text(
                  AppCurrency.format(ringkasan.totalKembali),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Note Info Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dana simpanan akan dicairkan dan ditransfer sesuai prosedur setelah diverifikasi oleh FO dan disetujui Pengurus/Finance.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowSimpanan(String title, double amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            AppCurrency.format(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildKetentuanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketentuan Sesuai AD/ART',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'Anggaran Dasar & Rumah Tangga KSPPS',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          _buildNumberedCondition(
            1,
            'Hak Suara & Keanggotaan',
            'Hak suara dan keikutsertaan dalam Rapat Anggota Tahunan (RAT) akan berakhir secara permanen.',
          ),
          const SizedBox(height: 12),
          _buildNumberedCondition(
            2,
            'Penutupan Fasilitas',
            'Seluruh rekening simpanan, fasilitas pembiayaan, dan layanan mobile akan ditutup secara permanen.',
          ),
          const SizedBox(height: 12),
          _buildNumberedCondition(
            3,
            'Prosedur Verifikasi',
            'Pengajuan akan diverifikasi oleh FO/Customer Service dan disetujui oleh Finance / Pimpinan Cabang.',
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedCondition(int number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$number',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormPengajuan(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_late_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formulir Konfirmasi Pengajuan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B)),
                    ),
                    Text(
                      'Konfirmasi persetujuan keluar keanggotaan',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          const Text(
            'Untuk melanjutkan pengunduran diri, silakan ketik kalimat konfirmasi berikut dengan persis:',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),

          // Kotak Teks Target Konfirmasi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFF9F1239)),
                    SizedBox(width: 6),
                    Text(
                      'KALIMAT KONFIRMASI WAJIB:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _targetText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _targetText));
                      _confirmController.text = _targetText;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teks disalin dan ditempel ke kolom input!'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDA4AF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Text(
                            'Salin & Tempel Kalimat',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input TextField
          const Text(
            'Ketik Ulang Kalimat Di Sini *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmController,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Ketik atau tempel kalimat di sini...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isTextMatching ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                  width: _isTextMatching ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isTextMatching ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  width: 2.0,
                ),
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 20),
              suffixIcon: _isTextMatching
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22)
                  : (_confirmController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () => _confirmController.clear(),
                        )
                      : null),
            ),
          ),
          const SizedBox(height: 6),

          // Helper / Validation Status Text
          if (_isTextMatching)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                SizedBox(width: 4),
                Text(
                  'Kalimat konfirmasi sesuai, tombol pengajuan aktif.',
                  style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            )
          else
            const Text(
              '* Kalimat harus persis sama termasuk spasi dan huruf kapital.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),

          const SizedBox(height: 20),

          // Tombol Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isTextMatching && !isSubmitting ? _submitPengunduran : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: _isTextMatching ? 2 : 0,
                shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.3),
              ),
              icon: isSubmitting
                  ? const SizedBox()
                  : const Icon(Icons.logout_rounded, size: 18),
              label: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text(
                      'Ajukan Pengunduran Diri',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotice(dynamic status) {
    final pending = status.pendingPengajuan;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Dalam Peninjauan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                    ),
                    Text(
                      'Sedang diproses oleh pengurus koperasi',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Pengajuan pengunduran diri Anda pada tanggal ${pending?.createdAt ?? '-'} saat ini sedang dalam proses verifikasi oleh tim Customer Service / Finance KSPPS.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.5),
          ),
          if (pending?.catatan != null && pending!.catatan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Text(
                'Catatan: ${pending.catatan}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeluarNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Keanggotaan Anda Telah Berakhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Status Anda telah tercatat keluar dari keanggotaan KSPPS PASTI. Jika ingin bergabung kembali di masa depan, silakan kunjungi kantor cabang terdekat.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatSection(dynamic status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Pengajuan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),
        ...status.riwayat.map<Widget>((item) {
          final isApproved = item.status == 'approved';
          final isRejected = item.status == 'rejected';
          final badgeColor = isApproved
              ? const Color(0xFF16A34A)
              : isRejected
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFD97706);
          final badgeBg = isApproved
              ? const Color(0xFFDCFCE7)
              : isRejected
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFFEF3C7);
          final statusLabel = isApproved
              ? 'DISETUJUI'
              : isRejected
                  ? 'DITOLAK'
                  : 'MENUNGGU';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.createdAt ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      if (item.catatan != null && item.catatan!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.catatan!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
