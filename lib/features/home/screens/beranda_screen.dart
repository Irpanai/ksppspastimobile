import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/ppob_menu.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/sijaka_portfolio_card.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DashboardProvider>().fetchDashboard(refresh: true),
      context.read<AuthProvider>().fetchProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Stack(
            children: [
              // Background Header with dark green
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomAppBar(context),
                    if (dashboardProvider.errorMessage != null)
                      _buildErrorBanner(context, dashboardProvider.errorMessage!),
                    const SizedBox(height: 24),
                    const BalanceCard(),
                    const SizedBox(height: 32),
                    const QuickActionsGrid(),
                    const SizedBox(height: 32),
                    const PPOBMenu(),
                    const SizedBox(height: 32),
                    const PromoCarousel(),
                    const SizedBox(height: 32),
                    const SijakaPortfolioCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => context.read<DashboardProvider>().fetchDashboard(refresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final dashboardAnggota = context.watch<DashboardProvider>().dashboardData?.anggota;

    final displayName = dashboardAnggota?.nama.isNotEmpty == true
        ? dashboardAnggota!.nama
        : (authUser?.name.isNotEmpty == true ? authUser!.name : 'Nasabah');

    final status = dashboardAnggota?.status ?? authUser?.statusKeanggotaan ?? 'Aktif';
    final noAnggota = dashboardAnggota?.noAnggota ?? authUser?.noAnggota ?? '';
    final cabang = dashboardAnggota?.cabang ?? authUser?.cabang ?? 'Pusat';

    final photoUrl = authUser?.profilePhotoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $displayName!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      noAnggota.isNotEmpty
                          ? 'Anggota ${status.toUpperCase()} • $noAnggota'
                          : 'Anggota ${status.toUpperCase()} • $cabang',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
