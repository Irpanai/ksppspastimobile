import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../main.dart';
import '../providers/dashboard_provider.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final ringkasan = dashboardProvider.dashboardData?.ringkasanSaldo;
    final statistiks = dashboardProvider.dashboardData?.statistiks;

    final totalSimpanan = ringkasan?.totalSimpanan ?? 0;
    final pokokDanWajib = ringkasan?.saldoPokokDanWajib ?? 0;
    final sukarela = ringkasan?.saldoSukarela ?? 0;
    final sijaka = ringkasan?.saldoSijaka ?? 0;
    final bagiHasil = ringkasan?.saldoBagihasilSijaka ?? 0;
    final bilyetAktif = statistiks?.jumlahBilyetSijakaAktif ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildGreenCard(
                  context,
                  title: 'Total Akumulasi Simpanan',
                  balance: totalSimpanan,
                  extraInfo: '+ Bagi Hasil: ${AppCurrency.format(bagiHasil)}',
                  icon: Icons.account_balance_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildGreenCard(
                  context,
                  title: 'Total Simpanan Anggota',
                  balance: pokokDanWajib + sukarela,
                  extraInfo: 'Pokok, Wajib & Sukarela',
                  icon: Icons.savings_rounded,
                  colorOverride: const [Color(0xFF14532D), Color(0xFF166534)], // Dark Green
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildGreenCard(
                  context,
                  title: 'Simpanan Berjangka (Sijaka)',
                  balance: sijaka,
                  extraInfo: '$bilyetAktif Bilyet Aktif',
                  icon: Icons.auto_graph_rounded,
                  colorOverride: const [Color(0xFF047857), Color(0xFF10B981)], // Emerald/Teal Green
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0), // increased margin for easier tapping
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGreenCard(
    BuildContext context, {
    required String title,
    required num balance,
    required String extraInfo,
    required IconData icon,
    List<Color>? colorOverride,
  }) {
    final isVisible = context.select<AppState, bool>((state) => state.isBalanceVisible);
    
    final Color color1 = colorOverride != null ? colorOverride[0] : Theme.of(context).colorScheme.secondary;
    final Color color2 = colorOverride != null ? colorOverride[1] : Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
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
                            child: Icon(icon, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: const TextStyle(
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
                    isVisible ? AppCurrency.format(balance) : 'Rp ••••••••',
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              extraInfo,
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
}
