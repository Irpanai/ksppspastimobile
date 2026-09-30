import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Filters per jenis
  final Map<String, String?> _tipeByJenis = {};
  final Map<String, DateTime?> _startDateByJenis = {};
  final Map<String, DateTime?> _endDateByJenis = {};

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

  String? getTipe(String jenis) => _tipeByJenis[jenis.toLowerCase()];
  DateTime? getStartDate(String jenis) => _startDateByJenis[jenis.toLowerCase()];
  DateTime? getEndDate(String jenis) => _endDateByJenis[jenis.toLowerCase()];

  bool hasActiveFilter(String jenis) {
    final key = jenis.toLowerCase();
    return _tipeByJenis[key] != null || _startDateByJenis[key] != null || _endDateByJenis[key] != null;
  }

  void setFilter(String jenis, {String? tipe, DateTime? start, DateTime? end}) {
    final key = jenis.toLowerCase();
    _tipeByJenis[key] = tipe;
    _startDateByJenis[key] = start;
    _endDateByJenis[key] = end;
    fetchRiwayat(key, refresh: true);
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
      final start = _startDateByJenis[key];
      final end = _endDateByJenis[key];
      final tipe = _tipeByJenis[key];
      final startStr = start != null ? DateFormat('yyyy-MM-dd').format(start) : null;
      final endStr = end != null ? DateFormat('yyyy-MM-dd').format(end) : null;

      final res = await _savingsService.getRiwayatSimpanan(
        jenis: key == 'all' ? null : key,
        tipe: tipe,
        tglMulai: startStr,
        tglSelesai: endStr,
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
      final start = _startDateByJenis[key];
      final end = _endDateByJenis[key];
      final tipe = _tipeByJenis[key];
      final startStr = start != null ? DateFormat('yyyy-MM-dd').format(start) : null;
      final endStr = end != null ? DateFormat('yyyy-MM-dd').format(end) : null;

      final res = await _savingsService.getRiwayatSimpanan(
        jenis: key == 'all' ? null : key,
        tipe: tipe,
        tglMulai: startStr,
        tglSelesai: endStr,
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
    _tipeByJenis.clear();
    _startDateByJenis.clear();
    _endDateByJenis.clear();
    notifyListeners();
  }
}
