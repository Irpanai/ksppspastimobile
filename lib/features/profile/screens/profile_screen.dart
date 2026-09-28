import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../gadai/screens/gadai_screen.dart';
import '../../history/providers/history_provider.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../sijaka/providers/sijaka_provider.dart';
import '../../sijaka/screens/sijaka_portfolio_screen.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfileDetail();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<AuthProvider>().fetchProfile(),
      context.read<ProfileProvider>().fetchProfileDetail(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final user = profileProvider.profileData?.user ?? authProvider.user;
    final anggota = profileProvider.profileData?.anggota ?? user?.anggota;

    final userName = user?.name.isNotEmpty == true ? user!.name : 'Nasabah KSPPS';
    final userEmail = user?.email.isNotEmpty == true ? user!.email : 'email@ksppspasti.com';
    final noAnggota = anggota?.noAnggota ?? user?.noAnggota ?? 'PASTI-0000';
    final statusKeanggotaan = anggota?.statusKeanggotaan ?? anggota?.status ?? user?.statusKeanggotaan ?? 'Aktif';
    final cabang = anggota?.cabang ?? user?.cabang ?? 'Pusat';
    final photoUrl = user?.fullProfilePhotoUrl ?? anggota?.fullFotoUrl ?? ApiConstants.resolveImageUrl(user?.profilePhotoUrl ?? anggota?.foto);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Green Shape
              Container(
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Profile Info & Photo
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(userName),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildDefaultAvatar(userName),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Text(
                        'Anggota ${statusKeanggotaan.toUpperCase()} • ID: $noAnggota • $cabang',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2x2 Menu Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                        children: [
                          _buildGridCard(
                            context,
                            title: 'Edit Profil',
                            subtitle: 'Kelola data diri & KYC',
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                              );
                              _refreshAll();
                            },
                          ),
                          _buildGridCard(
                            context,
                            title: 'Mutasi Rekening',
                            subtitle: 'Riwayat transaksi',
                            icon: Icons.receipt_long_outlined,
                            iconColor: const Color(0xFF16A34A),
                            iconBgColor: const Color(0xFFF0FDF4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                              );
                            },
                          ),
                          _buildGridCard(
                            context,
                            title: 'Portofolio Sijaka',
                            subtitle: 'Simpanan berjangka',
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF0D9488),
                            iconBgColor: const Color(0xFFF0FDFA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SijakaPortfolioScreen(showBackButton: true)),
                              );
                            },
                          ),
                          _buildGridCard(
                            context,
                            title: 'Transaksi Gadai',
                            subtitle: 'Pinjaman & agunan',
                            icon: Icons.handshake_outlined,
                            iconColor: const Color(0xFFD97706),
                            iconBgColor: const Color(0xFFFFFBEB),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GadaiScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Pengaturan Keamanan & Bantuan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 10),
                            child: Text('Keamanan & Akun', style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              children: [
                                _buildMenuRow(Icons.password_rounded, 'Ganti PIN Transaksi'),
                                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                                _buildMenuRow(Icons.fingerprint_rounded, 'Login Biometrik', trailing: Switch(value: true, activeColor: Theme.of(context).colorScheme.primary, onChanged: (v){})),
                                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                                _buildMenuRow(
                                  Icons.verified_user_outlined,
                                  'Verifikasi Identitas (KYC)',
                                  trailing: const Text('Terverifikasi', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 10),
                            child: Text('Lainnya', style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              children: [
                                _buildMenuRow(Icons.help_outline_rounded, 'Pusat Bantuan'),
                                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                                _buildMenuRow(Icons.description_outlined, 'Syarat & Ketentuan'),
                                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                                _buildMenuRow(Icons.info_outline_rounded, 'Tentang Aplikasi', trailing: const Text('v1.0.0', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Logout Button
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                              label: const Text('Keluar Akun', style: TextStyle(color: Color(0xFFDC2626), fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // App Version
                          const Center(
                            child: Text(
                              'Mobile KSPPS PASTI v1.0.0 • Sistem Syariah Terpadu',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Icon(icon, size: 90, color: iconColor.withOpacity(0.04)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, {Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF64748B), size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF334155))),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
      onTap: () {},
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda? Anda harus login kembali untuk bertransaksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                context.read<DashboardProvider>().reset();
                context.read<SavingsProvider>().reset();
                context.read<SijakaProvider>().reset();
                context.read<HistoryProvider>().reset();
                context.read<ProfileProvider>().reset();
              } catch (_) {}

              await context.read<AuthProvider>().logout();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Berhasil keluar dari akun'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'N';
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'N',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
