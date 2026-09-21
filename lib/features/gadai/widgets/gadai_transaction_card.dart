import 'package:flutter/material.dart';

class GadaiTransactionCard extends StatelessWidget {
  final String itemName;
  final String loanAmount;
  final String dueDate;
  final String status;
  final IconData iconData;
  final Color colorTheme;

  const GadaiTransactionCard({
    required this.itemName,
    required this.loanAmount,
    required this.dueDate,
    required this.status,
    required this.iconData,
    this.colorTheme = const Color(0xFF388E3C),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'Aktif';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive ? colorTheme.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 24, color: isActive ? colorTheme : const Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pinjaman: $loanAmount',
                        style: TextStyle(fontSize: 13, color: isActive ? const Color(0xFFDC2626) : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
          if (isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text('Jatuh Tempo: $dueDate', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Emerald green
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Gadai Selesai / Ditebus', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
