import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/models/dashboard_model.dart';
import '../../features/home/providers/dashboard_provider.dart';
import '../../features/home/widgets/wajib_simpanan_modal_dialog.dart';

/// Guard utilitas untuk memeriksa dan memastikan nasabah telah menyelesaikan
/// aktivasi keanggotaan (Simpanan Pokok & Simpanan Wajib awal).
class MemberActivationGuard {
  /// Memeriksa apakah status anggota saat ini sudah aktif resmi.
  static bool isActivated(BuildContext context, {bool listen = false}) {
    DashboardProvider? dashboardProvider;
    try {
      dashboardProvider = listen
          ? context.watch<DashboardProvider>()
          : context.read<DashboardProvider>();
    } catch (_) {
      dashboardProvider = null;
    }

    AuthProvider? authProvider;
    try {
      authProvider = listen
          ? context.watch<AuthProvider>()
          : context.read<AuthProvider>();
    } catch (_) {
      authProvider = null;
    }

    final authUser = authProvider?.user;
    final dashboardData = dashboardProvider?.dashboardData;
    final anggota = dashboardData?.anggota;

    return MemberStatusResolver.resolve(
      saldoPokok: dashboardData?.ringkasanSaldo.saldoPokok,
      saldoWajib: dashboardData?.ringkasanSaldo.saldoWajib,
      apiIsPokokPaid: anggota?.isPokokPaid ??
          authUser?.isPokokPaid ??
          authUser?.anggota?.isPokokPaid,
      apiIsWajibPaid: anggota?.isWajibPaid ??
          authUser?.isWajibPaid ??
          authUser?.anggota?.isWajibPaid,
      rawStatus: anggota?.statusKeanggotaan ??
          anggota?.status ??
          authUser?.statusKeanggotaan ??
          authUser?.anggota?.status,
    ).isActive;
  }

  /// Memvalidasi status aktivasi nasabah. Jika belum aktif, langsung menampilkan
  /// popup modal aktivasi akun (Simpanan Pokok + Wajib) dan mengembalikan false.
  static bool checkAndRequireActivation(BuildContext context) {
    if (!isActivated(context)) {
      WajibSimpananModalDialog.show(context);
      return false;
    }
    return true;
  }
}
