import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../payment/screens/top_up_screen.dart';
import '../models/simpanan_riwayat_model.dart';
import '../providers/savings_provider.dart';

class SimpananScreen extends StatelessWidget {
  const SimpananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: 'Simpanan Anda',
              showBackButton: false,
              bottomWidget: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
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
                    Tab(text: 'Pokok'),
                    Tab(text: 'Wajib'),
                    Tab(text: 'Sukarela'),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                physics: BouncingScrollPhysics(),
                children: [
                  _SimpananTabView(
                    jenis: 'pokok',
                    title: 'Pokok',
                    gradientColors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  ),
                  _SimpananTabView(
                    jenis: 'wajib',
                    title: 'Wajib',
                    gradientColors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  _SimpananTabView(
                    jenis: 'sukarela',
                    title: 'Sukarela',
                    gradientColors: [Color(0xFF388E3C), Color(0xFF81C784)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpananTabView extends StatefulWidget {
  final String jenis;
  final String title;
  final List<Color> gradientColors;

  const _SimpananTabView({
    required this.jenis,
    required this.title,
    required this.gradientColors,
  });

  @override
  State<_SimpananTabView> createState() => _SimpananTabViewState();
}

class _SimpananTabViewState extends State<_SimpananTabView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingsProvider>().fetchRiwayat(widget.jenis);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<SavingsProvider>();
      if (provider.hasMore(widget.jenis) && !provider.isLoadingMore(widget.jenis)) {
        provider.loadMore(widget.jenis);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      context.read<SavingsProvider>().fetchRiwayat(widget.jenis, refresh: true),
      context.read<DashboardProvider>().fetchDashboard(refresh: true),
    ]);
  }

  num _getBalance(BuildContext context) {
    final ringkasan = context.watch<DashboardProvider>().dashboardData?.ringkasanSaldo;
    if (ringkasan == null) return 0;
    switch (widget.jenis) {
      case 'pokok':
        return ringkasan.saldoPokok;
      case 'wajib':
        return ringkasan.saldoWajib;
      case 'sukarela':
        return ringkasan.saldoSukarela;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = context.watch<SavingsProvider>();
    final items = savingsProvider.getItems(widget.jenis);
    final isLoading = savingsProvider.isLoading(widget.jenis);
    final isLoadingMore = savingsProvider.isLoadingMore(widget.jenis);
    final error = savingsProvider.getError(widget.jenis);
    final balance = _getBalance(context);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.gradientColors[0],
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Premium Balance Card
            _buildBalanceCard(balance),
            const SizedBox(height: 32),
            // Transaction History Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Mutasi ${widget.title}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Row(
                    children: [
                      if (items.isNotEmpty)
                        Text(
                          '${items.length} Transaksi',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showFilterModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: savingsProvider.hasActiveFilter(widget.jenis) ? widget.gradientColors[0].withOpacity(0.1) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: savingsProvider.hasActiveFilter(widget.jenis) ? widget.gradientColors[0] : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildQuickFilterRow(context, savingsProvider),
            const SizedBox(height: 16),
            // Error, Loading, Empty, or List
            if (isLoading && items.isEmpty)
              _buildLoadingList()
            else if (error != null && items.isEmpty)
              _buildErrorView(error)
            else if (items.isEmpty)
              _buildEmptyState()
            else ...[
              _buildTransactionList(items),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(num balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  'Total Simpanan ${widget.title}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  AppCurrency.format(balance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.jenis == 'pokok'
                        ? 'Simpanan Pokok Anggota'
                        : widget.jenis == 'wajib'
                            ? 'Iuran Bulanan Wajib'
                            : 'Bisa Disetor / Ditarik',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TopUpScreen(initialType: widget.jenis),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_card_rounded, size: 14, color: widget.gradientColors[0]),
                      const SizedBox(width: 4),
                      Text(
                        'Setor',
                        style: TextStyle(
                          color: widget.gradientColors[0],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
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

  Widget _buildErrorView(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<SavingsProvider>().fetchRiwayat(widget.jenis, refresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.gradientColors[0],
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat Transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          Text(
            'Transaksi mutasi simpanan ${widget.title.toLowerCase()} Anda akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<MutasiSimpananItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final item = items[index];
        final isMasuk = item.isMasuk;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTransactionDetail(context, item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMasuk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedDate,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.formattedNominal,
                    style: TextStyle(
                      color: isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetail(BuildContext context, MutasiSimpananItem item) {
    final isMasuk = item.isMasuk;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                isMasuk ? 'Setoran / Masuk' : 'Penarikan / Keluar',
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
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
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
                    _buildDetailRow('Jenis Simpanan', 'Simpanan ${item.jenis.toUpperCase()}'),
                    _buildDetailRow('Keterangan', item.keterangan),
                    if (item.bulan != null && item.tahun != null)
                      _buildDetailRow('Periode', 'Bulan ${item.bulan} / ${item.tahun}'),
                    _buildDetailRow('Waktu Transaksi', '${item.formattedDate} WIB'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.gradientColors[0],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuickFilterRow(BuildContext context, SavingsProvider provider) {
    final tipe = provider.getTipe(widget.jenis);
    final start = provider.getStartDate(widget.jenis);
    final end = provider.getEndDate(widget.jenis);

    if (tipe == null && start == null && end == null) {
      return const SizedBox.shrink(); // Hide if no filters are active
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            const Text('Filter Aktif:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            if (tipe != null) ...[
              _buildRemovableChip(
                context,
                label: tipe == 'masuk' ? 'Masuk' : 'Keluar',
                onRemove: () => provider.setFilter(widget.jenis, tipe: null, start: start, end: end),
              ),
              const SizedBox(width: 8),
            ],
            if (start != null && end != null) ...[
              _buildRemovableChip(
                context,
                label: '${DateFormat('d MMM yyyy', 'id_ID').format(start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(end)}',
                onRemove: () => provider.setFilter(widget.jenis, tipe: tipe, start: null, end: null),
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

  void _showFilterModal(BuildContext context) {
    final provider = context.read<SavingsProvider>();
    String? tempTipe = provider.getTipe(widget.jenis);
    DateTime? tempStart = provider.getStartDate(widget.jenis);
    DateTime? tempEnd = provider.getEndDate(widget.jenis);

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
                        'Filter Mutasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      if (tempTipe != null || tempStart != null || tempEnd != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempTipe = null;
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
                    'Tipe Transaksi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Semua', tempTipe == null, () {
                        setModalState(() => tempTipe = null);
                      }),
                      _buildFilterChip('Masuk', tempTipe == 'masuk', () {
                        setModalState(() => tempTipe = 'masuk');
                      }),
                      _buildFilterChip('Keluar', tempTipe == 'keluar', () {
                        setModalState(() => tempTipe = 'keluar');
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Rentang Tanggal',
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
                                primary: widget.gradientColors[0],
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
                          Icon(Icons.calendar_month_outlined, color: widget.gradientColors[0], size: 20),
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
                        provider.setFilter(widget.jenis, tipe: tempTipe, start: tempStart, end: tempEnd);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.gradientColors[0],
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
      selectedColor: widget.gradientColors[0],
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
