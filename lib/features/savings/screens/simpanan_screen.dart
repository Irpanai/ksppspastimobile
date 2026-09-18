import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../../home/providers/dashboard_provider.dart';
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
                  if (items.isNotEmpty)
                    Text(
                      '${items.length} Transaksi',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
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
            const SizedBox(height: 32),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 28),
          )
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isMasuk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: item.isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.formattedNominal,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: item.isMasuk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.keterangan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('ID Transaksi', '#${item.id}'),
              _buildDetailRow('Jenis Simpanan', 'Simpanan ${item.jenis.toUpperCase()}'),
              _buildDetailRow('Tipe Transaksi', item.isMasuk ? 'Setoran / Masuk' : 'Penarikan / Keluar'),
              if (item.bulan != null && item.tahun != null)
                _buildDetailRow('Periode', 'Bulan ${item.bulan} / ${item.tahun}'),
              _buildDetailRow('Tanggal & Waktu', item.formattedDate),
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
}
