import 'package:flutter/material.dart';

class PaymentChannelModel {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? badge;
  final String? description;
  final Color tagColor;
  final IconData icon;
  final int minAmount;
  final int feeFlat;
  final String feeType;
  final double feePercent;
  final int feeThreshold;
  final int feeBelowThreshold;
  final double feeAboveThresholdPercent;
  final int sortOrder;
  final bool isActive;
  final String? maintenanceMessage;

  const PaymentChannelModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.badge,
    this.description,
    required this.tagColor,
    required this.icon,
    this.minAmount = 10000,
    this.feeFlat = 0,
    this.feeType = 'flat',
    this.feePercent = 0.0,
    this.feeThreshold = 100000,
    this.feeBelowThreshold = 0,
    this.feeAboveThresholdPercent = 0.0,
    this.sortOrder = 0,
    this.isActive = true,
    this.maintenanceMessage,
  });

  /// Hitung biaya layanan riil berdasarkan nominal setoran
  int calculateFee(int amount) {
    if (feeType == 'percent') {
      return (amount * (feePercent / 100)).round();
    }
    if (feeType == 'conditional') {
      if (amount <= feeThreshold) {
        return feeBelowThreshold > 0 ? feeBelowThreshold : feeFlat;
      } else {
        return (amount * (feeAboveThresholdPercent / 100)).round();
      }
    }
    return feeFlat;
  }

  factory PaymentChannelModel.fromJson(Map<String, dynamic> json) {
    final colorHex = json['tag_color'] as String? ?? '#0F766E';
    final iconName = json['icon_name'] as String? ?? 'account_balance_rounded';
    final code = json['code'] as String? ?? '';
    final isActiveRaw = json['is_active'];
    final bool active = isActiveRaw == null ? true : (isActiveRaw == true || isActiveRaw == 1 || isActiveRaw.toString() == 'true');

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is int) return val;
      if (val == null) return fallback;
      return int.tryParse(val.toString()) ?? fallback;
    }

    return PaymentChannelModel(
      id: parseInt(json['id']),
      code: code,
      name: json['name'] as String? ?? 'Kanal Pembayaran',
      category: json['category'] as String? ?? 'virtual_account',
      badge: json['badge'] as String?,
      description: json['description'] as String?,
      tagColor: _parseColor(colorHex, code),
      icon: _parseIcon(iconName, code),
      minAmount: parseInt(json['min_amount'], 10000),
      feeFlat: parseInt(json['fee_flat'], 0),
      feeType: json['fee_type'] as String? ?? 'flat',
      feePercent: parseDouble(json['fee_percent']),
      feeThreshold: parseInt(json['fee_threshold'], 100000),
      feeBelowThreshold: parseInt(json['fee_below_threshold'], 0),
      feeAboveThresholdPercent: parseDouble(json['fee_above_threshold_percent']),
      sortOrder: parseInt(json['sort_order'], 0),
      isActive: active,
      maintenanceMessage: json['maintenance_message'] as String?,
    );
  }

  static Color _parseColor(String hex, String code) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}

    // Fallbacks
    switch (code.toLowerCase()) {
      case 'bsi':
        return const Color(0xFF00A39D);
      case 'bca':
        return const Color(0xFF005DAA);
      case 'mandiri':
        return const Color(0xFF003D79);
      case 'bri':
        return const Color(0xFF00529C);
      case 'bni':
        return const Color(0xFFE55300);
      case 'cimb':
        return const Color(0xFF8B0000);
      case 'danamon':
        return const Color(0xFFFF6600);
      case 'qris':
      case 'checkout':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }

  static IconData _parseIcon(String name, String code) {
    if (code == 'bsi' || name.contains('mosque')) {
      return Icons.mosque_rounded;
    }
    if (code == 'checkout' || code == 'qris' || name.toLowerCase().contains('qr')) {
      return Icons.qr_code_scanner_rounded;
    }
    return Icons.account_balance_rounded;
  }

  /// Default fallback channels jika offline atau gagal memuat API
  static List<PaymentChannelModel> get defaultChannels => const [
    PaymentChannelModel(
      id: 1,
      code: 'bsi',
      name: 'BSI Virtual Account',
      category: 'virtual_account',
      badge: 'Syariah (Native)',
      description: 'Transfer syariah via BSI Mobile, ATM BSI, & ATM Bersama',
      tagColor: Color(0xFF00A39D),
      icon: Icons.mosque_rounded,
      sortOrder: 1,
    ),
    PaymentChannelModel(
      id: 2,
      code: 'bca',
      name: 'BCA Virtual Account',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Verifikasi otomatis instan via m-BCA, myBCA, & ATM',
      tagColor: Color(0xFF005DAA),
      icon: Icons.account_balance_rounded,
      sortOrder: 2,
    ),
    PaymentChannelModel(
      id: 3,
      code: 'mandiri',
      name: 'Mandiri Virtual Account',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Transfer via Livin\' by Mandiri, ATM, & Internet Banking',
      tagColor: Color(0xFF003D79),
      icon: Icons.account_balance_rounded,
      sortOrder: 3,
    ),
    PaymentChannelModel(
      id: 4,
      code: 'bri',
      name: 'BRI Virtual Account (BRIVA)',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Transfer mudah via BRImo, ATM BRI, & Agen BRILink',
      tagColor: Color(0xFF00529C),
      icon: Icons.account_balance_rounded,
      sortOrder: 4,
    ),
    PaymentChannelModel(
      id: 5,
      code: 'bni',
      name: 'BNI Virtual Account',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Transfer via BNI Mobile Banking, ATM, & Agen46',
      tagColor: Color(0xFFE55300),
      icon: Icons.account_balance_rounded,
      sortOrder: 5,
    ),
    PaymentChannelModel(
      id: 6,
      code: 'cimb',
      name: 'CIMB Niaga Virtual Account',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Transfer via OCTO Mobile & ATM CIMB Niaga',
      tagColor: Color(0xFF8B0000),
      icon: Icons.account_balance_rounded,
      sortOrder: 6,
    ),
    PaymentChannelModel(
      id: 7,
      code: 'danamon',
      name: 'Danamon Virtual Account',
      category: 'virtual_account',
      badge: 'Native In-App',
      description: 'Transfer via D-Bank PRO & ATM Danamon',
      tagColor: Color(0xFFFF6600),
      icon: Icons.account_balance_rounded,
      sortOrder: 7,
    ),
    PaymentChannelModel(
      id: 8,
      code: 'qris',
      name: 'QRIS (Semua Bank & E-Wallet)',
      category: 'qris',
      badge: 'Instan (Native)',
      description: 'Scan QRIS via BCA, Mandiri, BRI, BSI, GoPay, OVO, Dana, ShopeePay',
      tagColor: Color(0xFFDC2626),
      icon: Icons.qr_code_scanner_rounded,
      sortOrder: 8,
    ),
  ];
}
