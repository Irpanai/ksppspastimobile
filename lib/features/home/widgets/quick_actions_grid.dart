import 'package:flutter/material.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../payment/screens/top_up_screen.dart';
import '../../payment/screens/tarik_simpanan_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final actions = [
      {'icon': Icons.add_card_rounded, 'label': 'Top Up', 'color': primaryGreen},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Penarikan', 'color': primaryGreen},
      {'icon': Icons.receipt_long_rounded, 'label': 'Mutasi', 'color': primaryGreen},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transfer', 'color': primaryGreen},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions.map((action) {
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (action['label'] == 'Top Up') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TopUpScreen()));
                      } else if (action['label'] == 'Mutasi') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
                      } else if (action['label'] == 'Penarikan') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TarikSimpananScreen()));
                      } else if (action['label'] == 'Transfer') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Transfer segera hadir')));
                      }
                    }, 
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 2,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
