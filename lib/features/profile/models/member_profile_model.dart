import 'package:intl/intl.dart';
import '../../auth/models/user_model.dart';

class MemberProfileModel {
  final UserModel user;
  final AnggotaModel? anggota;
  final RingkasanSaldoModel? ringkasanSaldo;

  MemberProfileModel({
    required this.user,
    this.anggota,
    this.ringkasanSaldo,
  });

  factory MemberProfileModel.fromJson(Map<String, dynamic> json) {
    return MemberProfileModel(
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(id: 0, name: '', email: ''),
      anggota: json['anggota'] is Map<String, dynamic>
          ? AnggotaModel.fromJson(json['anggota'] as Map<String, dynamic>)
          : null,
      ringkasanSaldo: json['ringkasan_saldo'] is Map<String, dynamic>
          ? RingkasanSaldoModel.fromJson(json['ringkasan_saldo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'anggota': anggota?.toJson(),
      'ringkasan_saldo': ringkasanSaldo?.toJson(),
    };
  }
}

class RingkasanSaldoModel {
  final double saldoPokok;
  final double saldoWajib;
  final double saldoSukarela;
  final double saldoSijaka;
  final double saldoBagihasilSijaka;
  final double totalSaldo;

  RingkasanSaldoModel({
    required this.saldoPokok,
    required this.saldoWajib,
    required this.saldoSukarela,
    required this.saldoSijaka,
    required this.saldoBagihasilSijaka,
    required this.totalSaldo,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory RingkasanSaldoModel.fromJson(Map<String, dynamic> json) {
    return RingkasanSaldoModel(
      saldoPokok: _parseDouble(json['saldo_pokok']),
      saldoWajib: _parseDouble(json['saldo_wajib']),
      saldoSukarela: _parseDouble(json['saldo_sukarela']),
      saldoSijaka: _parseDouble(json['saldo_sijaka']),
      saldoBagihasilSijaka: _parseDouble(json['saldo_bagihasil_sijaka']),
      totalSaldo: _parseDouble(json['total_saldo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saldo_pokok': saldoPokok,
      'saldo_wajib': saldoWajib,
      'saldo_sukarela': saldoSukarela,
      'saldo_sijaka': saldoSijaka,
      'saldo_bagihasil_sijaka': saldoBagihasilSijaka,
      'total_saldo': totalSaldo,
    };
  }

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String get formattedSaldoPokok => _currencyFormatter.format(saldoPokok);
  String get formattedSaldoWajib => _currencyFormatter.format(saldoWajib);
  String get formattedSaldoSukarela => _currencyFormatter.format(saldoSukarela);
  String get formattedSaldoSijaka => _currencyFormatter.format(saldoSijaka);
  String get formattedSaldoBagihasilSijaka => _currencyFormatter.format(saldoBagihasilSijaka);
  String get formattedTotalSaldo => _currencyFormatter.format(totalSaldo);
}
