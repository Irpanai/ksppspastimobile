import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sijaka_model.dart';

class BuktiTransaksiNisbahDialog extends StatefulWidget {
  final RiwayatBagiHasilItem item;
  final BilyetSijakaItem bilyet;

  const BuktiTransaksiNisbahDialog({
    super.key,
    required this.item,
    required this.bilyet,
  });

  static Future<void> show(BuildContext context, RiwayatBagiHasilItem item, BilyetSijakaItem bilyet) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BuktiTransaksiNisbahDialog(item: item, bilyet: bilyet),
    );
  }

  @override
  State<BuktiTransaksiNisbahDialog> createState() => _BuktiTransaksiNisbahDialogState();
}

class _BuktiTransaksiNisbahDialogState extends State<BuktiTransaksiNisbahDialog> {
  bool _isDownloading = false;

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final token = context.read<AuthProvider>().token ?? await StorageService.getToken();
      final urlString = '${ApiConstants.baseUrl}/sijaka-docs/nisbah-pdf/${widget.item.id}${token != null && token.isNotEmpty ? '?token=$token' : ''}';
      final uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Membuka Bukti Transaksi Bagi Hasil periode ${widget.item.periode}...')),
                ],
              ),
              backgroundColor: const Color(0xFF0E7955),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception('Tidak dapat membuka URL dokumen PDF.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Gagal mendownload bukti: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bilyet = widget.bilyet;
    final authUser = context.watch<AuthProvider>().user;

    final noTransaksi = item.noTransaksi?.isNotEmpty == true
        ? item.noTransaksi!
        : 'TRX-${item.periode.replaceAll('-', '')}${authUser?.noAnggota ?? '001'}';

    final tanggal = item.tanggalTransaksi?.isNotEmpty == true
        ? item.tanggalTransaksi!
        : item.formattedDate;

    final namaAnggota = item.namaAnggota?.isNotEmpty == true
        ? item.namaAnggota!
        : (authUser?.name.isNotEmpty == true ? authUser!.name : 'ANGGOTA');

    final noAnggota = item.noAnggota?.isNotEmpty == true
        ? item.noAnggota!
        : (authUser?.noAnggota ?? '-');

    final periodeLabel = item.periodeLabel?.isNotEmpty == true
        ? item.periodeLabel!
        : 'Periode ${item.periode}';

    final noRekTujuan = (authUser?.anggota?.noRekening?.isNotEmpty == true && authUser!.anggota!.noRekening != '-')
        ? authUser.anggota!.noRekening!
        : ((item.noRekTujuan?.isNotEmpty == true && item.noRekTujuan != '-')
            ? item.noRekTujuan!
            : (bilyet.noRekeningPencairan?.isNotEmpty == true ? bilyet.noRekeningPencairan! : '-'));

    final bankTujuan = item.bankTujuan?.isNotEmpty == true
        ? item.bankTujuan!
        : (authUser?.anggota?.namaBank?.isNotEmpty == true ? authUser!.anggota!.namaBank! : 'BANK SYARIAH INDONESIA');

    final namaRekTujuan = item.namaRekTujuan?.isNotEmpty == true
        ? item.namaRekTujuan!
        : (authUser?.anggota?.atasNamaRekening?.isNotEmpty == true ? authUser!.anggota!.atasNamaRekening! : namaAnggota);

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: screenHeight * 0.90,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header with Green Branding & Close Icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0E7955), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUKTI TRANSAKSI NISBAH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'KSPPS INOVASI PASTI NUSANTARA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Scrollable Document Preview Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: [
                      // Badge "TRANSAKSI BERHASIL"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF0E7955), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'TRANSAKSI BERHASIL',
                              style: TextStyle(
                                color: Color(0xFF0E7955),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 1: DATA TRANSAKSI
                      _buildSectionCard(
                        title: 'DATA TRANSAKSI',
                        icon: Icons.description_outlined,
                        content: Column(
                          children: [
                            _buildInfoRow('No. Transaksi', noTransaksi),
                            _buildDivider(),
                            _buildInfoRow('Tanggal', tanggal),
                            _buildDivider(),
                            _buildInfoRow('Nama Anggota', namaAnggota.toUpperCase()),
                            _buildDivider(),
                            _buildInfoRow('No. Anggota', noAnggota),
                            _buildDivider(),
                            _buildInfoRow('Jenis Transaksi', 'Pembayaran Nisbah'),
                            _buildDivider(),
                            _buildInfoRow('Periode Nisbah', periodeLabel),
                            _buildDivider(),
                            // Nominal Nisbah with green container
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 110,
                                    child: Text(
                                      'Nominal Nisbah',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Text(': ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2F2E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Rp',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0B6343)),
                                          ),
                                          Text(
                                            AppCurrency.format(item.nominalBagihasil).replaceAll('Rp ', ''),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0B6343)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildDivider(),
                            _buildInfoRow('Rekening Sumber', item.rekeningSumber ?? 'KSPPS INTI RAHN NUSANTARA'),
                            _buildDivider(),
                            _buildInfoRow('Rekening Tujuan', bankTujuan),
                            _buildDivider(),
                            _buildInfoRow('Nama Rek. Tujuan', namaRekTujuan.toUpperCase()),
                            _buildDivider(),
                            _buildInfoRow('Keterangan', item.keterangan ?? 'Pemindahbukuan Dana Nisbah'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card 2: RINCIAN PEMINDAHBUKUAN
                      _buildSectionCard(
                        title: 'RINCIAN PEMINDAHBUKUAN',
                        icon: Icons.account_balance_wallet_outlined,
                        content: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Dana telah dipindahbukukan sebesar:',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  // Big Amount Box (Emerald Green)
                                  Expanded(
                                    flex: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF118159),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Rp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(
                                            AppCurrency.format(item.nominalBagihasil).replaceAll('Rp ', ''),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Destination Account Box (Light Mint)
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2F2E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Ke Rekening:', style: TextStyle(fontSize: 9.5, color: Color(0xFF475569))),
                                          const SizedBox(height: 2),
                                          Text(
                                            noRekTujuan,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0B6343)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Atas transaksi pembagian nisbah periode [$periodeLabel].',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card 3: VERIFIKASI TRANSAKSI
                      _buildSectionCard(
                        title: 'VERIFIKASI TRANSAKSI',
                        icon: Icons.verified_user_outlined,
                        content: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.35),
                                    children: [
                                      TextSpan(text: 'Transaksi ini tercatat secara elektronik pada sistem KSPPS INOVASI PASTI NUSANTARA.\n'),
                                      TextSpan(
                                        text: 'Bukti transaksi elektronik — tidak memerlukan tanda tangan.',
                                        style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF0E7955), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'KSPPS INOVASI PASTI NUSANTARA\nTerima kasih atas kepercayaan Anda. Semoga transaksi ini membawa keberkahan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Color(0xFF0E7955), fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action Bar (Download Button)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _handleDownloadPdf,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.file_download_outlined, size: 20),
                        label: Text(
                          _isDownloading ? 'Memproses Dokumen...' : 'Download / Cetak Bukti Bagi Hasil',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7955),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFF0E7955).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2E0D3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Card Header (Dark Green)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF118159),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEDF5F0));
  }
}
