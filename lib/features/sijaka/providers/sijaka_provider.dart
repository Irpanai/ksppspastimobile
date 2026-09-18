import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/sijaka_model.dart';
import '../services/sijaka_service.dart';

class SijakaProvider extends ChangeNotifier {
  final SijakaService _sijakaService = SijakaService();

  List<BilyetSijakaItem> _bilyetList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BilyetSijakaItem> get bilyetList => _bilyetList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  num get totalModalAktif {
    return _bilyetList
        .where((item) => item.isActive)
        .fold(0, (sum, item) => sum + item.nominalModal);
  }

  int get totalBilyetAktif {
    return _bilyetList.where((item) => item.isActive).length;
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

  void reset() {
    _bilyetList = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
