import 'package:flutter/material.dart';
import '../../../../shared/widgets/premium_header.dart';
import '../widgets/gadai_transaction_card.dart';

class GadaiScreen extends StatelessWidget {
  const GadaiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(title: 'Transaksi Gadai', showBackButton: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Summary Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded, color: Colors.orange.shade700, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pinjaman Gadai', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text('Rp 11.500.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Gadai Aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: GadaiTransactionCard(
                      itemName: 'Logam Mulia Antam 5g',
                      loanAmount: 'Rp 4.500.000',
                      dueDate: '15 Sep 2026',
                      status: 'Aktif',
                      iconData: Icons.diamond_outlined,
                      colorTheme: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GadaiTransactionCard(
                      itemName: 'BPKB Motor Honda Beat',
                      loanAmount: 'Rp 7.000.000',
                      dueDate: '20 Sep 2026',
                      status: 'Aktif',
                      iconData: Icons.two_wheeler_outlined,
                      colorTheme: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Riwayat Selesai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: GadaiTransactionCard(
                      itemName: 'Laptop ASUS ROG',
                      loanAmount: 'Rp 5.000.000',
                      dueDate: 'Telah Ditebus',
                      status: 'Selesai',
                      iconData: Icons.laptop_mac_outlined,
                      colorTheme: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Ajukan Gadai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
