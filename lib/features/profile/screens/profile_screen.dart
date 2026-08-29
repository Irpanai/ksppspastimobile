import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../sijaka/screens/sijaka_portfolio_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        physics: const BouncingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Green Shape (Now inside the scroll view)
            Container(
              width: double.infinity,
              height: 340, // Tall enough to cover the top area
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
                  // Profile Info
                  const SizedBox(height: 20),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Budi Santoso',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'budisantoso@email.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Anggota Penuh • ID: 10293847',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2x2 Menu Grid (Overlapping the green background)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.45, // More rectangular layout like the reference
                      children: [
                        _buildGridCard(
                          context,
                          title: 'Edit Profil',
                          subtitle: 'Kelola data diri',
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF2563EB), // Blue
                          iconBgColor: const Color(0xFFEFF6FF),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                          },
                        ),
                        _buildGridCard(
                          context,
                          title: 'Mutasi Rekening',
                          subtitle: 'Riwayat transaksi',
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFF16A34A), // Green
                          iconBgColor: const Color(0xFFF0FDF4),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
                          },
                        ),
                        _buildGridCard(
                          context,
                          title: 'Portofolio Sijaka',
                          subtitle: 'Simpanan berjangka',
                          icon: Icons.pie_chart_outline,
                          iconColor: const Color(0xFFD97706), // Orange
                          iconBgColor: const Color(0xFFFFFBEB),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SijakaPortfolioScreen()));
                          },
                        ),
                        _buildGridCard(
                          context,
                          title: 'Notifikasi',
                          subtitle: 'Jadwal & Info',
                          icon: Icons.notifications_active_outlined,
                          iconColor: const Color(0xFFDC2626), // Red
                          iconBgColor: const Color(0xFFFEF2F2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pengaturan List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text('Keamanan & Akun', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            children: [
                              _buildMenuRow(Icons.password_rounded, 'Ganti PIN Transaksi'),
                              const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                              _buildMenuRow(Icons.fingerprint_rounded, 'Login Biometrik', trailing: Switch(value: true, activeColor: Theme.of(context).colorScheme.primary, onChanged: (v){})),
                              const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                              _buildMenuRow(Icons.verified_user_outlined, 'Verifikasi e-KTP', trailing: const Text('Terverifikasi', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text('Lainnya', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
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

                        const SizedBox(height: 40),
                        
                        // Logout Button
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _showLogoutDialog(context),
                            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                            label: const Text('Keluar Akun', style: TextStyle(color: Color(0xFFDC2626), fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // App Version
                        const Center(
                          child: Text(
                            'Mobile Intira v1.0.0 • KSPPS PASTI',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Faded background watermark icon
              Positioned(
                right: -10,
                top: -10,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Icon(
                    icon,
                    size: 100,
                    color: iconColor.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFF64748B), size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF334155))),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      onTap: () {},
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda? Anda harus login kembali untuk bertransaksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
