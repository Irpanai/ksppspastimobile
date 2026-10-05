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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: screenHeight * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Static Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preview Bukti Transaksi Nisbah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 24),
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
                  child: Column(
                    children: [
                      // Header Image and Logo INSIDE the scroll view
                      Stack(
                        children: [
                          Image.asset(
                            'assets/images/header transaksi nisbah.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                          Positioned(
                            top: 10,
                            left: 32,
                            child: Image.asset(
                              'assets/images/logo billyet.png',
                              height: 75,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),

                            const SizedBox(height: 16),
                            // Badge "TRANSAKSI BERHASIL" with lines
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Row(
                                children: [
                                  const Expanded(child: Divider(color: Color(0xFF10B981), thickness: 0.5)),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF10B981), width: 1),
                                    ),
                                    child: const Text(
                                      'TRANSAKSI BERHASIL',
                                      style: TextStyle(
                                        color: Color(0xFF0E7955),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(child: Divider(color: Color(0xFF10B981), thickness: 0.5)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                      // Rest of content padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
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
                            const SizedBox(height: 24),

                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'KSPPS INOVASI PASTI NUSANTARA\n',
                                    style: TextStyle(fontSize: 10.5, color: Color(0xFF0E7955), fontWeight: FontWeight.w800, height: 1.5),
                                  ),
                                  TextSpan(
                                    text: 'Terima kasih atas kepercayaan Anda. Semoga transaksi ini membawa keberkahan',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      // Footer image full width (outside padding)
                      Image.asset(
                        'assets/images/footer transaksi nisbah.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ],
                  ), // End Column
                ), // End SingleChildScrollView
              ), // End Expanded
              // Bottom Sticky Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Tutup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownloadPdf,
                      icon: _isDownloading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.print_outlined, size: 18),
                      label: Text(
                        _isDownloading ? 'Memproses...' : 'Cetak PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7955),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
