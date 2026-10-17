import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cabang_model.dart';
import '../services/cabang_service.dart';

/// Widget Mini Map visual untuk kartu cabang terpilih pada halaman pendaftaran.
/// Mendukung toggle beralih antara Peta Standar (OpenStreetMap) dan Citra Satelit (Esri World Imagery).
class CabangMiniMap extends StatefulWidget {
  final CabangModel cabang;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback? onExpand;

  const CabangMiniMap({
    super.key,
    required this.cabang,
    this.userLatitude,
    this.userLongitude,
    this.onExpand,
  });

  @override
  State<CabangMiniMap> createState() => _CabangMiniMapState();
}

class _CabangMiniMapState extends State<CabangMiniMap> {
  bool _isSatellite = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cabang.latitude == null || widget.cabang.longitude == null) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final branchPos = LatLng(widget.cabang.latitude!, widget.cabang.longitude!);
    final userPos = (widget.userLatitude != null && widget.userLongitude != null)
        ? LatLng(widget.userLatitude!, widget.userLongitude!)
        : null;

    return Container(
      height: 185,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: branchPos,
                initialZoom: 15.2,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                if (_isSatellite) ...[
                  // Base Citra Satelit Esri
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.ksppspasti.mobile',
                    maxZoom: 19,
                  ),
                  // Overlay Batas Wilayah & Nama Jalan Esri
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.ksppspasti.mobile',
                    maxZoom: 19,
                  ),
                ] else ...[
                  // Peta Standar OpenStreetMap
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ksppspasti.mobile',
                    maxZoom: 19,
                  ),
                ],
                MarkerLayer(
                  markers: [
                    // Marker Posisi User GPS
                    if (userPos != null)
                      Marker(
                        point: userPos,
                        width: 34,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.45),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                      ),

                    // Marker Cabang Terpilih
                    Marker(
                      point: branchPos,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFCD34D), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Kontrol Atas: Toggle Satelit & Buka Peta Penuh
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle Satelit
                  Material(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _isSatellite = !_isSatellite),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSatellite ? 'Mode Jalan' : 'Citra Satelit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tombol Perbesar Peta (Fullscreen Modal)
                  if (widget.onExpand != null)
                    Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onExpand,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Peta Penuh',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Badge Koordinat Mini di pojok kiri bawah
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_rounded, size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.cabang.latitude!.toStringAsFixed(4)}, ${widget.cabang.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Pemetaan Lokasi Cabang Interaktif
/// Fitur:
/// - Pencarian real-time nama cabang, kode cabang, kota, alamat, atau provinsi
/// - Filter provinsi & pilihan cepat kantor cabang di provinsi tersebut (warna selaras tema)
/// - Hubungi WhatsApp CS & Telepon Kantor Cabang langsung
/// - Citra Satelit definisi tinggi (Esri World Imagery + label jalan) & Peta Standar
/// - Mode Pendaftaran (Pilih Cabang Ini) dan Mode Eksplorasi / Info Cabang
class CabangMapModal extends StatefulWidget {
  final List<CabangModel> allCabangs;
  final CabangModel? initialSelectedCabang;
  final String? initialProvince;
  final double? userLatitude;
  final double? userLongitude;
  final ValueChanged<CabangModel>? onSelectCabang;

  const CabangMapModal({
    super.key,
    required this.allCabangs,
    this.initialSelectedCabang,
    this.initialProvince,
    this.userLatitude,
    this.userLongitude,
    this.onSelectCabang,
  });

  /// Membuka Modal Bottom Sheet Pemetaan Cabang
  static Future<void> show({
    required BuildContext context,
    required List<CabangModel> allCabangs,
    CabangModel? initialSelectedCabang,
    String? initialProvince,
    double? userLatitude,
    double? userLongitude,
    ValueChanged<CabangModel>? onSelectCabang,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CabangMapModal(
        allCabangs: allCabangs,
        initialSelectedCabang: initialSelectedCabang,
        initialProvince: initialProvince,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        onSelectCabang: onSelectCabang,
      ),
    );
  }

  @override
  State<CabangMapModal> createState() => _CabangMapModalState();
}

class _CabangMapModalState extends State<CabangMapModal> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  CabangModel? _focusedCabang;
  late List<CabangModel> _allValidCabangs;
  late List<CabangModel> _filteredCabangs;

  String _searchQuery = '';
  String _selectedProvince = 'Semua';
  List<String> _provinceList = ['Semua'];
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // 1. Saring hanya cabang yang memiliki koordinat valid
    _allValidCabangs = widget.allCabangs
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();

    // 2. Hitung jarak jika ada koordinat user
    if (widget.userLatitude != null && widget.userLongitude != null) {
      _allValidCabangs = _allValidCabangs.map((c) {
        final d = CabangService.calculateDistanceKm(
          widget.userLatitude!,
          widget.userLongitude!,
          c.latitude!,
          c.longitude!,
        );
        return c.copyWith(distanceInKm: d);
      }).toList();

      _allValidCabangs.sort((a, b) {
        if (a.distanceInKm == null && b.distanceInKm == null) return 0;
        if (a.distanceInKm == null) return 1;
        if (b.distanceInKm == null) return -1;
        return a.distanceInKm!.compareTo(b.distanceInKm!);
      });
    }

    // 3. Ekstrak daftar provinsi unik secara dinamis
    final distinctProvinces = <String>{};
    for (final c in _allValidCabangs) {
      final p = c.province?.trim();
      if (p != null && p.isNotEmpty) {
        distinctProvinces.add(p);
      }
    }
    final sortedProvs = distinctProvinces.toList()..sort();
    _provinceList = ['Semua', ...sortedProvs];

    // 4. Inisialisasi provinsi terpilih
    if (widget.initialProvince != null && widget.initialProvince!.isNotEmpty) {
      final match = _provinceList.firstWhere(
        (p) => p.toUpperCase() == widget.initialProvince!.toUpperCase(),
        orElse: () => 'Semua',
      );
      _selectedProvince = match;
    } else if (widget.initialSelectedCabang?.province != null) {
      final match = _provinceList.firstWhere(
        (p) => p.toUpperCase() == widget.initialSelectedCabang!.province!.toUpperCase(),
        orElse: () => 'Semua',
      );
      _selectedProvince = match;
    }

    // 5. Terapkan filter awal
    _applyFilter(initial: true);

    // 6. Tentukan cabang yang sedang difokuskan
    _focusedCabang = widget.initialSelectedCabang ??
        (_filteredCabangs.isNotEmpty ? _filteredCabangs.first : null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter({bool initial = false}) {
    final q = _searchQuery.trim().toLowerCase();
    final prov = _selectedProvince.trim().toUpperCase();

    final result = _allValidCabangs.where((c) {
      // Filter Provinsi
      if (prov != 'SEMUA') {
        final cProv = (c.province ?? '').trim().toUpperCase();
        if (cProv != prov && !cProv.contains(prov) && !prov.contains(cProv)) {
          return false;
        }
      }

      // Filter Pencarian (Nama, Kode, Kota, Provinsi, Alamat)
      if (q.isNotEmpty) {
        final name = c.name.toLowerCase();
        final code = c.code.toLowerCase();
        final city = (c.city ?? '').toLowerCase();
        final province = (c.province ?? '').toLowerCase();
        final address = (c.address ?? '').toLowerCase();

        final matches = name.contains(q) ||
            code.contains(q) ||
            city.contains(q) ||
            province.contains(q) ||
            address.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();

    _filteredCabangs = result;

    if (!initial) {
      setState(() {
        if (_focusedCabang == null ||
            !_filteredCabangs.any((c) => c.id == _focusedCabang!.id)) {
          if (_filteredCabangs.isNotEmpty) {
            _focusedCabang = _filteredCabangs.first;
            _centerTo(
              LatLng(_focusedCabang!.latitude!, _focusedCabang!.longitude!),
              zoom: _selectedProvince != 'Semua' ? 14.5 : 12.0,
            );
          } else {
            _focusedCabang = null;
          }
        }
      });
    }
  }

  LatLng _getInitialCenter() {
    if (_focusedCabang?.latitude != null && _focusedCabang?.longitude != null) {
      return LatLng(_focusedCabang!.latitude!, _focusedCabang!.longitude!);
    }
    if (widget.userLatitude != null && widget.userLongitude != null) {
      return LatLng(widget.userLatitude!, widget.userLongitude!);
    }
    // Default: Pusat Kalsel / Banjarmasin
    return const LatLng(-3.32490, 114.59010);
  }

  void _centerTo(LatLng target, {double zoom = 15.0}) {
    _mapController.move(target, zoom);
  }

  String _formatProvinceName(String raw) {
    if (raw.toUpperCase() == 'SEMUA') return 'Semua';
    return raw.split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  int _getProvinceBranchCount(String province) {
    if (province.toUpperCase() == 'SEMUA') return _allValidCabangs.length;
    final provUpper = province.trim().toUpperCase();
    return _allValidCabangs.where((c) {
      final cProv = (c.province ?? '').trim().toUpperCase();
      return cProv == provUpper || cProv.contains(provUpper);
    }).length;
  }

  /// Membuka navigasi rute Google Maps
  Future<void> _openExternalMaps(CabangModel cabang) async {
    Uri url;
    if (cabang.latitude != null && cabang.longitude != null) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${cabang.latitude},${cabang.longitude}',
      );
    } else {
      final query = Uri.encodeComponent('${cabang.name} ${cabang.city ?? ''}');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  /// Membuka chat WhatsApp langsung ke Customer Service Cabang
  Future<void> _openWhatsApp(CabangModel cabang) async {
    if (cabang.phone == null || cabang.phone!.isEmpty) return;

    String cleanNumber = cabang.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('+62')) {
      cleanNumber = cleanNumber.substring(1);
    }

    final greeting = Uri.encodeComponent(
      'Assalamu\'alaikum KSPPS PASTI ${cabang.name}, saya ingin menanyakan informasi layanan simpanan/pembiayaan.',
    );
    final waUrl = Uri.parse('https://wa.me/$cleanNumber?text=$greeting');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUrl);
      }
    } catch (_) {
      _openDialer(cabang);
    }
  }

  /// Melakukan panggilan telepon langsung ke kantor cabang
  Future<void> _openDialer(CabangModel cabang) async {
    if (cabang.phone == null || cabang.phone!.isEmpty) return;
    final telUrl = Uri.parse('tel:${cabang.phone!.replaceAll(RegExp(r'[^0-9+]'), '')}');
    try {
      await launchUrl(telUrl);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final lightGreenBg = primaryColor.withValues(alpha: 0.12);
    final lightGreenBorder = primaryColor.withValues(alpha: 0.35);

    final userPos = (widget.userLatitude != null && widget.userLongitude != null)
        ? LatLng(widget.userLatitude!, widget.userLongitude!)
        : null;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isSelectionMode = widget.onSelectCabang != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightGreenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peta Lokasi Kantor Cabang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          isSelectionMode
                              ? '${_filteredCabangs.length} kantor cabang terpetakan • Ketuk pin untuk memilih'
                              : '${_filteredCabangs.length} kantor cabang terpetakan • Ketuk pin untuk kontak & rute',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Kolom Pencarian Real-Time (Nama cabang, kode, kota, provinsi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Cari nama cabang, kode cabang, atau kota...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _applyFilter();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilter();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Filter Chips Provinsi (Horizontal Scroll - Menggunakan Warna Tema Aplikasi)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _provinceList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prov = _provinceList[index];
                  final isSelected = _selectedProvince.toUpperCase() == prov.toUpperCase();
                  final count = _getProvinceBranchCount(prov);

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _selectedProvince = prov;
                      _applyFilter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.28),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${_formatProvinceName(prov)} ($count)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pilihan Kantor Cabang di Provinsi Tersebut (Quick Branch Chips)
            if (_filteredCabangs.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredCabangs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final c = _filteredCabangs[index];
                    final isFocused = _focusedCabang?.id == c.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _focusedCabang = c);
                        _centerTo(LatLng(c.latitude!, c.longitude!), zoom: 16.0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isFocused ? lightGreenBg : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused ? primaryColor : const Color(0xFFE2E8F0),
                            width: isFocused ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 13,
                              color: isFocused ? primaryColor : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.code} • ${c.name}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                                color: isFocused ? secondaryColor : const Color(0xFF334155),
                              ),
                            ),
                            if (c.formattedDistance != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${c.formattedDistance})',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isFocused ? primaryColor : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Peta Interaktif (OpenStreetMap / Citra Satelit)
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _getInitialCenter(),
                      initialZoom: 13.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      if (_isSatellite) ...[
                        // Citra Satelit Esri World Imagery Resolusi Tinggi
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.ksppspasti.mobile',
                          maxZoom: 19,
                        ),
                        // Label Jalan & Batas Kota Transparan Esri
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.ksppspasti.mobile',
                          maxZoom: 19,
                        ),
                      ] else ...[
                        // Peta Jalan Standar OpenStreetMap
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ksppspasti.mobile',
                          maxZoom: 19,
                        ),
                      ],

                      // Marker Layer
                      MarkerLayer(
                        markers: [
                          // Marker Posisi User GPS
                          if (userPos != null)
                            Marker(
                              point: userPos,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                            ),

                          // Marker Cabang Hasil Filter
                          ..._filteredCabangs.map((cabang) {
                            final isFocused = _focusedCabang?.id == cabang.id;
                            final pos = LatLng(cabang.latitude!, cabang.longitude!);

                            return Marker(
                              point: pos,
                              width: isFocused ? 54 : 38,
                              height: isFocused ? 54 : 38,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _focusedCabang = cabang);
                                  _centerTo(pos, zoom: 15.5);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isFocused
                                          ? [primaryColor, secondaryColor]
                                          : [const Color(0xFF4CAF50), primaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isFocused ? const Color(0xFFFCD34D) : Colors.white,
                                      width: isFocused ? 3.5 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isFocused ? primaryColor : Colors.black)
                                            .withValues(alpha: isFocused ? 0.55 : 0.3),
                                        blurRadius: isFocused ? 14 : 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: isFocused ? 26 : 18,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // Badge Mode Citra Satelit di pojok kiri atas peta
                  if (_isSatellite)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.satellite_alt_rounded, color: primaryColor, size: 13),
                            const SizedBox(width: 4),
                            const Text(
                              'Citra Satelit Esri',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating Controls di Kanan Atas (Toggle Citra Satelit, GPS, Zoom)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Tombol Toggle Satelit / Peta Standar
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 3,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _isSatellite = !_isSatellite),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isSatellite ? primaryColor : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isSatellite ? 'Peta Jalan' : 'Citra Satelit',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tombol Ke Posisi Saya
                        if (userPos != null) ...[
                          FloatingActionButton.small(
                            heroTag: 'my_loc_btn',
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                            elevation: 3,
                            onPressed: () => _centerTo(userPos, zoom: 15.0),
                            tooltip: 'Ke Posisi Saya',
                            child: const Icon(Icons.my_location_rounded),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Tombol Zoom In
                        FloatingActionButton.small(
                          heroTag: 'zoom_in_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 3,
                          onPressed: () {
                            final z = _mapController.camera.zoom + 1;
                            _mapController.move(_mapController.camera.center, z);
                          },
                          child: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(height: 6),

                        // Tombol Zoom Out
                        FloatingActionButton.small(
                          heroTag: 'zoom_out_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 3,
                          onPressed: () {
                            final z = _mapController.camera.zoom - 1;
                            _mapController.move(_mapController.camera.center, z);
                          },
                          child: const Icon(Icons.remove_rounded),
                        ),
                      ],
                    ),
                  ),

                  // Overlay Jika Tidak Ada Cabang yang Cocok
                  if (_filteredCabangs.isEmpty)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'Kantor Cabang Tidak Ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tidak ada cabang yang cocok dengan kata kunci atau filter provinsi ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedProvince = 'Semua';
                                _applyFilter();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Tampilkan Semua Cabang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating Focused Branch Card di Bagian Bawah Peta
                  if (_focusedCabang != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: lightGreenBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _focusedCabang!.name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Kode: ${_focusedCabang!.code} • ${_focusedCabang!.displayLocation}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_focusedCabang!.formattedDistance != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: lightGreenBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: lightGreenBorder),
                                    ),
                                    child: Text(
                                      '📍 ${_focusedCabang!.formattedDistance}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (_focusedCabang!.address != null &&
                                _focusedCabang!.address!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _focusedCabang!.address!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                              ),
                            ],

                            // Informasi Kontak Cabang (Telepon & WhatsApp)
                            if (_focusedCabang!.phone != null &&
                                _focusedCabang!.phone!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF25D366)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CS: ${_focusedCabang!.phone}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'WhatsApp CS',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Tombol Aksi
                            if (isSelectionMode) ...[
                              // Mode Pendaftaran: Pilih Cabang Ini + Kontak WhatsApp + Rute
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        widget.onSelectCabang!(_focusedCabang!);
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                                      label: const Text(
                                        'Pilih Cabang Ini',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  if (_focusedCabang!.phone != null && _focusedCabang!.phone!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    IconButton.filled(
                                      onPressed: () => _openWhatsApp(_focusedCabang!),
                                      icon: const Icon(Icons.chat_rounded, size: 18),
                                      tooltip: 'Hubungi WhatsApp',
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(11),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () => _openExternalMaps(_focusedCabang!),
                                    icon: const Icon(Icons.map_outlined, size: 16),
                                    label: const Text(
                                      'Rute',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(color: primaryColor),
                                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Mode Informasi / Dashboard: Hubungi WhatsApp + Telepon + Rute Maps
                              Row(
                                children: [
                                  if (_focusedCabang!.phone != null && _focusedCabang!.phone!.isNotEmpty) ...[
                                    Expanded(
                                      flex: 3,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openWhatsApp(_focusedCabang!),
                                        icon: const Icon(Icons.chat_rounded, size: 16),
                                        label: const Text(
                                          'WhatsApp CS',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    flex: 2,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openExternalMaps(_focusedCabang!),
                                      icon: const Icon(Icons.map_outlined, size: 16),
                                      label: const Text(
                                        'Rute Maps',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(color: primaryColor),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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
