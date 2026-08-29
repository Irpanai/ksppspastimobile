import 'package:flutter/material.dart';
import '../../home/screens/beranda_screen.dart';
import '../../savings/screens/simpanan_screen.dart';
import '../../gadai/screens/gadai_screen.dart';
import '../../qris/screens/qris_scanner_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({Key? key}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BerandaScreen(),
    const SimpananScreen(),
    const GadaiScreen(),
    const ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Beranda'},
    {'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'Simpanan'},
    {'icon': Icons.handshake_outlined, 'activeIcon': Icons.handshake, 'label': 'Gadai'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profil'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 90, // Total space for the navbar and overlapping button
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Stack(
            alignment: Alignment.center, // Center everything so the big button overflows top and bottom equally
            clipBehavior: Clip.none,
            children: [
              // White Pill Background
              Container(
                height: 65, // Slightly thinner pill to emphasize the button size
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Kiri
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _currentIndex = 0),
                              child: Center(child: _buildNavItem(0)),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _currentIndex = 1),
                              child: Center(child: _buildNavItem(1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ruang kosong untuk tombol QRIS di tengah
                    const SizedBox(width: 86),
                    // Kanan
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _currentIndex = 2),
                              child: Center(child: _buildNavItem(2)),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _currentIndex = 3),
                              child: Center(child: _buildNavItem(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Floating QR Button raksasa di tengah
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QrisScannerScreen()),
                  );
                },
                child: Container(
                  height: 86, // Ukuran raksasa melebihi height navbar (65)
                  width: 86,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, // Tema Hijau
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF8FAFC), width: 6), // Border tebal agar seolah memotong navbar dengan warna background app
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon with slight bounce/scale on active
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Icon(
              isSelected ? item['activeIcon'] : item['icon'],
              color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF94A3B8), // Sleek grey
              size: 24, 
            ),
          ),
          const SizedBox(height: 6),
          // Animated Text Color
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF94A3B8),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
            child: Text(
              item['label'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

