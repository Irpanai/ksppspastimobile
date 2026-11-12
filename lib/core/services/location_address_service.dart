import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DetectedAddress {
  final String formattedAddress;
  final String? street;
  final String? kelurahan;
  final String? kecamatan;
  final String? kabupatenKota;
  final String? provinsi;

  const DetectedAddress({
    required this.formattedAddress,
    this.street,
    this.kelurahan,
    this.kecamatan,
    this.kabupatenKota,
    this.provinsi,
  });

  bool get hasAny =>
      formattedAddress.trim().isNotEmpty ||
      (street != null && street!.trim().isNotEmpty) ||
      (kelurahan != null && kelurahan!.trim().isNotEmpty) ||
      (kecamatan != null && kecamatan!.trim().isNotEmpty) ||
      (kabupatenKota != null && kabupatenKota!.trim().isNotEmpty) ||
      (provinsi != null && provinsi!.trim().isNotEmpty);

  static DetectedAddress? fromPlatformMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) return null;
    final street = _cleanOrNull(raw['street']?.toString());
    final kel = _cleanOrNull(raw['kelurahan']?.toString());
    final kec = _cleanOrNull(raw['kecamatan']?.toString());
    final kab = _cleanOrNull(raw['kabupatenKota']?.toString());
    final prov = _cleanOrNull(raw['provinsi']?.toString());
    final platformFormatted = _cleanOrNull(raw['formattedAddress']?.toString());

    final formatted = _buildCompactAddress(
      street: street,
      kelurahan: kel,
      kecamatan: kec,
      kabupatenKota: kab,
      provinsi: prov,
      fallback: platformFormatted,
    );

    if (formatted.isEmpty) return null;

    return DetectedAddress(
      formattedAddress: formatted,
      street: street,
      kelurahan: kel,
      kecamatan: kec,
      kabupatenKota: kab,
      provinsi: prov,
    );
  }

  static String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _buildCompactAddress({
    String? street,
    String? kelurahan,
    String? kecamatan,
    String? kabupatenKota,
    String? provinsi,
    String? fallback,
  }) {
    final parts = <String>[];
    if (street != null && street.isNotEmpty) {
      parts.add(street);
    }
    if (kelurahan != null && kelurahan.isNotEmpty) {
      parts.add(kelurahan);
    }
    if (kecamatan != null && kecamatan.isNotEmpty) {
      final upper = kecamatan.toUpperCase();
      parts.add(upper.startsWith('KEC') ? kecamatan : 'Kec. $kecamatan');
    }
    if (parts.isEmpty && kabupatenKota != null && kabupatenKota.isNotEmpty) {
      parts.add(kabupatenKota);
    }
    if (parts.isEmpty && provinsi != null && provinsi.isNotEmpty) {
      parts.add(provinsi);
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return fallback?.trim() ?? '';
  }
}

/// Service reverse geocoding berbasis Android Geocoder dengan fallback OSM Nominatim.
class LocationAddressService {
  static const MethodChannel _channel = MethodChannel(
    'com.ksppspasti.mobile/location_address',
  );

  static Future<DetectedAddress?> reverseGeocode(
    double latitude,
    double longitude, {
    http.Client? httpClient,
  }) async {
    // 1. Coba Geocoder native Android (cepat, tanpa API key eksternal)
    try {
      final nativeResult = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('reverseGeocode', {
            'lat': latitude,
            'lng': longitude,
          })
          .timeout(const Duration(seconds: 5));
      final parsedNative = DetectedAddress.fromPlatformMap(nativeResult);
      if (parsedNative != null && parsedNative.hasAny) {
        return parsedNative;
      }
    } on PlatformException {
      // Lanjut fallback HTTP jika layanan geocoder perangkat tidak tersedia
    } on MissingPluginException {
      // Di lingkungan unit test / iOS fallback ke HTTP
    } on TimeoutException {
      // Fallback HTTP bila native timeout
    } catch (_) {
      // Fallback HTTP untuk semua kegagalan tak terduga
    }

    // 2. Fallback OpenStreetMap Nominatim (Bahasa Indonesia)
    final client = httpClient ?? http.Client();
    final ownsClient = httpClient == null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toStringAsFixed(6),
        'lon': longitude.toStringAsFixed(6),
        'addressdetails': '1',
        'accept-language': 'id',
      });
      final response = await client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'KsppsPastiMobile/1.0 (https://ksppspasti.id)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return fromNominatimJson(decoded);
        }
      }
    } catch (_) {
      return null;
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
    return null;
  }

  /// Parser murni JSON OpenStreetMap Nominatim agar dapat diuji unit test.
  static DetectedAddress? fromNominatimJson(Map<String, dynamic> json) {
    final addrRaw = json['address'];
    final addr = addrRaw is Map
        ? addrRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
        : <String, String>{};

    final road = _firstNonEmpty(addr, [
      'road',
      'pedestrian',
      'residential',
      'footway',
      'path',
    ]);
    final houseNumber = _firstNonEmpty(addr, ['house_number']);
    final neighbourhood = _firstNonEmpty(addr, ['neighbourhood', 'hamlet']);

    String? street;
    if (road != null) {
      street = houseNumber != null ? '$road No. $houseNumber' : road;
      if (neighbourhood != null &&
          !street.toLowerCase().contains(neighbourhood.toLowerCase())) {
        street = '$street, $neighbourhood';
      }
    } else if (neighbourhood != null) {
      street = neighbourhood;
    }

    final kelurahan = _firstNonEmpty(addr, [
      'village',
      'quarter',
      'suburb',
      'urban_village',
    ]);

    final kecamatan = _firstNonEmpty(addr, [
      'subdistrict',
      'city_district',
      'municipality',
      'district',
    ]);

    final kabupatenKota = _firstNonEmpty(addr, [
      'city',
      'regency',
      'county',
      'town',
    ]);

    final provinsi = _firstNonEmpty(addr, ['state', 'province']);

    final displayName = DetectedAddress._cleanOrNull(
      json['display_name']?.toString(),
    );

    final formatted = DetectedAddress._buildCompactAddress(
      street: street,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      kabupatenKota: kabupatenKota,
      provinsi: provinsi,
      fallback: displayName,
    );

    if (formatted.isEmpty) return null;

    return DetectedAddress(
      formattedAddress: formatted,
      street: street,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      kabupatenKota: kabupatenKota,
      provinsi: provinsi,
    );
  }

  static String? _firstNonEmpty(Map<String, String> map, List<String> keys) {
    for (final key in keys) {
      final val = DetectedAddress._cleanOrNull(map[key]);
      if (val != null) return val;
    }
    return null;
  }
}

