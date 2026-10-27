import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/cabang_location_banner.dart';
import '../widgets/promo_carousel.dart';
import '../../promo/providers/promo_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../notification/screens/notification_screen.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/sijaka_portfolio_card.dart';

import '../widgets/tunggakan_modal_dialog.dart';

import '../widgets/wajib_simpanan_modal_dialog.dart';
import '../../payment/models/payment_model.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/widgets/pending_payments_modal.dart';

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
          TunggakanModalDialog.show(context, anggota, saldoPokok);
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DashboardProvider>().fetchDashboard(refresh: true),
      context.read<AuthProvider>().fetchProfile(),
      context.read<PromoProvider>().fetchPromos(refresh: true),
      context.read<NotificationProvider>().fetchNotifications(refresh: true),
    ]);
    if (mounted) {
      _checkAndShowTunggakanPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final anggota = dashboardProvider.dashboardData?.anggota;
    final saldoPokok = dashboardProvider.dashboardData?.ringkasanSaldo.saldoPokok ?? 0;
    final isMenunggak = anggota != null && (anggota.isMenunggak || anggota.tunggakanWajib.isNotEmpty);
    final pendingPayments = paymentProvider.pendingPayments;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
                    if (pendingPayments.isNotEmpty)
                      _buildPendingPaymentBanner(context, pendingPayments),
                    if (saldoPokok == 0)
                      _buildSimpananPokokBanner(context),
                    if (isMenunggak)
                      _buildTunggakanWarningBanner(context, anggota, saldoPokok),
                    const SizedBox(height: 24),
                    const BalanceCard(),
                    const SizedBox(height: 32),
                    const QuickActionsGrid(),
                    const SizedBox(height: 24),
                    const CabangLocationBanner(),
                    const SizedBox(height: 28),
                    // const PPOBMenu(), // Dihide sementara karena belum selesai
                    // const SizedBox(height: 24),
                    const PromoCarousel(),
                    const SizedBox(height: 24),
                    const SijakaPortfolioCard(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentBanner(BuildContext context, List<SnapTokenResponse> pendingList) {
    if (pendingList.isEmpty) return const SizedBox.shrink();
    final first = pendingList.first;
    final count = pendingList.length;

    final title = count > 1 ? 'Ada $count Pembayaran Menunggu' : 'Menunggu Pembayaran';
    final subtitle = count > 1
        ? '${first.displayPaymentMethod} dan ${count - 1} lainnya • Ketuk untuk lihat'
        : '${first.displayPaymentMethod} • ${first.nominalFormat}';

    return InkWell(
      onTap: () => PendingPaymentsModal.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // Warm amber background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => PendingPaymentsModal.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Buka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpananPokokBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
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
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kewajiban: Simpanan Pokok',
                  style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Anda diwajibkan membayar Simpanan Pokok awal.',
                  style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => WajibSimpananModalDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTunggakanWarningBanner(BuildContext context, DashboardAnggota anggota, [num saldoPokok = 0]) {
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
            onPressed: () => TunggakanModalDialog.show(context, anggota, saldoPokok),
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Halo, $displayName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          noAnggota.isNotEmpty
                              ? 'Anggota ${status.toUpperCase()} • $noAnggota'
                              : 'Anggota ${status.toUpperCase()} • $cabang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (ctx) {
              final notifProvider = ctx.watch<NotificationProvider>();
              final unreadCount = notifProvider.unreadCount;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        height: 9,
                        width: 9,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(ctx).colorScheme.secondary, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
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
