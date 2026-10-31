import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  bool _hasShownTunggakanDialog = false;

  DashboardProvider() {
    _loadCachedDashboard();
  }

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasShownTunggakanDialog => _hasShownTunggakanDialog;

  Future<void> _loadCachedDashboard() async {
    try {
      final cached = await StorageService.getDashboardData();
      if (cached != null) {
        _dashboardData = DashboardData.fromJson(cached);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached dashboard: $e');
    }
  }

  void markTunggakanDialogShown() {
    _hasShownTunggakanDialog = true;
  }

  Future<void> fetchDashboard({bool refresh = false}) async {
    // Jika data belum ada, kita tampilkan loading
    // Jika data sudah ada dari cache, kita refresh di background (silent refresh)
    if (_dashboardData == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _dashboardService.getDashboard();
      _dashboardData = data;
      _isLoading = false;
      _errorMessage = null;
      // Simpan ke cache lokal agar pembukaan berikutnya instan (0 ms)
      await StorageService.saveDashboardData(data.toJson());
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memuat dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _dashboardData = null;
    _isLoading = false;
    _errorMessage = null;
    _hasShownTunggakanDialog = false;
    StorageService.clearDashboardData();
    notifyListeners();
  }
}
