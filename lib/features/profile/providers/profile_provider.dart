import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/member_profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  MemberProfileModel? _profileData;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  MemberProfileModel? get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 7.1 Fetch detail profile
  Future<void> fetchProfileDetail({bool refresh = false}) async {
    if (_isLoading) return;

    if (!refresh && _profileData != null) {
      // Data already loaded, can do silent refresh
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _profileService.getProfileDetail();
      _profileData = result;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat profil: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update local hasPin status
  void updateHasPin(bool hasPin) {
    if (_profileData != null) {
      _profileData = MemberProfileModel(
        user: _profileData!.user.copyWith(hasPin: hasPin),
        anggota: _profileData!.anggota,
        ringkasanSaldo: _profileData!.ringkasanSaldo,
      );
      notifyListeners();
    }
  }

  /// 7.2 Update profile
  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.updateProfile(updateData);
      _profileData = updatedProfile;
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// 7.3 Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengubah password: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// 7.4 Upload Photo
  Future<bool> uploadPhoto(File imageFile) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.uploadPhoto(imageFile);
      _profileData = updatedProfile;
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengunggah foto profil: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset on logout
  void reset() {
    _profileData = null;
    _isLoading = false;
    _isUpdating = false;
    _errorMessage = null;
    notifyListeners();
  }
}
