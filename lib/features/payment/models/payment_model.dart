import '../../../../core/utils/currency_formatter.dart';

class SnapTokenResponse {
  final String orderId;
  final String snapToken;
  final String snapRedirectUrl;
  final String paymentUrl;
  final num nominal;
  final String nominalFormat;
  final num adminFee;
  final num grossAmount;
  final String adminFeeFormat;
  final String grossAmountFormat;
  final String type;
  final String status;
  final String? clientKey;
  final String? clientId;
  final String gateway;
  final String? createdAt;
  final String paymentMode;
  final String paymentMethod;
  final String? bank;
  final String? bankName;
  final String? vaNumber;
  final String? expiredDate;
  final Map<String, dynamic>? instructions;
  final String? howToPayPage;

  final bool isDirectQris;
  final String? qrString;
  final String? nmid;

  SnapTokenResponse({
    required this.orderId,
    required this.snapToken,
    required this.snapRedirectUrl,
    String? paymentUrl,
    required this.nominal,
    required this.nominalFormat,
    this.adminFee = 0,
    num? grossAmount,
    String? adminFeeFormat,
    String? grossAmountFormat,
    required this.type,
    required this.status,
    this.clientKey,
    this.clientId,
    this.gateway = 'doku',
    this.createdAt,
    this.paymentMode = 'checkout_url',
    this.paymentMethod = 'checkout',
    this.bank,
    this.bankName,
    this.vaNumber,
    this.expiredDate,
    this.instructions,
    this.howToPayPage,
    this.isDirectQris = false,
    this.qrString,
    this.nmid,
  })  : paymentUrl = paymentUrl ?? snapRedirectUrl,
        grossAmount = grossAmount ?? (nominal + adminFee),
        adminFeeFormat = adminFeeFormat ?? AppCurrency.format(adminFee),
        grossAmountFormat = grossAmountFormat ?? AppCurrency.format(grossAmount ?? (nominal + adminFee));

  bool get isDirectVa =>
      paymentMode == 'direct_va' || (vaNumber != null && vaNumber!.isNotEmpty);

  String get displayPaymentMethod {
    if (isDirectQris) return 'QRIS Nasional';
    if (isDirectVa) {
      if (bankName != null && bankName!.isNotEmpty) return bankName!;
      if (bank != null && bank!.isNotEmpty) return ' Virtual Account';
      return 'Virtual Account';
    }
    return 'DOKU Checkout';
  }

