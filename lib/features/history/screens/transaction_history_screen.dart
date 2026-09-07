import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _dummyTransactions = [
    {
      'date': 'Hari Ini',
      'items': [
        {
          'title': 'Setoran Simpanan Sukarela',
          'type': 'in',
          'amount': 250000,
          'time': '14:30',
          'desc': 'Transfer dari Bank Syariah Indonesia',
        },
        {
          'title': 'Pembayaran PPOB - PLN',
          'type': 'out',
          'amount': 52500,
          'time': '09:15',
          'desc': 'Token Listrik Prabayar',
        },
      ]
    },
    {
      'date': 'Kemarin',
      'items': [
        {
          'title': 'Pencairan Pembiayaan',
          'type': 'in',
          'amount': 5000000,
          'time': '16:00',
          'desc': 'Pencairan Multijasa ke Rek. Utama',
        },
        {
          'title': 'Setoran Simpanan Pokok',
          'type': 'in',
          'amount': 100000,
          'time': '10:00',
          'desc': 'Potongan otomatis bulanan',
        },
      ]
    },
    {
      'date': '24 Agustus 2026',
      'items': [
        {
          'title': 'Transfer ke Anggota',
          'type': 'out',
          'amount': 1500000,
          'time': '11:45',
          'desc': 'Transfer ke Bpk. Ahmad',
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Custom Beautiful Header
          PremiumHeader(
            title: 'Mutasi Rekening',
            bottomWidget: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.white.withOpacity(0.8),
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
          
          // Transaction List Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('all'),
                _buildTransactionList('in'),
                _buildTransactionList('out'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String filterType) {
    List<Map<String, dynamic>> filteredData = [];
    for (var group in _dummyTransactions) {
      var filteredItems = (group['items'] as List).where((item) {
        if (filterType == 'all') return true;
        return item['type'] == filterType;
      }).toList();

      if (filteredItems.isNotEmpty) {
        filteredData.add({
          'date': group['date'],
          'items': filteredItems,
        });
      }
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final group = filteredData[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group['date'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group['items'].length,
                separatorBuilder: (context, idx) => const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, idx) {
                  final item = group['items'][idx];
                  final isIn = item['type'] == 'in';
                  return InkWell(
                    onTap: () => _showTransactionDetail(context, item),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isIn ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['time']} • ${item['desc']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isIn ? '+' : '-'}Rp ${item['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isIn ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
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

  void _showTransactionDetail(BuildContext context, Map<String, dynamic> item) {
    final isIn = item['type'] == 'in';
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isIn ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Transaksi Berhasil', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Rp ${item['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36, color: Color(0xFF1E293B), letterSpacing: -1),
              ),
              const SizedBox(height: 32),
              
              // Structured Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9))
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Jenis Transaksi', item['title']),
                    _buildDetailRow('Keterangan', item['desc']),
                    _buildDetailRow('Waktu', '${item['time']} WIB'),
                    _buildDetailRow('No. Referensi', 'INT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', isLast: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Bagikan Resi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
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
}
