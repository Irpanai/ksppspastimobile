import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../savings/models/simpanan_riwayat_model.dart';
import '../providers/history_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchMutasi();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final provider = context.read<HistoryProvider>();
    switch (_tabController.index) {
      case 0:
        provider.setTipe(null); // Semua
        break;
      case 1:
        provider.setTipe('masuk'); // Masuk
        break;
      case 2:
        provider.setTipe('keluar'); // Keluar
        break;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<HistoryProvider>();
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<HistoryProvider>().fetchMutasi(refresh: true);
  }

  void _showFilterModal(BuildContext context) {
    final provider = context.read<HistoryProvider>();
    String? tempJenis = provider.selectedJenis;
    DateTime? tempStart = provider.startDate;
    DateTime? tempEnd = provider.endDate;

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
                        'Filter Mutasi Rekening',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      if (tempJenis != null || tempStart != null || tempEnd != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempJenis = null;
                              tempStart = null;
                              tempEnd = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Jenis Simpanan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Semua Jenis', tempJenis == null, () {
                        setModalState(() => tempJenis = null);
                      }),
                      _buildFilterChip('Simpanan Pokok', tempJenis == 'pokok', () {
                        setModalState(() => tempJenis = 'pokok');
                      }),
                      _buildFilterChip('Simpanan Wajib', tempJenis == 'wajib', () {
                        setModalState(() => tempJenis = 'wajib');
                      }),
                      _buildFilterChip('Simpanan Sukarela', tempJenis == 'sukarela', () {
                        setModalState(() => tempJenis = 'sukarela');
                      }),
                      _buildFilterChip('Sijaka (Berjangka)', tempJenis == 'sijaka', () {
                        setModalState(() => tempJenis = 'sijaka');
                      }),
                      _buildFilterChip('Bagi Hasil Sijaka', tempJenis == 'sijaka_bagihasil', () {
                        setModalState(() => tempJenis = 'sijaka_bagihasil');
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Rentang Tanggal Transaksi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: tempStart != null && tempEnd != null
                            ? DateTimeRange(start: tempStart!, end: tempEnd!)
                            : null,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Theme.of(context).colorScheme.primary,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempStart = picked.start;
                          tempEnd = picked.end;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tempStart != null && tempEnd != null
                                  ? '${DateFormat('d MMM yyyy', 'id_ID').format(tempStart!)} - ${DateFormat('d MMM yyyy', 'id_ID').format(tempEnd!)}'
                                  : 'Pilih Rentang Tanggal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tempStart != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          if (tempStart != null)
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempStart = null;
                                  tempEnd = null;
                                });
                              },
                              child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.setJenis(tempJenis);
                        provider.setDateRange(tempStart, tempEnd);
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

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final groupedData = historyProvider.groupedByDate;
    final isLoading = historyProvider.isLoading;
    final isLoadingMore = historyProvider.isLoadingMore;
    final error = historyProvider.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header with TabBar
          PremiumHeader(
            title: 'Mutasi Rekening',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: historyProvider.hasActiveFilter
                      ? Colors.amber // Bright color to contrast with the green header
                      : Colors.white,
                  size: 20,
                ),
                onPressed: () => _showFilterModal(context),
              ),
            ],
            bottomWidget: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Semua'),
                  Tab(text: 'Masuk'),
                  Tab(text: 'Keluar'),
                ],
              ),
            ),
          ),

          // Horizontal Quick Filter Badges
          _buildQuickFilterRow(context, historyProvider),

          // Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.primary,
              child: _buildBodyContent(
                isLoading: isLoading,
                isLoadingMore: isLoadingMore,
                error: error,
                groupedData: groupedData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterRow(BuildContext context, HistoryProvider provider) {
    final jenis = provider.selectedJenis;
    final start = provider.startDate;
    final end = provider.endDate;

    if (jenis == null && start == null && end == null) {
      return const SizedBox.shrink(); // Hide if no filters are active
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            const Text('Filter Aktif:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            if (jenis != null) ...[
              _buildRemovableChip(
                context,
                label: _formatJenisLabel(jenis),
                onRemove: () => provider.setJenis(null),
              ),
              const SizedBox(width: 8),
            ],
            if (start != null && end != null) ...[
              _buildRemovableChip(
                context,
                label: '${DateFormat('d MMM yyyy', 'id_ID').format(start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(end)}',
                onRemove: () => provider.setDateRange(null, null),
              ),
              const SizedBox(width: 8),
            ],
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
            color: Colors.black.withOpacity(0.04),
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

  Widget _buildBodyContent({
    required bool isLoading,
    required bool isLoadingMore,
    required String? error,
    required Map<String, List<MutasiSimpananItem>> groupedData,
  }) {
    if (isLoading && groupedData.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (error != null && groupedData.isEmpty) {
      return _buildErrorState(error);
    }

    if (groupedData.isEmpty) {
      return _buildEmptyState();
    }

    final dateKeys = groupedData.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: dateKeys.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == dateKeys.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }

        final dateKey = dateKeys[index];
        final items = groupedData[dateKey] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, idx) => const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final isMasuk = item.isMasuk;

                  return InkWell(
                    onTap: () => _showTransactionDetail(context, item),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMasuk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.keterangan,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_formatJenisLabel(item.jenis)} • ${item.formattedDate}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedNominal,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: isMasuk ? const Color(0xFF059669) : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 90, color: const Color(0xFFF1F5F9)),
                  ],
                ),
              ),
              Container(height: 16, width: 70, color: const Color(0xFFF1F5F9)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Mutasi Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ditemukan catatan mutasi simpanan sesuai filter yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, MutasiSimpananItem item) {
    final isMasuk = item.isMasuk;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMasuk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMasuk ? 'Setoran / Mutasi Masuk' : 'Penarikan / Mutasi Keluar',
                  style: TextStyle(
                    color: isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.formattedNominal,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    color: isMasuk ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),

                // Structured Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('ID Transaksi', '#${item.id}'),
                      _buildDetailRow('Jenis Simpanan', _formatJenisLabel(item.jenis)),
                      _buildDetailRow('Keterangan', item.keterangan),
                      if (item.bulan != null && item.tahun != null)
                        _buildDetailRow('Periode', 'Bulan ${item.bulan} / ${item.tahun}'),
                      _buildDetailRow('Waktu Transaksi', '${item.formattedDate} WIB', isLast: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Tutup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJenisLabel(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'pokok':
        return 'Simpanan Pokok';
      case 'wajib':
        return 'Simpanan Wajib';
      case 'sukarela':
        return 'Simpanan Sukarela';
      case 'sijaka':
        return 'Simpanan Sijaka';
      case 'sijaka_bagihasil':
        return 'Bagi Hasil Sijaka';
      default:
        return 'Simpanan ${jenis.toUpperCase()}';
    }
  }
}
