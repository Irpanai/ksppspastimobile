class CabangModel {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String? province;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final double? distanceInKm;

  CabangModel({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.province,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.distanceInKm,
  });

  factory CabangModel.fromJson(Map<String, dynamic> json) {
    return CabangModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      province: json['province']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
    };
  }

  /// Label bantuan untuk display dropdown
  String get displayLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty && province != city) parts.add(province!);
    return parts.join(', ');
  }

  /// Jarak terformat (misal: "850 m" atau "2.4 km")
  String? get formattedDistance {
    if (distanceInKm == null) return null;
    if (distanceInKm! < 1) {
      return '${(distanceInKm! * 1000).round()} m';
    }
    return '${distanceInKm!.toStringAsFixed(1)} km';
  }

  CabangModel copyWith({
    int? id,
    String? code,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? province,
    double? latitude,
    double? longitude,
    bool? isActive,
    double? distanceInKm,
  }) {
    return CabangModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      distanceInKm: distanceInKm ?? this.distanceInKm,
    );
  }
}

class ProvinceCabangModel {
  final String province;
  final int totalCabang;

  ProvinceCabangModel({
    required this.province,
    this.totalCabang = 0,
  });

  factory ProvinceCabangModel.fromJson(Map<String, dynamic> json) {
    return ProvinceCabangModel(
      province: json['province']?.toString() ?? '',
      totalCabang: json['total_cabang'] is int
          ? json['total_cabang']
          : int.tryParse(json['total_cabang']?.toString() ?? '0') ?? 0,
    );
  }
}
