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
import '../../payment/screens/top_up_screen.dart';
import '../../payment/widgets/pending_payments_modal.dart';
import '../../../core/services/in_app_update_service.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/dashboard_alert_banner.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardAndCheckTunggakan();
      InAppUpdateService.checkAndShowUpdateDialog(context);
    });
  }

  Future<void> _loadDashboardAndCheckTunggakan() async {
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.fetchDashboard();
    if (!mounted) return;
    _checkDashboardErrorModal();
    _checkAndShowTunggakanPopup();
  }

  void _checkDashboardErrorModal() {
    final err = context.read<DashboardProvider>().errorMessage?.trim() ?? '';
    if (err.isEmpty || err.toLowerCase().contains('timeout')) {
      _lastShownError = null;
      return;
    }
    if (_lastShownError == err) return;
    _lastShownError = err;
    AppDialog.showError(
      context,
      title: 'Gagal Memuat Beranda',
      message: err,
      buttonText: 'Muat Ulang',
      onConfirm: () {
        if (mounted) _loadDashboardAndCheckTunggakan();
      },
      secondaryButtonText: 'Tutup',
    );
  }

  MemberStatusResolver _resolveCurrentMemberStatus(BuildContext context, {bool listen = false}) {
    final dashboardProvider = listen ? context.watch<DashboardProvider>() : context.read<DashboardProvider>();
    final authUser = listen ? context.watch<AuthProvider>().user : context.read<AuthProvider>().user;
    final dashboardData = dashboardProvider.dashboardData;
    final anggota = dashboardData?.anggota;

    return MemberStatusResolver.resolve(
      saldoPokok: dashboardData?.ringkasanSaldo.saldoPokok,
      saldoWajib: dashboardData?.ringkasanSaldo.saldoWajib,
      apiIsPokokPaid: anggota?.isPokokPaid ?? authUser?.isPokokPaid ?? authUser?.anggota?.isPokokPaid,
      apiIsWajibPaid: anggota?.isWajibPaid ?? authUser?.isWajibPaid ?? authUser?.anggota?.isWajibPaid,
      rawStatus: anggota?.statusKeanggotaan ??
          anggota?.status ??
          authUser?.statusKeanggotaan ??
          authUser?.anggota?.status,
    );
  }

  void _checkAndShowTunggakanPopup() {
    final dashboardProvider = context.read<DashboardProvider>();
    final dashboardAnggota = dashboardProvider.dashboardData?.anggota;
    final saldoPokok = dashboardProvider.dashboardData?.ringkasanSaldo.saldoPokok ?? 0;

    // Guard: Jangan tampilkan dialog apapun jika data belum tersedia atau sedang loading awal
    if (dashboardProvider.dashboardData == null || dashboardProvider.isLoading) {
      return;
    }

    final statusInfo = _resolveCurrentMemberStatus(context);

    // Nasabah baru / anggota belum aktif (belum melunasi Simpanan Pokok & Wajib)
    if (!statusInfo.isPokokPaid || !statusInfo.isWajibPaid) {
      if (!dashboardProvider.hasShownTunggakanDialog) {
        dashboardProvider.markTunggakanDialogShown();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (!statusInfo.isPokokPaid) {
              WajibSimpananModalDialog.show(context);
            } else if (dashboardAnggota != null) {
              TunggakanModalDialog.show(context, dashboardAnggota, saldoPokok);
            }
          }
        });
      }
      return;
    }

    // Cek tunggakan simpanan wajib bulanan (hanya jika Pokok & Wajib awal sudah pernah dibayar)
    final anggota = dashboardAnggota;
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
      _checkDashboardErrorModal();
      _checkAndShowTunggakanPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final anggota = dashboardProvider.dashboardData?.anggota;
    final saldoPokok = dashboardProvider.dashboardData?.ringkasanSaldo.saldoPokok ?? 0;

    final statusInfo = _resolveCurrentMemberStatus(context, listen: true);
    final isMenunggak = statusInfo.isPokokPaid &&
        statusInfo.isWajibPaid &&
        anggota != null &&
        (anggota.isMenunggak || anggota.tunggakanWajib.isNotEmpty);
    final pendingPayments = paymentProvider.pendingPayments;

    final bool shouldShowActivationBanner = (!statusInfo.isPokokPaid || !statusInfo.isWajibPaid) &&
        dashboardProvider.dashboardData != null &&
        !dashboardProvider.isLoading;

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
                      if (pendingPayments.isNotEmpty)
                        _buildPendingPaymentBanner(context, pendingPayments),
                      if (shouldShowActivationBanner)
                        _buildSimpananPokokBanner(context, needsPokok: !statusInfo.isPokokPaid),
                      if (isMenunggak)
                        _buildTunggakanWarningBanner(context, anggota, saldoPokok),
                      const SizedBox(height: 24),
                      const BalanceCard(),
                      const SizedBox(height: 32),
                      const QuickActionsGrid(),
                      const SizedBox(height: 24),
                      const CabangLocationBanner(),
                      const SizedBox(height: 28),
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

    return DashboardAlertBanner.amber(
      title: title,
      subtitle: subtitle,
      actionLabel: 'Lihat',
      icon: Icons.timer_outlined,
      onCardTap: () => PendingPaymentsModal.show(context),
      onActionTap: () => PendingPaymentsModal.show(context),
    );
  }

  Widget _buildSimpananPokokBanner(BuildContext context, {bool needsPokok = true}) {
    final targetType = needsPokok ? 'simpanan_pokok_wajib' : 'simpanan_wajib';

    return DashboardAlertBanner.emerald(
      title: needsPokok
          ? 'Bayar Simpanan Pokok & Wajib'
          : 'Aktivasi: Bayar Simpanan Wajib',
      subtitle: needsPokok
          ? 'Bayar Simpanan Pokok Rp 15.000 & Wajib Rp 2.500 agar status anggota Anda Aktif.'
          : 'Lunasi Simpanan Wajib Rp 2.500 untuk mengaktifkan status anggota Anda.',
      actionLabel: 'Bayar',
      icon: Icons.how_to_reg_rounded,
      onCardTap: () {
        if (needsPokok) {
          WajibSimpananModalDialog.show(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TopUpScreen(initialType: 'simpanan_wajib'),
            ),
          );
        }
      },
      onActionTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TopUpScreen(initialType: targetType),
        ),
      ),
    );
  }

  Widget _buildTunggakanWarningBanner(BuildContext context, DashboardAnggota anggota, [num saldoPokok = 0]) {
    final bulanCount = anggota.jumlahBulanMenunggak > 0
        ? anggota.jumlahBulanMenunggak
        : anggota.tunggakanWajib.length;

    return DashboardAlertBanner.amber(
      title: 'Perhatian: Status Menunggak',
      subtitle: bulanCount > 0
          ? 'Ada $bulanCount bulan Simpanan Wajib belum dibayar.'
          : 'Simpanan Wajib belum terbayar.',
      actionLabel: 'Bayar',
      icon: Icons.warning_amber_rounded,
      onCardTap: () => TunggakanModalDialog.show(context, anggota, saldoPokok),
      onActionTap: () => TunggakanModalDialog.show(context, anggota, saldoPokok),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final dashboardProvider = context.watch<DashboardProvider>();
    final dashboardAnggota = dashboardProvider.dashboardData?.anggota;
    final statusInfo = _resolveCurrentMemberStatus(context, listen: true);

    final displayName = dashboardAnggota?.nama.isNotEmpty == true
        ? dashboardAnggota!.nama
        : (authUser?.name.isNotEmpty == true ? authUser!.name : 'Nasabah');

    final noAnggota = dashboardAnggota?.noAnggota ?? authUser?.noAnggota ?? authUser?.anggota?.noAnggota ?? '';
    final cabang = dashboardAnggota?.cabang ?? authUser?.cabang ?? authUser?.anggota?.cabang ?? 'KSPPS PASTI';
    final String statusDisplay = statusInfo.displayStatus;
    final bool isBadgedActive = statusInfo.isActive;

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
                          color: isBadgedActive
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: isBadgedActive
                              ? null
                              : Border.all(color: const Color(0xFFFDE68A), width: 1),
                        ),
                        child: Text(
                          noAnggota.isNotEmpty
                              ? 'Anggota $statusDisplay • $noAnggota'
                              : 'Anggota $statusDisplay • $cabang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
