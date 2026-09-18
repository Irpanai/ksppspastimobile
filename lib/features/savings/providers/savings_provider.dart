import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/simpanan_riwayat_model.dart';
import '../services/savings_service.dart';

class SavingsProvider extends ChangeNotifier {
  final SavingsService _savingsService = SavingsService();

  final Map<String, List<MutasiSimpananItem>> _itemsByJenis = {};
  final Map<String, bool> _loadingByJenis = {};
  final Map<String, bool> _loadingMoreByJenis = {};
  final Map<String, String?> _errorByJenis = {};
  final Map<String, int> _pageByJenis = {};
  final Map<String, int> _lastPageByJenis = {};

  List<MutasiSimpananItem> getItems(String jenis) => _itemsByJenis[jenis.toLowerCase()] ?? [];
  bool isLoading(String jenis) => _loadingByJenis[jenis.toLowerCase()] ?? false;
  bool isLoadingMore(String jenis) => _loadingMoreByJenis[jenis.toLowerCase()] ?? false;
  String? getError(String jenis) => _errorByJenis[jenis.toLowerCase()];
  bool hasMore(String jenis) {
    final j = jenis.toLowerCase();
    final current = _pageByJenis[j] ?? 1;
    final last = _lastPageByJenis[j] ?? 1;
    return current < last;
  }

  Future<void> fetchRiwayat(String jenis, {bool refresh = false}) async {
    final key = jenis.toLowerCase();

    if (_itemsByJenis.containsKey(key) && !refresh && !(_loadingByJenis[key] ?? false)) {
      return;
    }

    _loadingByJenis[key] = true;
    _errorByJenis[key] = null;
    notifyListeners();

    try {
      final res = await _savingsService.getRiwayatSimpanan(
        jenis: key == 'all' ? null : key,
        page: 1,
      );

      _itemsByJenis[key] = res.items;
      _pageByJenis[key] = res.currentPage;
      _lastPageByJenis[key] = res.lastPage;
      _loadingByJenis[key] = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorByJenis[key] = e.message;
      _loadingByJenis[key] = false;
      notifyListeners();
    } catch (e) {
      _errorByJenis[key] = 'Gagal memuat riwayat: ${e.toString()}';
      _loadingByJenis[key] = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(String jenis) async {
    final key = jenis.toLowerCase();
    if (_loadingMoreByJenis[key] == true || !hasMore(key)) return;

    _loadingMoreByJenis[key] = true;
    notifyListeners();

    try {
      final nextPage = (_pageByJenis[key] ?? 1) + 1;
      final res = await _savingsService.getRiwayatSimpanan(
        jenis: key == 'all' ? null : key,
        page: nextPage,
      );

      final currentList = _itemsByJenis[key] ?? [];
      _itemsByJenis[key] = [...currentList, ...res.items];
      _pageByJenis[key] = res.currentPage;
      _lastPageByJenis[key] = res.lastPage;
      _loadingMoreByJenis[key] = false;
      notifyListeners();
    } catch (_) {
      _loadingMoreByJenis[key] = false;
      notifyListeners();
    }
  }

  void reset() {
    _itemsByJenis.clear();
    _loadingByJenis.clear();
    _loadingMoreByJenis.clear();
    _errorByJenis.clear();
    _pageByJenis.clear();
    _lastPageByJenis.clear();
    notifyListeners();
  }
}
