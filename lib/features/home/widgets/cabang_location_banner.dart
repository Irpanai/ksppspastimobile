import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/services/cabang_service.dart';
import '../../auth/widgets/cabang_map_modal.dart';

/// Banner Pintas Sebaran Kantor Cabang KSPPS PASTI untuk Dashboard Utama
class CabangLocationBanner extends StatefulWidget {
  const CabangLocationBanner({super.key});

  @override
  State<CabangLocationBanner> createState() => _CabangLocationBannerState();
}

class _CabangLocationBannerState extends State<CabangLocationBanner> {
  bool _isLoading = false;
  int? _branchCount;

  @override
  void initState() {
    super.initState();
    _loadBranchCount();
  }

  Future<void> _loadBranchCount() async {
    try {
      final allCabangs = await CabangService.getAllCabangs();
      if (mounted && allCabangs.isNotEmpty) {
        setState(() {
          _branchCount = allCabangs.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _openBranchMap(BuildContext context) async {
    setState(() => _isLoading = true);

    double? userLat;
    double? userLon;

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        userLat = pos.latitude;
        userLon = pos.longitude;
      }
    } catch (_) {}

    try {
      final allCabangs = await CabangService.getAllCabangs(forceRefresh: true);

      if (!context.mounted) return;

      CabangMapModal.show(
        context: context,
        allCabangs: allCabangs,
        userLatitude: userLat,
        userLongitude: userLon,
      );
    } catch (e) {
      debugPrint('[CabangLocationBanner] Error opening map: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        shadowColor: primaryColor.withValues(alpha: 0.12),
        child: InkWell(
          onTap: _isLoading ? null : () => _openBranchMap(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  primaryColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                // Ikon Peta / Kantor Cabang
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Teks Judul & Deskripsi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Sebaran Kantor Cabang',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _branchCount != null ? '$_branchCount Cabang' : '101 Cabang',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Peta lokasi satelit, rute & kontak WhatsApp CS',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Buka
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: primaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
