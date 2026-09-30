import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/sijaka_model.dart';
import '../services/sijaka_service.dart';

class SijakaProvider extends ChangeNotifier {
  final SijakaService _sijakaService = SijakaService();

  List<BilyetSijakaItem> _bilyetList = [];
  List<SijakaProdukItem> _produkList = [];
  bool _isLoading = false;
  bool _isLoadingProduk = false;
  String? _errorMessage;
  String? _produkError;
  String? _selectedStatus;

  List<BilyetSijakaItem> get bilyetList {
    if (_selectedStatus == null) return _bilyetList;
    return _bilyetList.where((item) => item.status.toLowerCase() == _selectedStatus!.toLowerCase()).toList();
  }
  
  List<SijakaProdukItem> get produkList => _produkList;
  bool get isLoading => _isLoading;
  bool get isLoadingProduk => _isLoadingProduk;
  String? get errorMessage => _errorMessage;
  String? get produkError => _produkError;
  String? get selectedStatus => _selectedStatus;
  bool get hasActiveFilter => _selectedStatus != null;

  void setStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  num get totalModalAktif {
    return _bilyetList
        .where((item) => item.isActive)
        .fold(0, (sum, item) => sum + item.nominalModal);
  }

  int get totalBilyetAktif {
    return _bilyetList.where((item) => item.isActive).length;
  }

  num get totalEstimasiBagiHasil {
    return _bilyetList
        .where((item) => item.isActive)
        .fold(0, (sum, item) => sum + (item.nominalModal * item.persenNisbahBulanan / 100));
  }

  num get totalSaldoBagiHasil {
    return _bilyetList
        .where((item) => item.isActive)
        .fold(0, (sum, item) => sum + item.saldoBagihasil);
  }

  Future<void> fetchBilyetList({bool refresh = false}) async {
    if (_bilyetList.isNotEmpty && !refresh && !_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _sijakaService.getBilyetList();
      _bilyetList = list;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat portofolio Sijaka: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BilyetSijakaDetail?> fetchBilyetDetail(int rekeningId) async {
    try {
      return await _sijakaService.getBilyetDetail(rekeningId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchProdukList({bool refresh = false}) async {
    if (_produkList.isNotEmpty && !refresh && !_isLoadingProduk) {
      return;
    }

    _isLoadingProduk = true;
    _produkError = null;
    notifyListeners();

    try {
      final list = await _sijakaService.getProdukList();
      _produkList = list;
      _isLoadingProduk = false;
      notifyListeners();
    } on ApiException catch (e) {
      _produkError = e.message;
      _isLoadingProduk = false;
      notifyListeners();
    } catch (e) {
      _produkError = 'Gagal memuat produk Sijaka: ${e.toString()}';
      _isLoadingProduk = false;
      notifyListeners();
    }
  }

  void reset() {
    _bilyetList = [];
    _produkList = [];
    _isLoading = false;
    _isLoadingProduk = false;
    _errorMessage = null;
    _produkError = null;
    _selectedStatus = null;
    notifyListeners();
  }
}

