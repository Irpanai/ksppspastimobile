import 'package:flutter/material.dart';
import '../../history/screens/transaction_history_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final actions = [
      {'icon': Icons.add_card_rounded, 'label': 'Top Up', 'color': primaryGreen},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transfer', 'color': primaryGreen},
      {'icon': Icons.account_balance_rounded, 'label': 'Tarik Tunai', 'color': primaryGreen},
      {'icon': Icons.receipt_long_rounded, 'label': 'Mutasi', 'color': primaryGreen},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((action) {
          return Column(
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
                    if (action['label'] == 'Mutasi') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                      );
                    }
                  }, 
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action['label'] as String,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
