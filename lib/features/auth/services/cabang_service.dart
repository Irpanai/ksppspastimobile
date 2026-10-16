import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cabang_model.dart';

class CabangService {
  /// Cache semua cabang yang sudah di-fetch untuk performa cepat & offline-friendly
  static List<CabangModel>? _cachedAllCabangs;

  /// Hitung jarak antara dua koordinat geografis dalam satuan kilometer (Rumus Haversine)
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Mengambil seluruh cabang terdaftar yang diurutkan berdasarkan jarak terdekat dari pengguna
  static Future<List<CabangModel>> getCabangsSortedByDistance(double userLat, double userLon) async {
    final allCabangs = await getAllCabangs();
    final List<CabangModel> withDistance = [];

    for (final c in allCabangs) {
      if (c.latitude != null && c.longitude != null) {
        final dist = calculateDistanceKm(userLat, userLon, c.latitude!, c.longitude!);
        withDistance.add(c.copyWith(distanceInKm: dist));
      } else {
        withDistance.add(c);
      }
    }

    withDistance.sort((a, b) {
      if (a.distanceInKm == null && b.distanceInKm == null) return 0;
      if (a.distanceInKm == null) return 1;
      if (b.distanceInKm == null) return -1;
      return a.distanceInKm!.compareTo(b.distanceInKm!);
    });

    return withDistance;
  }

  /// Mengambil daftar provinsi yang memiliki kantor cabang
  static Future<List<String>> getProvinces() async {
    try {
      // 1. Coba panggil endpoint dedicated /cabangs/provinces
      final response = await ApiClient.get<List<dynamic>>(
        ApiConstants.cabangProvinces,
        withAuth: false,
        fromJsonT: (data) => data as List<dynamic>,
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final list = response.data!
            .map((item) {
              if (item is Map<String, dynamic>) {
                return item['province']?.toString().trim() ?? '';
              }
              return item.toString().trim();
            })
            .where((p) => p.isNotEmpty)
            .toList();

        if (list.isNotEmpty) {
          list.sort();
          return list;
        }
      }
    } catch (e) {
      debugPrint('[CabangService] Error fetching /cabangs/provinces: $e');
    }

    // 2. Fallback: Ambil dari /cabangs (semua cabang) lalu ambil distinct province
    try {
      final allCabangs = await getAllCabangs();
      final provinces = allCabangs
          .map((c) => c.province?.trim() ?? '')
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();

      if (provinces.isNotEmpty) {
        provinces.sort();
        return provinces;
      }
    } catch (e) {
      debugPrint('[CabangService] Error extracting provinces from all cabangs: $e');
    }

    // 3. Fallback default jika offline / backend belum mengembalikan data
    return _defaultProvinces;
  }

