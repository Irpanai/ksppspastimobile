import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../models/sijaka_model.dart';
import '../providers/sijaka_provider.dart';
import 'shu_report_screen.dart';
import 'sijaka_submission_screen.dart';

class SijakaPortfolioScreen extends StatefulWidget {
  const SijakaPortfolioScreen({super.key});

  @override
  State<SijakaPortfolioScreen> createState() => _SijakaPortfolioScreenState();
}

class _SijakaPortfolioScreenState extends State<SijakaPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SijakaProvider>().fetchBilyetList();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<SijakaProvider>().fetchBilyetList(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final sijakaProvider = context.watch<SijakaProvider>();
    final bilyetList = sijakaProvider.bilyetList;
    final isLoading = sijakaProvider.isLoading;
    final errorMessage = sijakaProvider.errorMessage;
    final totalModal = sijakaProvider.totalModalAktif;
    final totalAktif = sijakaProvider.totalBilyetAktif;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          PremiumHeader(
            title: 'Portofolio Sijaka',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: sijakaProvider.hasActiveFilter
                      ? Colors.amber
                      : Colors.white,
                  size: 20,
                ),
                onPressed: () => _showFilterModal(context),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring status dan rincian Simpanan Berjangka (Sijaka) Anda.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    _buildTotalPortfolioCard(
                      context,
                      totalModal: totalModal,
                      totalAktif: totalAktif,
                      estimasiBagiHasil: sijakaProvider.totalEstimasiBagiHasil,
                      saldoBagiHasil: sijakaProvider.totalSaldoBagiHasil,
                    ),
                    _buildQuickFilterRow(context, sijakaProvider),
                    const SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: ElevatedButton.icon(
                    //         onPressed: () {
                    //           Navigator.push(context, MaterialPageRoute(builder: (_) => const SijakaSubmissionScreen()));
                    //         },
                    //         icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    //         label: const Text('Ajukan Baru'),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Theme.of(context).colorScheme.primary,
                    //           foregroundColor: Colors.white,
                    //           padding: const EdgeInsets.symmetric(vertical: 14),
                    //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //           elevation: 0,
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 12),
                    //     Expanded(
                    //       child: OutlinedButton.icon(
                    //         onPressed: () {
                    //           Navigator.push(context, MaterialPageRoute(builder: (_) => const ShuReportScreen()));
                    //         },
                    //         icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    //         label: const Text('Laporan SHU'),
                    //         style: OutlinedButton.styleFrom(
                    //           foregroundColor: Theme.of(context).colorScheme.primary,
                    //           side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                    //           padding: const EdgeInsets.symmetric(vertical: 14),
                    //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Bilyet Sijaka',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        if (bilyetList.isNotEmpty)
                          Text(
                            '${bilyetList.length} Bilyet',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoading && bilyetList.isEmpty)
                      _buildLoadingSkeleton()
                    else if (errorMessage != null && bilyetList.isEmpty)
                      _buildErrorView(errorMessage)
                    else if (bilyetList.isEmpty)
                      _buildEmptyState()
                    else
                      ...bilyetList.map((bilyet) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildBilyetCard(context, bilyet: bilyet),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPortfolioCard(
    BuildContext context, {
    required num totalModal,
    required int totalAktif,
    required num estimasiBagiHasil,
    required num saldoBagiHasil,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF067451), // matching the web design color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF067451),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BILYET SIJAKA AKTIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$totalAktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bilyet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.2),
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),
                
                // Total Modal Sijaka
                const Text(
                  'Total Modal Sijaka (Terkunci)',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCurrency.format(totalModal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Akumulasi modal seluruh bilyet aktif',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                
                const SizedBox(height: 20),
                
                // Estimasi Bagi Hasil
                const Text(
                  'Estimasi Bagi Hasil Bulanan',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCurrency.format(estimasiBagiHasil),
                  style: const TextStyle(
                    color: Color(0xFFFBBF24), // Yellow text
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Cair tiap bulan ke kantong hasil',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                
                const SizedBox(height: 20),
                
                // Saldo Kantong
                const Text(
                  'Saldo Kantong Bagi Hasil',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCurrency.format(saldoBagiHasil),
                  style: const TextStyle(
                    color: Color(0xFFFBBF24), // Yellow text
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dapat dicairkan',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilyetCard(BuildContext context, {required BilyetSijakaItem bilyet}) {
    final isActive = bilyet.isActive;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFFE2E8F0) : Colors.transparent, width: 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailModal(context, bilyet),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFECFDF5) : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              size: 22,
                              color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bilyet.namaProduk,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bilyet.noBilyet,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        bilyet.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isActive ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildModernDetailItem('Nominal Modal', bilyet.formattedModal, isActive, isAmount: true),
                          _buildModernDetailItem('Tenor', '${bilyet.tenorBulan} Bulan', isActive),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildModernDetailItem('Jatuh Tempo', bilyet.formattedJatuhTempoDate, isActive),
                          _buildModernDetailItem('Nisbah Bulanan', '${bilyet.persenNisbahBulanan}% / bln', isActive),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.monetization_on_rounded, size: 20, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Saldo Bagi Hasil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      bilyet.formattedSaldoBagiHasil,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailItem(String label, String value, bool isActive, {bool isAmount = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 15 : 13,
              fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700,
              color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 160, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12, width: 100, color: const Color(0xFFF1F5F9)),
                  Container(height: 12, width: 80, color: const Color(0xFFF1F5F9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Bilyet Sijaka',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'Anda belum memiliki Simpanan Berjangka (Sijaka) aktif. Klik Ajukan Baru untuk memulai investasi syariah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(BuildContext context, BilyetSijakaItem initialBilyet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BilyetDetailBottomSheet(bilyetId: initialBilyet.id, initialBilyet: initialBilyet),
    );
  }

  void _showFilterModal(BuildContext context) {
    final provider = context.read<SijakaProvider>();
    String? tempStatus = provider.selectedStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Bilyet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      if (tempStatus != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatus = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status Bilyet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Semua Status', tempStatus == null, () {
                        setModalState(() => tempStatus = null);
                      }),
                      _buildFilterChip('Aktif', tempStatus == 'aktif', () {
                        setModalState(() => tempStatus = 'aktif');
                      }),
                      _buildFilterChip('Lunas', tempStatus == 'lunas', () {
                        setModalState(() => tempStatus = 'lunas');
                      }),
                      _buildFilterChip('Cair', tempStatus == 'cair', () {
                        setModalState(() => tempStatus = 'cair');
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.setStatus(tempStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Terapkan Filter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildQuickFilterRow(BuildContext context, SijakaProvider provider) {
    final status = provider.selectedStatus;

    if (status == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            const Text('Filter Aktif:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            _buildRemovableChip(
              context,
              label: 'Status: ${status.toUpperCase()}',
              onRemove: () => provider.setStatus(null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableChip(BuildContext context, {required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BilyetDetailBottomSheet extends StatefulWidget {
  final int bilyetId;
  final BilyetSijakaItem initialBilyet;

  const _BilyetDetailBottomSheet({
    required this.bilyetId,
    required this.initialBilyet,
  });

  @override
  State<_BilyetDetailBottomSheet> createState() => _BilyetDetailBottomSheetState();
}

class _BilyetDetailBottomSheetState extends State<_BilyetDetailBottomSheet> {
  BilyetSijakaDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await context.read<SijakaProvider>().fetchBilyetDetail(widget.bilyetId);
      if (mounted) {
        setState(() {
          _detail = detail;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bilyet = _detail?.bilyet ?? widget.initialBilyet;
    final riwayat = _detail?.riwayatBagihasil ?? [];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            bilyet.namaProduk,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              bilyet.noBilyet,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Informasi Akad Bilyet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _buildModernRow('Nominal Modal', bilyet.formattedModal, isAmount: true),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          
                          _buildModernRow(
                            'Nomor Akad', 
                            bilyet.noAkad?.isNotEmpty == true ? bilyet.noAkad! : '-'
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          
                          _buildModernRow(
                            'No. Permohonan', 
                            bilyet.noPemohonan?.isNotEmpty == true ? bilyet.noPemohonan! : '-'
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          
                          _buildModernRow('Tenor Simpanan', '${bilyet.tenorBulan} Bulan'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          _buildModernRow('Tanggal Setor', bilyet.formattedSetorDate),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          _buildModernRow('Jatuh Tempo', bilyet.formattedJatuhTempoDate),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          _buildModernRow('Nisbah Bulanan', '${bilyet.persenNisbahBulanan}% / bln'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          _buildModernRow('Metode Penyerahan', bilyet.metodePenyerahanBagihasil),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          
                          _buildModernRow(
                            'No. Rekening Pencairan', 
                            bilyet.noRekeningPencairan?.isNotEmpty == true ? bilyet.noRekeningPencairan! : '-'
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                          
                          _buildModernRow('Status Bilyet', bilyet.status.toUpperCase(), isStatus: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Riwayat Bagi Hasil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Total: ${bilyet.formattedTotalBagiHasil}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Gagal memuat rincian bagi hasil: $_error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      )
                    else if (riwayat.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 32, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat',
                              style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pencairan bagi hasil akan tampil di sini',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          final item = riwayat[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.monetization_on_rounded, size: 18, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Periode ${item.periode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      Text(item.formattedDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.formattedNominal,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: const Color(0xFFF1F5F9), width: 1)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement cetak bilyet
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: const Text('Cetak Bilyet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7955), // match green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement cetak akad
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: const Text('Cetak Akad & Formulir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED), // match purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRow(String label, String value, {bool isAmount = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label, 
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)
            ),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
                  color: isAmount ? const Color(0xFF059669) : const Color(0xFF0F172A),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
