import '../../../../core/utils/currency_formatter.dart';

class SnapTokenResponse {
  final String orderId;
  final String snapToken;
  final String snapRedirectUrl;
  final num nominal;
  final String nominalFormat;
  final String type;
  final String status;
  final String? clientKey;
  final String? createdAt;

  SnapTokenResponse({
    required this.orderId,
    required this.snapToken,
    required this.snapRedirectUrl,
    required this.nominal,
    required this.nominalFormat,
    required this.type,
    required this.status,
    this.clientKey,
    this.createdAt,
  });

  factory SnapTokenResponse.fromJson(Map<String, dynamic> json) {
    num parseNominal(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    final nom = parseNominal(json['nominal']);
    return SnapTokenResponse(
      orderId: json['order_id']?.toString() ?? '',
      snapToken: json['snap_token']?.toString() ?? '',
      snapRedirectUrl: json['snap_redirect_url']?.toString() ?? '',
      nominal: nom,
      nominalFormat: json['nominal_format']?.toString() ?? AppCurrency.format(nom),
      type: json['type']?.toString() ?? 'simpanan_sukarela',
      status: json['status']?.toString() ?? 'pending',
      clientKey: json['client_key']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'snap_token': snapToken,
      'snap_redirect_url': snapRedirectUrl,
      'nominal': nominal,
      'nominal_format': nominalFormat,
      'type': type,
      'status': status,
      'client_key': clientKey,
      'created_at': createdAt,
    };
  }
}

class PaymentStatusResponse {
  final String orderId;
  final String type;
  final num nominal;
  final String nominalFormat;
  final String status;
  final String? paymentType;
  final String? paymentChannel;
  final String? vaNumber;
  final String? paidAt;

  PaymentStatusResponse({
    required this.orderId,
    required this.type,
    required this.nominal,
    required this.nominalFormat,
    required this.status,
    this.paymentType,
    this.paymentChannel,
    this.vaNumber,
    this.paidAt,
  });

  bool get isSettlement => status.toLowerCase() == 'settlement' || status.toLowerCase() == 'capture' || status.toLowerCase() == 'success' || status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isExpiredOrCancelled => status.toLowerCase() == 'expire' || status.toLowerCase() == 'cancel' || status.toLowerCase() == 'deny';

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    num parseNominal(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    final nom = parseNominal(json['nominal']);
    return PaymentStatusResponse(
      orderId: json['order_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      nominal: nom,
      nominalFormat: json['nominal_format']?.toString() ?? AppCurrency.format(nom),
      status: json['status']?.toString() ?? 'pending',
      paymentType: json['payment_type']?.toString(),
      paymentChannel: json['payment_channel']?.toString(),
      vaNumber: json['va_number']?.toString(),
      paidAt: json['paid_at']?.toString(),
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final String orderId;
  final String type;
  final num nominal;
  final String status;
  final String? paymentType;
  final String? createdAt;

  PaymentHistoryItem({
    required this.id,
    required this.orderId,
    required this.type,
    required this.nominal,
    required this.status,
    this.paymentType,
    this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    num parseNominal(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    return PaymentHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      nominal: parseNominal(json['nominal']),
      status: json['status']?.toString() ?? 'pending',
      paymentType: json['payment_type']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
