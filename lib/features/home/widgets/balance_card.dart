import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../main.dart';
import '../providers/dashboard_provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final ringkasan = dashboardProvider.dashboardData?.ringkasanSaldo;
    final statistiks = dashboardProvider.dashboardData?.statistiks;

    final totalSimpanan = ringkasan?.totalSimpanan ?? 0;
    final pokokDanWajib = ringkasan?.saldoPokokDanWajib ?? 0;
    final pokok = ringkasan?.saldoPokok ?? 0;
    final wajib = ringkasan?.saldoWajib ?? 0;
    final sukarela = ringkasan?.saldoSukarela ?? 0;
    final sijaka = ringkasan?.saldoSijaka ?? 0;
    final bagiHasil = ringkasan?.saldoBagihasilSijaka ?? 0;
    final bilyetAktif = statistiks?.jumlahBilyetSijakaAktif ?? 0;

    return SizedBox(
      height: 190, // Set fixed height for the horizontal cards
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        clipBehavior: Clip.none,
        children: [
          _buildGreenCard(
            context,
            totalSimpanan: totalSimpanan,
            bagiHasil: bagiHasil,
          ),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Simpanan Pokok & Wajib',
            balance: AppCurrency.format(pokokDanWajib),
            subtitle: 'P: ${AppCurrency.format(pokok)} • W: ${AppCurrency.format(wajib)}',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Simpanan Sukarela',
            balance: AppCurrency.format(sukarela),
            subtitle: 'Simpanan Transaksional',
            icon: Icons.savings_outlined,
          ),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Simpanan Berjangka',
            balance: AppCurrency.format(sijaka),
            subtitle: '$bilyetAktif Bilyet Aktif',
            icon: Icons.auto_graph_rounded,
          ),
          const SizedBox(width: 16),
          _buildWhiteCard(
            context,
            title: 'Bagi Hasil Sijaka',
            balance: AppCurrency.format(bagiHasil),
            subtitle: 'Akumulasi Bagi Hasil',
            icon: Icons.monetization_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGreenCard(
    BuildContext context, {
    required num totalSimpanan,
    required num bagiHasil,
  }) {
    final isVisible = context.select<AppState, bool>((state) => state.isBalanceVisible);
    final Color color1 = Theme.of(context).colorScheme.secondary; // Dark Green
    final Color color2 = Theme.of(context).colorScheme.primary; // Vibrant Green

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.35),
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
                  color: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.1),
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Total Akumulasi Simpanan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
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
                            color: Colors.white.withValues(alpha: 0.9),
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
                    isVisible ? AppCurrency.format(totalSimpanan) : 'Rp ••••••••',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+ Bagi Hasil: ${AppCurrency.format(bagiHasil)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.verified_user_rounded, color: Colors.white30, size: 24),
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

  Widget _buildWhiteCard(
    BuildContext context, {
    required String title,
    required String balance,
    required String subtitle,
    required IconData icon,
  }) {
    final isVisible = context.select<AppState, bool>((state) => state.isBalanceVisible);

    return Container(
      width: MediaQuery.of(context).size.width * 0.72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Saldo Simpanan',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVisible ? balance : 'Rp ••••••••',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