  String get displayType {
    switch (type.toLowerCase()) {
      case 'simpanan_sukarela':
        return 'Simpanan Sukarela';
      case 'simpanan_wajib':
        return 'Simpanan Wajib';
      case 'simpanan_pokok':
        return 'Simpanan Pokok';
      case 'pembukaan_sijaka':
        return 'Deposito SIJAKA';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory SnapTokenResponse.fromJson(Map<String, dynamic> json) {
    num parseNominal(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    final nom = parseNominal(json['nominal']);
    final fee = parseNominal(json['admin_fee']);
    final gross = parseNominal(json['gross_amount']);
    final effectiveGross = gross > 0 ? gross : (nom + fee);
    final redirectUrl = json['payment_url']?.toString() ?? json['snap_redirect_url']?.toString() ?? '';
    final qrStr = json['qr_string']?.toString();
    final isQris = json['is_direct_qris'] == true ||
        json['payment_mode'] == 'direct_qris' ||
        json['payment_method'] == 'qris' ||
        (qrStr != null && qrStr.isNotEmpty);

    return SnapTokenResponse(
      orderId: json['order_id']?.toString() ?? '',
      snapToken: json['snap_token']?.toString() ?? json['order_id']?.toString() ?? '',
      snapRedirectUrl: redirectUrl,
      paymentUrl: redirectUrl,
      nominal: nom,
      nominalFormat: json['nominal_format']?.toString() ?? AppCurrency.format(nom),
      adminFee: fee,
      grossAmount: effectiveGross,
      adminFeeFormat: json['admin_fee_format']?.toString() ?? AppCurrency.format(fee),
      grossAmountFormat: json['gross_amount_format']?.toString() ?? AppCurrency.format(effectiveGross),
      type: json['type']?.toString() ?? 'simpanan_sukarela',
      status: json['status']?.toString() ?? 'pending',
      clientKey: json['client_key']?.toString(),
      clientId: json['client_id']?.toString(),
      gateway: json['gateway']?.toString() ?? (json['payment_url'] != null ? 'doku' : 'midtrans'),
      createdAt: json['created_at']?.toString(),
      paymentMode: json['payment_mode']?.toString() ?? (isQris ? 'direct_qris' : 'checkout_url'),
      paymentMethod: json['payment_method']?.toString() ?? (isQris ? 'qris' : 'checkout'),
      bank: json['bank']?.toString(),
      bankName: json['bank_name']?.toString(),
      vaNumber: json['va_number']?.toString(),
      expiredDate: json['expired_date']?.toString(),
      instructions: json['instructions'] is Map ? Map<String, dynamic>.from(json['instructions'] as Map) : null,
      howToPayPage: json['how_to_pay_page']?.toString(),
      isDirectQris: isQris,
      qrString: qrStr,
      nmid: json['nmid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'snap_token': snapToken,
      'snap_redirect_url': snapRedirectUrl,
      'payment_url': paymentUrl,
      'nominal': nominal,
      'nominal_format': nominalFormat,
      'admin_fee': adminFee,
      'gross_amount': grossAmount,
      'admin_fee_format': adminFeeFormat,
      'gross_amount_format': grossAmountFormat,
      'type': type,
      'status': status,
      'client_key': clientKey,
      'client_id': clientId,
      'gateway': gateway,
      'created_at': createdAt,
      'payment_mode': paymentMode,
      'payment_method': paymentMethod,
      'bank': bank,
      'bank_name': bankName,
      'va_number': vaNumber,
      'expired_date': expiredDate,
      'instructions': instructions,
      'how_to_pay_page': howToPayPage,
      'is_direct_qris': isDirectQris,
      'qr_string': qrString,
      'nmid': nmid,
    };
  }
}

/// Alias typedef for DOKU Checkout
typedef PaymentCheckoutResponse = SnapTokenResponse;

class PaymentStatusResponse {
  final String orderId;
  final String type;
  final num nominal;
  final String nominalFormat;
  final num adminFee;
  final num grossAmount;
  final String adminFeeFormat;
  final String grossAmountFormat;
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
    this.adminFee = 0,
    num? grossAmount,
    String? adminFeeFormat,
    String? grossAmountFormat,
    required this.status,
    this.paymentType,
    this.paymentChannel,
    this.vaNumber,
    this.paidAt,
  })  : grossAmount = grossAmount ?? (nominal + adminFee),
        adminFeeFormat = adminFeeFormat ?? AppCurrency.format(adminFee),
        grossAmountFormat = grossAmountFormat ?? AppCurrency.format(grossAmount ?? (nominal + adminFee));

  bool get isSettled => isSettlement;
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
    final fee = parseNominal(json['admin_fee']);
    final gross = parseNominal(json['gross_amount']);
    final effectiveGross = gross > 0 ? gross : (nom + fee);

    return PaymentStatusResponse(
      orderId: json['order_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      nominal: nom,
      nominalFormat: json['nominal_format']?.toString() ?? AppCurrency.format(nom),
      adminFee: fee,
      grossAmount: effectiveGross,
      adminFeeFormat: json['admin_fee_format']?.toString() ?? AppCurrency.format(fee),
      grossAmountFormat: json['gross_amount_format']?.toString() ?? AppCurrency.format(effectiveGross),
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
  final num adminFee;
  final num grossAmount;
  final String status;
  final String? paymentType;
  final String? createdAt;

  PaymentHistoryItem({
    required this.id,
    required this.orderId,
    required this.type,
    required this.nominal,
    this.adminFee = 0,
    num? grossAmount,
    required this.status,
    this.paymentType,
    this.createdAt,
  }) : grossAmount = grossAmount ?? (nominal + adminFee);

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    num parseNominal(dynamic val) {
      if (val is num) return val;
      if (val == null) return 0;
      return num.tryParse(val.toString()) ?? 0;
    }

    final nom = parseNominal(json['nominal']);
    final fee = parseNominal(json['admin_fee']);
    final gross = parseNominal(json['gross_amount']);
    final effectiveGross = gross > 0 ? gross : (nom + fee);

    return PaymentHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      nominal: nom,
      adminFee: fee,
      grossAmount: effectiveGross,
      status: json['status']?.toString() ?? 'pending',
      paymentType: json['payment_type']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
