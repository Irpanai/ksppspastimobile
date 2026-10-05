import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/ppob_menu.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/sijaka_portfolio_card.dart';

import '../widgets/tunggakan_modal_dialog.dart';

import '../widgets/wajib_simpanan_modal_dialog.dart';

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
      _loadDashboardAndCheckTunggakan();
    });
  }

  Future<void> _loadDashboardAndCheckTunggakan() async {
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.fetchDashboard();
    if (!mounted) return;
    _checkAndShowTunggakanPopup();
  }

  void _checkAndShowTunggakanPopup() {
    final dashboardProvider = context.read<DashboardProvider>();
    final anggota = dashboardProvider.dashboardData?.anggota;
    final saldoPokok = dashboardProvider.dashboardData?.ringkasanSaldo.saldoPokok ?? 0;

    // Cek jika saldo pokok 0 (artinya belum pernah bayar simpanan pokok / akun baru)
    if (saldoPokok == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          WajibSimpananModalDialog.show(context);
        }
      });
      return; // Jangan lanjut cek tunggakan lain jika pokok belum dibayar
    }

    if (anggota != null &&
        (anggota.isMenunggak || anggota.tunggakanWajib.isNotEmpty) &&
        !dashboardProvider.hasShownTunggakanDialog) {
      dashboardProvider.markTunggakanDialogShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          TunggakanModalDialog.show(context, anggota);
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DashboardProvider>().fetchDashboard(refresh: true),
      context.read<AuthProvider>().fetchProfile(),
    ]);
    if (mounted) {
      _checkAndShowTunggakanPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final anggota = dashboardProvider.dashboardData?.anggota;
    final isMenunggak = anggota != null && (anggota.isMenunggak || anggota.tunggakanWajib.isNotEmpty);

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
                    if (isMenunggak)
                      _buildTunggakanWarningBanner(context, anggota),
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
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTunggakanWarningBanner(BuildContext context, DashboardAnggota anggota) {
    final bulanCount = anggota.jumlahBulanMenunggak > 0
        ? anggota.jumlahBulanMenunggak
        : anggota.tunggakanWajib.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber-50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber-200
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian: Status Menunggak',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bulanCount > 0
                      ? 'Ada $bulanCount bulan Simpanan Wajib belum dibayar.'
                      : 'Simpanan Wajib belum terbayar.',
                  style: const TextStyle(color: Color(0xFFB45309), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => TunggakanModalDialog.show(context, anggota),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
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

    final photoUrl = authUser?.fullProfilePhotoUrl ?? ApiConstants.resolveImageUrl(authUser?.profilePhotoUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Beranda photo load error: $error (URL: $photoUrl)');
                            return _buildInitials(displayName);
                          },
                        )
                      : _buildInitials(displayName),
                ),
              ),
              const SizedBox(width: 14),
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

  Widget _buildInitials(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'N';
    return Container(
      color: Colors.white.withValues(alpha: 0.25),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'N',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