  /// Mengambil seluruh data cabang aktif
  static Future<List<CabangModel>> getAllCabangs({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAllCabangs != null && _cachedAllCabangs!.isNotEmpty) {
      return _cachedAllCabangs!;
    }

    try {
      final response = await ApiClient.get<List<dynamic>>(
        ApiConstants.cabangs,
        withAuth: false,
        fromJsonT: (data) => data as List<dynamic>,
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final list = response.data!
            .map((item) => CabangModel.fromJson(item as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();

        if (list.isNotEmpty) {
          _cachedAllCabangs = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('[CabangService] Error fetching /cabangs: $e');
    }

    return _defaultCabangList;
  }

  /// Mengambil data cabang terdaftar berdasarkan provinsi
  static Future<List<CabangModel>> getCabangsByProvince(String province) async {
    final cleanProvince = province.trim().toUpperCase();

    try {
      final response = await ApiClient.get<List<dynamic>>(
        '${ApiConstants.cabangs}?province=${Uri.encodeComponent(province)}',
        withAuth: false,
        fromJsonT: (data) => data as List<dynamic>,
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final list = response.data!
            .map((item) => CabangModel.fromJson(item as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();

        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[CabangService] Error fetching cabangs for province $province: $e');
    }

    // Fallback: Filter dari seluruh data cabang
    final allCabangs = await getAllCabangs();
    final filtered = allCabangs.where((c) {
      final cProv = (c.province ?? '').trim().toUpperCase();
      return cProv.contains(cleanProvince) || cleanProvince.contains(cProv);
    }).toList();

    if (filtered.isNotEmpty) return filtered;

    // Default fallback jika tidak ada cabang di provinsi tersebut
    return [
      CabangModel(
        id: 1,
        code: 'HO-BJM',
        name: 'Head Office Banjarmasin',
        city: 'KOTA BANJARMASIN',
        province: province,
        address: 'Gedung Intira, Jl. Pangeran Antasari No. 10',
      ),
    ];
  }

  /// Daftar provinsi default dari cabang KSPPS PASTI yang terdaftar
  static final List<String> _defaultProvinces = [
    'ACEH',
    'BALI',
    'BENGKULU',
    'GORONTALO',
    'JAMBI',
    'JAWA TENGAH',
    'JAWA TIMUR',
    'KALIMANTAN BARAT',
    'KALIMANTAN SELATAN',
    'KALIMANTAN TENGAH',
    'KALIMANTAN TIMUR',
    'KEPULAUAN BANGKA BELITUNG',
    'LAMPUNG',
    'MALUKU',
    'NUSA TENGGARA BARAT',
    'NUSA TENGGARA TIMUR',
    'RIAU',
    'SULAWESI BARAT',
    'SULAWESI SELATAN',
    'SULAWESI TENGAH',
    'SULAWESI TENGGARA',
    'SULAWESI UTARA',
    'SUMATERA BARAT',
    'SUMATERA SELATAN',
  ];

  /// Daftar cabang default KSPPS PASTI jika backend offline
  static final List<CabangModel> _defaultCabangList = [
    CabangModel(
      id: 1,
      code: 'HO-BJM',
      name: 'Head Office Banjarmasin',
      phone: '021-5000000',
      address: 'Gedung Intira, Jl. Pangeran Antasari No. 10',
      city: 'KOTA BANJARMASIN',
      province: 'KALIMANTAN SELATAN',
      latitude: -3.32490,
      longitude: 114.59010,
    ),
    CabangModel(
      id: 12,
      code: 'BJM-003',
      name: 'KC ANTASARI',
      phone: '0823-5147-0880',
      address: 'Jl. Antasari RT.06 Pekapuran Raya',
      city: 'KOTA BANJARMASIN',
      province: 'KALIMANTAN SELATAN',
      latitude: -3.32850,
      longitude: 114.59780,
    ),
    CabangModel(
      id: 13,
      code: 'BJM-004',
      name: 'KC KAYUTANGI',
      phone: '0821-4455-6677',
      address: 'Jl. Brigjend H. Hasan Basry No. 45',
      city: 'KOTA BANJARMASIN',
      province: 'KALIMANTAN SELATAN',
      latitude: -3.29820,
      longitude: 114.58890,
    ),
    CabangModel(
      id: 14,
      code: 'BJB-001',
      name: 'KC BANJARBARU',
      phone: '0813-8899-0011',
      address: 'Jl. A. Yani Km. 34, Loktabat',
      city: 'KOTA BANJARBARU',
      province: 'KALIMANTAN SELATAN',
      latitude: -3.44060,
      longitude: 114.83060,
    ),
    CabangModel(
      id: 15,
      code: 'MTP-001',
      name: 'KC MARTAPURA',
      phone: '0812-3344-5566',
      address: 'Jl. Sukaramai Pasar Batuah',
      city: 'KABUPATEN BANJAR',
      province: 'KALIMANTAN SELATAN',
      latitude: -3.41160,
      longitude: 114.85170,
    ),
    CabangModel(
      id: 16,
      code: 'PLK-001',
      name: 'KC PALANGKARAYA',
      phone: '0852-7788-9900',
      address: 'Jl. RTA Milono Km. 2.5',
      city: 'KOTA PALANGKARAYA',
      province: 'KALIMANTAN TENGAH',
      latitude: -2.20780,
      longitude: 113.91650,
    ),
    CabangModel(
      id: 17,
      code: 'SMG-001',
      name: 'KC SEMARANG BARAT',
      phone: '024-7654321',
      address: 'Jl. Pamularsih Raya No. 88',
      city: 'KOTA SEMARANG',
      province: 'JAWA TENGAH',
      latitude: -6.99320,
      longitude: 110.39570,
    ),
    CabangModel(
      id: 18,
      code: 'SOLO-001',
      name: 'KC SOLO',
      phone: '0271-654321',
      address: 'Jl. Slamet Riyadi No. 120',
      city: 'KOTA SURAKARTA',
      province: 'JAWA TENGAH',
      latitude: -7.56930,
      longitude: 110.82500,
    ),
    CabangModel(
      id: 19,
      code: 'KDS-001',
      name: 'KC KUDUS',
      phone: '0291-432109',
      address: 'Jl. Jend. Sudirman No. 50',
      city: 'KABUPATEN KUDUS',
      province: 'JAWA TENGAH',
      latitude: -6.80480,
      longitude: 110.84050,
    ),
  ];
}
