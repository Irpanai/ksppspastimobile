import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/promo_model.dart';
import '../services/promo_service.dart';

class PromoProvider extends ChangeNotifier {
  final PromoService _promoService = PromoService();

  List<PromoModel> _promos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Semua';

  List<PromoModel> get promos =>
      _promos.where((p) => p.isCurrentlyVisibleOn()).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  List<PromoModel> get filteredPromos {
    final activePromos = promos;
    if (_selectedCategory == 'Promo') {
      return activePromos.where((p) => p.isPromo).toList();
    }
    if (_selectedCategory == 'Informasi') {
      return activePromos.where((p) => p.isInfo).toList();
    }
    return activePromos;
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  Future<void> fetchPromos({bool refresh = false}) async {
    if (_isLoading) return;

    if (!refresh && _promos.isNotEmpty) {
      // Data already loaded, silent refresh
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await _promoService.getPromos();
      _promos = results.where((p) => p.isCurrentlyVisibleOn()).toList();
      _errorMessage = null;
    } on ApiException catch (e) {
      if (!e.isTimeout && e.message.trim().isNotEmpty && !e.message.toLowerCase().contains('timeout')) { _errorMessage = e.message; }
    } catch (e) {
      _errorMessage = 'Gagal memuat info & promo: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
