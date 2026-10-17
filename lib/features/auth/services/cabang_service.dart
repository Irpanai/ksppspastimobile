import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cabang_model.dart';

class CabangService {
  /// Cache semua cabang yang sudah di-fetch untuk performa cepat saat bernavigasi
  static List<CabangModel>? _cachedAllCabangs;

  /// Membersihkan cache cabang jika ingin memaksa fetch ulang dari API
  static void clearCache() {
    _cachedAllCabangs = null;
  }

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

  /// Mengambil seluruh cabang terdaftar dari API yang diurutkan berdasarkan jarak terdekat dari pengguna
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

  /// Mengambil daftar provinsi yang memiliki kantor cabang dari API
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

    // 2. Ambil dari endpoint /cabangs lalu ekstrak distinct province
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
      debugPrint('[CabangService] Error extracting provinces from cabangs API: $e');
    }

    return const <String>[];
  }

  /// Mengambil seluruh data cabang aktif langsung dari API
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

    return const <CabangModel>[];
  }

  /// Mengambil data cabang terdaftar berdasarkan provinsi langsung dari API
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

    // Filter dari seluruh data cabang yang diambil dari API
    final allCabangs = await getAllCabangs();
    final filtered = allCabangs.where((c) {
      final cProv = (c.province ?? '').trim().toUpperCase();
      return cProv.contains(cleanProvince) || cleanProvince.contains(cProv);
    }).toList();

    return filtered;
  }
}
