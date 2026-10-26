import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/premium_header.dart';
import '../../../core/utils/ktp_ocr_helper.dart';
import 'kyc_camera_screen.dart';
import '../../main_nav/screens/main_nav_screen.dart';
import '../models/cabang_model.dart';
import '../providers/auth_provider.dart';
import '../services/cabang_service.dart';
import '../widgets/cabang_map_modal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  // State Pemilihan Cabang (Provinsi -> Cabang)
  String? _selectedProvinceCabang;
  CabangModel? _selectedCabangModel;
  List<String> _provinces = [];
  List<CabangModel> _cabangsInProvince = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingCabangs = false;

  // Fitur Deteksi Lokasi Cabang Terdekat (GPS)
  bool _isDetectingLocation = false;
  String? _nearestCabangDetectedMessage;
  double? _userLatitude;
  double? _userLongitude;

  bool _isObscure1 = true;
  bool _isObscure2 = true;

  File? _fotoKtp;
  File? _fotoWajah;
  Uint8List? _fotoKtpBytes;
  Uint8List? _fotoWajahBytes;
  bool _isOcrLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Memuat daftar provinsi cabang dari API
  Future<void> _loadProvinces() async {
    if (!mounted) return;
    setState(() => _isLoadingProvinces = true);
    try {
      final list = await CabangService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingProvinces = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  /// Memuat daftar cabang berdasarkan provinsi yang dipilih
  Future<void> _loadCabangsByProvince(String province) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCabangs = true;
      _cabangsInProvince = [];
      _selectedCabangModel = null;
    });

    try {
      final list = await CabangService.getCabangsByProvince(province);
      if (mounted) {
        setState(() {
          _cabangsInProvince = list;
          _isLoadingCabangs = false;
          if (list.length == 1) {
            _selectedCabangModel = list.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCabangs = false);
    }
  }

  /// Mendeteksi cabang terdekat dari posisi koordinat GPS pengguna
  Future<void> _detectNearestCabang() async {
    setState(() {
      _isDetectingLocation = true;
      _nearestCabangDetectedMessage = null;
    });

    try {
      // 1. Cek ketersediaan layanan GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showWarning('Layanan lokasi/GPS perangkat nonaktif. Silakan aktifkan GPS Anda.');
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

      // 2. Periksa & minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showWarning('Izin akses lokasi ditolak oleh pengguna.');
          if (mounted) setState(() => _isDetectingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showWarning('Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi di Pengaturan.');
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

      // 3. Ambil posisi GPS pengguna
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      // 4. Hitung & urutkan cabang terdekat
      final sortedCabangs = await CabangService.getCabangsSortedByDistance(
        position.latitude,
        position.longitude,
      );

      if (sortedCabangs.isNotEmpty) {
        final nearest = sortedCabangs.first;
        final prov = nearest.province ?? '';

        setState(() {
          _selectedProvinceCabang = prov;
          _selectedCabangModel = nearest;
          _nearestCabangDetectedMessage =
              '${nearest.name} (${nearest.formattedDistance ?? 'terdekat'})';
        });

        // Sinkronisasi cabang dalam provinsi yang terpilih
        if (prov.isNotEmpty) {
          await _loadCabangsByProvince(prov);
          if (mounted) {
            setState(() {
              _selectedCabangModel = nearest;
            });
          }
        }

        _showSuccess(
          'Cabang terdekat ditemukan: ${nearest.name} (${nearest.formattedDistance ?? 'lokasi terdekat'})',
        );
      } else {
        _showWarning('Tidak dapat menemukan data cabang untuk dihitung jaraknya.');
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Error detecting location: $e');
      _showWarning('Gagal mendeteksi lokasi saat ini. Pastikan GPS aktif dan terhubung ke internet.');
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  /// Membuka lokasi titik koordinat cabang di aplikasi Google Maps
  Future<void> _openBranchLocationInMaps(CabangModel cabang) async {
    Uri url;
    if (cabang.latitude != null && cabang.longitude != null) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${cabang.latitude},${cabang.longitude}',
      );
    } else {
      final query = Uri.encodeComponent('${cabang.name} ${cabang.city ?? ''} ${cabang.address ?? ''}');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Error opening maps: $e');
      _showWarning('Tidak dapat membuka peta Google Maps.');
    }
  }

  /// Membuka Modal Peta Interaktif Seluruh Cabang (OpenStreetMap / Citra Satelit)
  Future<void> _openMapModal() async {
    final allCabangs = await CabangService.getAllCabangs();
    final cabangsToDisplay = allCabangs.isNotEmpty ? allCabangs : _cabangsInProvince;

    if (!mounted) return;

    CabangMapModal.show(
      context: context,
      allCabangs: cabangsToDisplay,
      initialSelectedCabang: _selectedCabangModel,
      initialProvince: _selectedProvinceCabang,
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
      onSelectCabang: (cabang) {
        setState(() {
          _selectedProvinceCabang = cabang.province ?? _selectedProvinceCabang;
          _selectedCabangModel = cabang;
        });
        if (cabang.province != null) {
          _loadCabangsByProvince(cabang.province!);
        }
      },
    );
  }

  Future<void> _pickKtp() async {
    try {
      final File? file = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => const KycCameraScreen(mode: KycCameraMode.ktp),
        ),
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _fotoKtp = file;
          _fotoKtpBytes = bytes;
        });
        _scanOcr(XFile(file.path));
      }
    } catch (e) {
      _showWarning('Gagal membuka kamera KTP. Pastikan izin kamera telah diberikan.');
    }
  }

  Future<void> _scanOcr(XFile pickedFile) async {
    if (kIsWeb) {
      _showSuccess('Foto KTP berhasil disimpan.');
      return;
    }

    setState(() => _isOcrLoading = true);

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final ocrResult = KtpOcrHelper.parse(recognizedText);

      final String? nik = ocrResult.nik;
      final String? nama = ocrResult.nama;

      if (nik != null && nik.isNotEmpty) {
        _nikController.text = nik;
      }
      if (nama != null && nama.isNotEmpty) {
        _nameController.text = nama;
      }

      if (nik != null && nama != null) {
        _showSuccess('KTP berhasil dipindai! NIK dan Nama terisi otomatis.');
      } else if (nik != null) {
        _showSuccess('NIK ($nik) berhasil terbaca. Silakan lengkapi Nama Anda.');
      } else if (nama != null) {
        _showSuccess('Nama ($nama) berhasil terbaca. Silakan lengkapi NIK Anda.');
      } else {
        _showWarning('Foto KTP tersimpan. AI belum dapat mendeteksi NIK/Nama dengan jelas, mohon isi manual.');
      }

      textRecognizer.close();
    } catch (e) {
      _showWarning('Foto KTP tersimpan. Silakan isi data secara manual.');
    } finally {
      if (mounted) setState(() => _isOcrLoading = false);
    }
  }

  Future<void> _pickWajah() async {
    try {
      final File? file = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => const KycCameraScreen(mode: KycCameraMode.selfie),
        ),
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _fotoWajah = file;
          _fotoWajahBytes = bytes;
        });
        _showSuccess('Foto selfie wajah berhasil diambil.');
      }
    } catch (e) {
      _showWarning('Gagal membuka kamera depan. Pastikan izin kamera telah diberikan.');
    }
  }

    Future<void> _submitRegister() async {
    final name = _nameController.text.trim();
    final nik = _nikController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showWarning('Silakan masukkan nama lengkap sesuai KTP.');
      return;
    }

    if (nik.isEmpty || nik.length != 16) {
      _showWarning('Nomor Induk Kependudukan (NIK) harus 16 digit angka.');
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showWarning('Silakan masukkan nomor handphone yang valid (min. 10 digit).');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showWarning('Silakan masukkan format alamat email yang valid.');
      return;
    }

    if (password.length < 6) {
      _showWarning('Password minimal harus 6 karakter.');
      return;
    }

    if (password != confirmPassword) {
      _showWarning('Konfirmasi password tidak cocok.');
      return;
    }

    if (_selectedProvinceCabang == null || _selectedProvinceCabang!.isEmpty) {
      _showWarning('Silakan pilih provinsi kantor cabang terlebih dahulu.');
      return;
    }

    if (_selectedCabangModel == null) {
      _showWarning('Silakan pilih kantor cabang pendaftaran.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: confirmPassword,
      nik: nik,
      noHp: phone,
      alamat: address.isNotEmpty ? address : null,
      cabangId: _selectedCabangModel!.id,
      cabang: _selectedCabangModel!.name,
      fotoWajah: _fotoWajah,
      fotoKtp: _fotoKtp,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Pendaftaran berhasil! Selamat datang di KSPPS PASTI.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      _showError(authProvider.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFF0E7955),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Modal Bottom Sheet Search Dropdown untuk Memilih Provinsi
  void _openProvinceSearchModal() {
    if (_provinces.isEmpty && _isLoadingProvinces) {
      _showWarning('Sedang memuat data provinsi, mohon tunggu sebentar...');
      return;
    }

    final searchController = TextEditingController();
    List<String> filteredList = List.from(_provinces);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.map_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Provinsi Cabang',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Pilih provinsi kantor cabang KSPPS PASTI',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: false,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Cari provinsi (misal: Kalimantan, Jawa)...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() {
                                        filteredList = List.from(_provinces);
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (query) {
                            setModalState(() {
                              if (query.trim().isEmpty) {
                                filteredList = List.from(_provinces);
                              } else {
                                final q = query.trim().toLowerCase();
                                filteredList = _provinces
                                    .where((p) => p.toLowerCase().contains(q))
                                    .toList();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text(
                            'Menampilkan ${filteredList.length} provinsi',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Provinsi tidak ditemukan',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Coba kata kunci pencarian yang lain.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final prov = filteredList[index];
                                final isSelected = prov == _selectedProvinceCabang;

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    if (_selectedProvinceCabang != prov) {
                                      setState(() {
                                        _selectedProvinceCabang = prov;
                                        _selectedCabangModel = null;
                                      });
                                      _loadCabangsByProvince(prov);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 18,
                                          color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            prov,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 18)
                                        else
                                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Modal Bottom Sheet Search Dropdown untuk Memilih Cabang di Provinsi Terpilih
  void _openCabangSearchModal() {
    if (_selectedProvinceCabang == null) {
      _showWarning('Silakan pilih provinsi terlebih dahulu.');
      return;
    }

    if (_isLoadingCabangs) {
      _showWarning('Sedang memuat data cabang, mohon tunggu sebentar...');
      return;
    }

    // Hitung jarak cabang jika koordinat user tersedia
    List<CabangModel> initialList = _cabangsInProvince.map((c) {
      if (_userLatitude != null && _userLongitude != null && c.latitude != null && c.longitude != null) {
        final d = CabangService.calculateDistanceKm(_userLatitude!, _userLongitude!, c.latitude!, c.longitude!);
        return c.copyWith(distanceInKm: d);
      }
      return c;
    }).toList();

    // Jika ada koordinat user, urutkan cabang terdekat di atas
    if (_userLatitude != null && _userLongitude != null) {
      initialList.sort((a, b) {
        if (a.distanceInKm == null && b.distanceInKm == null) return 0;
        if (a.distanceInKm == null) return 1;
        if (b.distanceInKm == null) return -1;
        return a.distanceInKm!.compareTo(b.distanceInKm!);
      });
    }

    final searchController = TextEditingController();
    List<CabangModel> filteredList = List.from(initialList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.account_balance_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Kantor Cabang',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Wilayah: $_selectedProvinceCabang',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: false,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Cari nama cabang, kode, kota, atau alamat...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() {
                                        filteredList = List.from(initialList);
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (query) {
                            setModalState(() {
                              if (query.trim().isEmpty) {
                                filteredList = List.from(initialList);
                              } else {
                                final q = query.trim().toLowerCase();
                                filteredList = initialList.where((c) {
                                  final nameMatch = c.name.toLowerCase().contains(q);
                                  final codeMatch = c.code.toLowerCase().contains(q);
                                  final cityMatch = (c.city ?? '').toLowerCase().contains(q);
                                  final addrMatch = (c.address ?? '').toLowerCase().contains(q);
                                  return nameMatch || codeMatch || cityMatch || addrMatch;
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tersedia ${filteredList.length} kantor cabang',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _openMapModal();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.map_rounded, size: 12, color: Color(0xFF1D4ED8)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Buka Peta',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (_userLatitude != null && _userLongitude != null)
                                const Row(
                                  children: [
                                    Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF166534)),
                                    SizedBox(width: 3),
                                    Text(
                                      'GPS Aktif',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ],
                                )
                              else
                                InkWell(
                                  onTap: () async {
                                    Navigator.pop(sheetContext);
                                    await _detectNearestCabang();
                                    _openCabangSearchModal();
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.my_location_rounded, size: 12, color: Color(0xFF166534)),
                                        SizedBox(width: 4),
                                        Text(
                                          'GPS',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List View Cabang
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Kantor cabang tidak ditemukan',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tidak ada cabang yang cocok dengan pencarian Anda.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final cabang = filteredList[index];
                                final isSelected = _selectedCabangModel?.id == cabang.id;
                                final isNearest = initialList.isNotEmpty &&
                                    initialList.first.id == cabang.id &&
                                    cabang.distanceInKm != null;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCabangModel = cabang;
                                    });
                                    Navigator.pop(sheetContext);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFFF1F5F9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.storefront_rounded,
                                            size: 16,
                                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    cabang.name,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  if (isNearest)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        borderRadius: BorderRadius.circular(5),
                                                        border: Border.all(color: const Color(0xFFFCD34D)),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.star_rounded, size: 10, color: Color(0xFFB45309)),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            'TERDEKAT',
                                                            style: TextStyle(
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w900,
                                                              color: Color(0xFFB45309),
                                                              letterSpacing: 0.3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (cabang.formattedDistance != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFDCFCE7),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '📍 ${cabang.formattedDistance}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF166534),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      cabang.code,
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                                    ),
                                                  ),
                                                  if (cabang.city != null && cabang.city!.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      cabang.city!,
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (cabang.address != null && cabang.address!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  cabang.address!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.map_outlined, color: Color(0xFF059669), size: 19),
                                          tooltip: 'Lihat di Peta',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () => _openBranchLocationInMaps(cabang),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isSelected)
                                          Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 20)
                                        else
                                          const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1), size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Daftar Anggota Baru',
            showBackButton: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Value Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            const Color(0xFFF0FDF4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Bergabunglah bersama KSPPS PASTI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lengkapi data diri Anda di bawah ini untuk membuka rekening simpanan syariah secara instan, aman, dan transparan.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    // Section 1: Verifikasi Identitas (KYC)
                    _buildSectionHeader('Dokumen Identitas (KYC)', Icons.verified_user_outlined),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildInfoAlert(
                        'Unggah foto selfie wajah dan scan e-KTP. AI OCR akan otomatis membaca NIK dan Nama Anda.',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoUploadCard(
                              title: 'Foto Wajah',
                              subtitle: 'Ambil Selfie',
                              file: _fotoWajah,
                              bytes: _fotoWajahBytes,
                              onTap: _pickWajah,
                              icon: Icons.face_retouching_natural_rounded,
                              isLoading: false,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildPhotoUploadCard(
                              title: 'Scan e-KTP',
                              subtitle: 'Pindai KTP',
                              file: _fotoKtp,
                              bytes: _fotoKtpBytes,
                              onTap: _pickKtp,
                              icon: Icons.credit_card_rounded,
                              isLoading: _isOcrLoading,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Section 2: Data Pribadi & Akun
                    _buildSectionHeader('Data Pribadi & Keamanan Akun', Icons.security_rounded),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField(
                        label: 'Nama Lengkap (Sesuai KTP) *',
                        controller: _nameController,
                        hint: 'Contoh: Budi Santoso',
                        icon: Icons.person_outline_rounded,
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        label: 'Nomor Induk Kependudukan (NIK 16 Digit) *',
                        controller: _nikController,
                        hint: '3301xxxxxxxxxxxx',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                        ],
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        label: 'Nomor Handphone / WhatsApp *',
                        controller: _phoneController,
                        hint: '081234567890',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                        ],
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        label: 'Alamat Email Aktif *',
                        controller: _emailController,
                        hint: 'nasabah@domain.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        label: 'Password Akun *',
                        controller: _passwordController,
                        hint: 'Min. 6 karakter',
                        icon: Icons.lock_outline_rounded,
                        isObscure: _isObscure1,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildTextField(
                        label: 'Konfirmasi Password *',
                        controller: _confirmPasswordController,
                        hint: 'Ulangi password',
                        icon: Icons.lock_outline_rounded,
                        isObscure: _isObscure2,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Section 3: Domisili & Pilihan Kantor Cabang
                    _buildSectionHeader('Domisili & Kantor Cabang KSPPS', Icons.location_city_rounded),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField(
                        label: 'Alamat Domisili (Opsional)',
                        controller: _addressController,
                        hint: 'Jl. Pemuda No. 10, Semarang',
                        icon: Icons.location_on_outlined,
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Fitur Deteksi Cabang Terdekat via GPS
                      _buildGpsDetectCard(),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Dropdown Provinsi Cabang
                      _buildDropdownSelector(
                        label: 'Provinsi Kantor Cabang *',
                        value: _selectedProvinceCabang ?? 'Pilih Provinsi Kantor Cabang',
                        hasValue: _selectedProvinceCabang != null,
                        icon: Icons.map_outlined,
                        isLoading: _isLoadingProvinces,
                        enabled: !isLoading,
                        onTap: _openProvinceSearchModal,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Dropdown Kantor Cabang
                      _buildDropdownSelector(
                        label: 'Kantor Cabang Terdaftar *',
                        value: _selectedCabangModel != null
                            ? _selectedCabangModel!.name
                            : (_selectedProvinceCabang == null
                                ? 'Pilih provinsi terlebih dahulu'
                                : (_isLoadingCabangs
                                    ? 'Memuat daftar cabang...'
                                    : 'Pilih Kantor Cabang (${_cabangsInProvince.length} cabang)')),
                        subtitle: _selectedCabangModel != null
                            ? '${_selectedCabangModel!.code} • ${_selectedCabangModel!.displayLocation}'
                            : null,
                        distanceBadge: _selectedCabangModel?.formattedDistance,
                        hasValue: _selectedCabangModel != null,
                        icon: Icons.account_balance_outlined,
                        isLoading: _isLoadingCabangs,
                        enabled: !isLoading && _selectedProvinceCabang != null && !_isLoadingCabangs,
                        isLocked: _selectedProvinceCabang == null,
                        onTap: _openCabangSearchModal,
                      ),
                      if (_selectedCabangModel != null)
                        _buildSelectedCabangCard(_selectedCabangModel!),
                    ]),
                    const SizedBox(height: 32),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Link Masuk
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Sudah punya akun? ',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Masuk di sini',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildInfoAlert(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool isObscure = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isObscure,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          inputFormatters: [
            ...?inputFormatters,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength, maxLengthEnforcement: MaxLengthEnforcement.enforced),
          ],
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSelector({
    required String label,
    required String value,
    String? subtitle,
    String? distanceBadge,
    required bool hasValue,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool enabled = true,
    bool isLocked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasValue
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasValue
                      ? Theme.of(context).colorScheme.primary
                      : (isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8)),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasValue ? FontWeight.bold : FontWeight.w500,
                                color: hasValue
                                    ? const Color(0xFF1E293B)
                                    : (isLocked ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distanceBadge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📍 $distanceBadge',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  )
                else if (isLocked)
                  const Icon(Icons.lock_outline_rounded, color: Color(0xFFCBD5E1), size: 18)
                else if (hasValue)
                  Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 18)
                else
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsDetectCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF0FDF4),
            const Color(0xFFECFDF5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari Cabang Terdekat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nearestCabangDetectedMessage != null
                      ? 'Terpilih: $_nearestCabangDetectedMessage'
                      : 'Aktifkan GPS untuk memilih cabang paling dekat dengan Anda secara otomatis.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _nearestCabangDetectedMessage != null
                        ? const Color(0xFF047857)
                        : const Color(0xFF065F46).withValues(alpha: 0.8),
                    fontWeight: _nearestCabangDetectedMessage != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _openMapModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF047857),
              side: const BorderSide(color: Color(0xFF86EFAC)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, size: 14),
                SizedBox(width: 3),
                Text('Peta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _isDetectingLocation ? null : _detectNearestCabang,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isDetectingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Deteksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required Uint8List? bytes,
    required VoidCallback onTap,
    required IconData icon,
    required bool isLoading,
  }) {
    final hasImage = bytes != null || file != null;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasImage ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? Theme.of(context).colorScheme.primary : const Color(0xFFE2E8F0),
            width: hasImage ? 2 : 1,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasImage && bytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        bytes,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasImage ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        hasImage ? Icons.check_circle_rounded : icon,
                        color: hasImage ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
                        size: 26,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: hasImage ? Theme.of(context).colorScheme.primary : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasImage ? 'Ketuk untuk ubah' : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: hasImage ? Theme.of(context).colorScheme.primary : const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  /// Kartu Pratinjau Cabang Terdaftar & Navigasi Peta Google Maps
  Widget _buildSelectedCabangCard(CabangModel cabang) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'CABANG PENDAFTARAN ANDA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (cabang.formattedDistance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, color: Color(0xFF166534), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '📍 ${cabang.formattedDistance}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Nama Cabang & Kode
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cabang.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kode: ${cabang.code} • ${cabang.displayLocation}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (cabang.address != null && cabang.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cabang.address!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                  ),
                ),
              ],
            ),
          ],

          if (cabang.phone != null && cabang.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text(
                  cabang.phone!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          // Mini Map Visual Interaktif
          if (cabang.latitude != null && cabang.longitude != null) ...[
            const SizedBox(height: 10),
            CabangMiniMap(
              cabang: cabang,
              userLatitude: _userLatitude,
              userLongitude: _userLongitude,
              onExpand: _openMapModal,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFBBF7D0)),
          const SizedBox(height: 10),

          // Keterangan status pendaftaran
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF059669)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rekening simpanan & buku anggota Anda nantinya akan diterbitkan serta dikelola oleh kantor cabang ini.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Aksi: Buka Peta Interaktif & Rute Google Maps
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMapModal,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text(
                    'Peta Interaktif',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openBranchLocationInMaps(cabang),
                  icon: const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF047857)),
                  label: const Text(
                    'Rute Maps',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF86EFAC), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

