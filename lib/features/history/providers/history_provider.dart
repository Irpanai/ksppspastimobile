import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../savings/models/simpanan_riwayat_model.dart';
import '../../savings/services/savings_service.dart';

class HistoryProvider extends ChangeNotifier {
  final SavingsService _savingsService = SavingsService();

  List<MutasiSimpananItem> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;

  // Active filters
  String? _selectedTipe; // null = Semua, 'masuk' = Setoran/Masuk, 'keluar' = Penarikan/Keluar
  String? _selectedJenis; // null = Semua, 'pokok', 'wajib', 'sukarela'
  DateTime? _startDate;
  DateTime? _endDate;

  List<MutasiSimpananItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get totalItems => _totalItems;
  bool get hasMore => _currentPage < _lastPage;

  String? get selectedTipe => _selectedTipe;
  String? get selectedJenis => _selectedJenis;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get hasActiveFilter =>
      _selectedJenis != null || _startDate != null || _endDate != null;

  /// Helper getter to group mutasi by Date heading ("Hari Ini", "Kemarin", or "27 Agustus 2026")
  Map<String, List<MutasiSimpananItem>> get groupedByDate {
    final Map<String, List<MutasiSimpananItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in _items) {
      String groupKey;
      try {
        final itemDate = DateTime.parse(item.tglTransaksi).toLocal();
        final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);

        if (itemDay == today) {
          groupKey = 'Hari Ini';
        } else if (itemDay == yesterday) {
          groupKey = 'Kemarin';
        } else {
          groupKey = AppDateFormatter.formatIndoFull(item.tglTransaksi);
        }
      } catch (_) {
        groupKey = item.tglTransaksi.isNotEmpty ? item.tglTransaksi : 'Lainnya';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(item);
    }

    return groups;
  }

  void setTipe(String? tipe) {
    if (_selectedTipe == tipe) return;
    _selectedTipe = tipe;
    fetchMutasi(refresh: true);
  }

  void setJenis(String? jenis) {
    if (_selectedJenis == jenis) return;
    _selectedJenis = jenis;
    fetchMutasi(refresh: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    fetchMutasi(refresh: true);
  }

  void resetFilters() {
    _selectedJenis = null;
    _startDate = null;
    _endDate = null;
    fetchMutasi(refresh: true);
  }

  Future<void> fetchMutasi({bool refresh = false}) async {
    if (_items.isNotEmpty && !refresh && !_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      final res = await _savingsService.getRiwayatSimpanan(
        jenis: _selectedJenis,
        tipe: _selectedTipe,
        tglMulai: startStr,
        tglSelesai: endStr,
        page: 1,
      );

      _items = res.items;
      _currentPage = res.currentPage;
      _lastPage = res.lastPage;
      _totalItems = res.total;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat mutasi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      final res = await _savingsService.getRiwayatSimpanan(
        jenis: _selectedJenis,
        tipe: _selectedTipe,
        tglMulai: startStr,
        tglSelesai: endStr,
        page: nextPage,
      );

      _items = [..._items, ...res.items];
      _currentPage = res.currentPage;
      _lastPage = res.lastPage;
      _totalItems = res.total;
      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void reset() {
    _items = [];
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _lastPage = 1;
    _totalItems = 0;
    _selectedTipe = null;
    _selectedJenis = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
}
