import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart'; 

class BalanceCard extends StatelessWidget {
  const BalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190, // Set fixed height for the horizontal cards
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        clipBehavior: Clip.none,
        children: [
          _buildGreenCard(context),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Simpanan Pokok & Wajib',
            balance: 'Rp 1.000.000',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Simpanan Qurban',
            balance: 'Rp 3.500.000',
            icon: Icons.pets_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGreenCard(BuildContext context) {
    final isVisible = context.select<AppState, bool>((state) => state.isBalanceVisible);
    final Color color1 = Theme.of(context).colorScheme.secondary; // Dark Green
    final Color color2 = Theme.of(context).colorScheme.primary; // Vibrant Green

    return Container(
      width: MediaQuery.of(context).size.width * 0.78, // Slightly wider for a grander feel
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative Abstract Shape 1
            Positioned(
            right: -40,
            top: -40,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Decorative Abstract Shape 2
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.savings_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Simpanan Sukarela',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.read<AppState>().toggleBalanceVisibility(),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Total Saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isVisible ? 'Rp 5.250.000' : 'Rp ••••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+Rp 250.000',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bulan ini',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                    ),
                    const Spacer(),
                    const Icon(Icons.nfc_rounded, color: Colors.white30, size: 28),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWhiteCard(BuildContext context, {required String title, required String balance, required IconData icon}) {
    final isVisible = context.select<AppState, bool>((state) => state.isBalanceVisible);
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.68, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle background icon for modern look
            Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 120,
              color: Colors.grey.shade50,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: const Color(0xFF475569), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Total Saldo',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isVisible ? balance : 'Rp ••••••••',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'No. Rekening',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  '10293847',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
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
