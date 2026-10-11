import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/member_profile_model.dart';
import '../models/pengunduran_diri_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  MemberProfileModel? _profileData;
  PengunduranDiriStatusModel? _pengunduranStatus;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isPengunduranLoading = false;
  bool _isSubmittingPengunduran = false;
  String? _errorMessage;

  MemberProfileModel? get profileData => _profileData;
  PengunduranDiriStatusModel? get pengunduranStatus => _pengunduranStatus;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isPengunduranLoading => _isPengunduranLoading;
  bool get isSubmittingPengunduran => _isSubmittingPengunduran;
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

  /// Reset password via PIN
  Future<bool> resetPasswordWithPin({
    required String pin,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.resetPasswordWithPin(
        pin: pin,
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
      _errorMessage = 'Gagal mereset password: ${e.toString()}';
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

  /// Fetch Status Pengunduran Diri
  Future<void> fetchPengunduranStatus() async {
    _isPengunduranLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _profileService.getPengunduranDiriStatus();
      _pengunduranStatus = result;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat status pengunduran diri: ${e.toString()}';
    } finally {
      _isPengunduranLoading = false;
      notifyListeners();
    }
  }

  /// Ajukan Pengunduran Diri
  Future<bool> ajukanPengunduranDiri(String konfirmasiTeks) async {
    _isSubmittingPengunduran = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.ajukanPengunduranDiri(konfirmasiTeks);
      _isSubmittingPengunduran = false;
      // Refresh status setelah berhasil mengajukan
      await fetchPengunduranStatus();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmittingPengunduran = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengajukan pengunduran diri: ${e.toString()}';
      _isSubmittingPengunduran = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset on logout
  void reset() {
    _profileData = null;
    _pengunduranStatus = null;
    _isLoading = false;
    _isUpdating = false;
    _isPengunduranLoading = false;
    _isSubmittingPengunduran = false;
    _errorMessage = null;
    notifyListeners();
  }
}
