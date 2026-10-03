import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  bool _hasShownTunggakanDialog = false;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasShownTunggakanDialog => _hasShownTunggakanDialog;

  void markTunggakanDialogShown() {
    _hasShownTunggakanDialog = true;
  }

  Future<void> fetchDashboard({bool refresh = false}) async {
    if (_dashboardData != null && !refresh && !_isLoading) {
      // Data already loaded and not forcing refresh
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _dashboardService.getDashboard();
      _dashboardData = data;
      _isLoading = false;
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
    notifyListeners();
  }
}
