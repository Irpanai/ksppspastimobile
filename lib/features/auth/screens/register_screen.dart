import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_address_service.dart';
import '../../../core/utils/ktp_ocr_helper.dart';
import 'kyc_camera_screen.dart';
import 'login_screen.dart';
import '../../main_nav/screens/main_nav_screen.dart';
import '../models/cabang_model.dart';
import '../providers/auth_provider.dart';
import '../services/cabang_service.dart';
import '../widgets/cabang_map_modal.dart';
import '../../profile/screens/terms_conditions_screen.dart';
import '../../profile/screens/data_consent_screen.dart';
import '../../../shared/widgets/app_dialog.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onSwitchToLogin;
  final bool isEmbedded;

  const RegisterScreen({
    super.key,
    this.onSwitchToLogin,
    this.isEmbedded = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  String _selectedGender = 'Laki-laki';
  String? _selectedReligion = 'Islam';
  final _jobController = TextEditingController(text: 'Wiraswasta / Pengusaha');

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  static const List<String> _religionOptions = [
    'Islam',
    'Kristen Protestan',
    'Kristen Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
  ];

  static const List<String> _jobOptions = [
    'Pegawai Swasta',
    'Wiraswasta / Pengusaha',
    'Pegawai Negeri Sipil (PNS) / ASN',
    'TNI / Polri',
    'Pedagang',
    'Petani / Peternak / Nelayan',
    'Karyawan BUMN / BUMD',
    'Profesional / Tenaga Medis',
    'Guru / Dosen',
    'Buruh Harian / Pekerja Lepas',
    'Pelajar / Mahasiswa',
    'Ibu Rumah Tangga',
    'Lainnya',
  ];

  // State Pemilihan Cabang (Provinsi -> Cabang)
  String? _selectedProvinceCabang;
  CabangModel? _selectedCabangModel;
  List<String> _provinces = [];
  List<CabangModel> _cabangsInProvince = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingCabangs = false;

  // Fitur Deteksi Lokasi Cabang Terdekat & Alamat Domisili (GPS)
  bool _isDetectingLocation = false;
  bool _isDetectingAddress = false;
  String? _nearestCabangDetectedMessage;
  double? _userLatitude;
  double? _userLongitude;

  // Data Wilayah Tambahan (terisi otomatis dari OCR e-KTP atau GPS)
  String? _alamatProvinsi;
  String? _alamatKabupatenKota;
  String? _alamatKecamatan;
  String? _alamatKelurahan;
  String? _detectedAddressSource;

  bool _isObscure1 = true;
  bool _isObscure2 = true;

  File? _fotoKtp;
  File? _fotoWajah;
  Uint8List? _fotoKtpBytes;
  Uint8List? _fotoWajahBytes;
  bool _isOcrLoading = false;
  bool _isConsentChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo-kspps-pasti.png'), context);
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _nikController.addListener(_onNikChanged);
  }

  @override
  void dispose() {
    _nikController.removeListener(_onNikChanged);
    _nameController.dispose();
    _nikController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _jobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNikChanged() {
    final nik = _nikController.text.trim();
    if (nik.length == 16) {
      final nikData = KtpOcrHelper.parseNikData(nik);
      if (nikData != null) {
        if (_selectedBirthDate == null && nikData['dateTime'] is DateTime) {
          final dt = nikData['dateTime'] as DateTime;
          setState(() {
            _selectedBirthDate = dt;
            _birthDateController.text = _formatIndonesianDate(dt);
          });
        }
        if (nikData['jenis_kelamin'] is String && (_selectedGender.isEmpty || _selectedGender == 'Laki-laki')) {
          setState(() {
            _selectedGender = nikData['jenis_kelamin'] as String;
          });
        }
      }
    }
  }

  String _formatIndonesianDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatBackendDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    // Syarat umum anggota: minimal 17 tahun (memiliki KTP)
    final maxDate = DateTime(now.year - 17, now.month, now.day);
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(maxDate) ? maxDate : initialDate,
      firstDate: DateTime(1930),
      lastDate: maxDate,
      helpText: 'PILIH TANGGAL LAHIR',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatIndonesianDate(picked);
      });
    }
  }

  void _openReligionSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Agama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_religionOptions.length, (index) {
                  final rel = _religionOptions[index];
                  final isSelected = _selectedReligion == rel;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedReligion = rel);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            rel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openJobSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (sheetCtx, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Pekerjaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih sesuai profesi atau pekerjaan Anda saat ini',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _jobOptions.length,
                        itemBuilder: (itemCtx, index) {
                          final job = _jobOptions[index];
                          final isSelected = _jobController.text.trim() == job;
                          return InkWell(
                            onTap: () {
                              if (job == 'Lainnya') {
                                Navigator.pop(ctx);
                                _promptCustomJob();
                              } else {
                                setState(() {
                                  _jobController.text = job;
                                });
                                Navigator.pop(ctx);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.work_outline_rounded,
                                    color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      job,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (job == 'Lainnya')
                                    const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
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

  void _promptCustomJob() {
    final customCtrl = TextEditingController(text: _jobController.text == 'Lainnya' ? '' : _jobController.text);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ketik Pekerjaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: customCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Contoh: Desainer Grafis, Barista, dsb',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (customCtrl.text.trim().isNotEmpty) {
                setState(() => _jobController.text = customCtrl.text.trim());
              }
              Navigator.pop(dCtx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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

  /// Mengambil koordinat GPS terkini dengan pemeriksaan layanan & izin lokasi.
  Future<Position?> _acquireCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showWarning('Layanan lokasi/GPS perangkat nonaktif. Silakan aktifkan GPS Anda.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showWarning('Izin akses lokasi ditolak oleh pengguna.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showWarning('Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi di Pengaturan.');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    _userLatitude = position.latitude;
    _userLongitude = position.longitude;
    return position;
  }

  /// Mengisi field alamat & sub-wilayah dari koordinat GPS via reverse geocoding.
  Future<bool> _applyAddressFromCoordinates(
    double latitude,
    double longitude, {
    bool forceOverwrite = true,
  }) async {
    final detected = await LocationAddressService.reverseGeocode(latitude, longitude);
    if (!mounted || detected == null || !detected.hasAny) {
      return false;
    }

    if (!forceOverwrite && _addressController.text.trim().isNotEmpty) {
      return false;
    }

    setState(() {
      if (detected.formattedAddress.isNotEmpty) {
        _addressController.text = detected.formattedAddress;
      }
      if (detected.provinsi != null && detected.provinsi!.isNotEmpty) {
        _alamatProvinsi = detected.provinsi;
      }
      if (detected.kabupatenKota != null && detected.kabupatenKota!.isNotEmpty) {
        _alamatKabupatenKota = detected.kabupatenKota;
      }
      if (detected.kecamatan != null && detected.kecamatan!.isNotEmpty) {
        _alamatKecamatan = detected.kecamatan;
      }
      if (detected.kelurahan != null && detected.kelurahan!.isNotEmpty) {
        _alamatKelurahan = detected.kelurahan;
      }
      _detectedAddressSource = 'GPS Lokasi Sekarang';
    });

    return true;
  }

  /// Mendeteksi alamat domisili berdasarkan lokasi GPS saat ini.
  Future<void> _detectAddressFromCurrentLocation() async {
    setState(() => _isDetectingAddress = true);

    try {
      final position = await _acquireCurrentPosition();
      if (position == null) return;

      final updated = await _applyAddressFromCoordinates(
        position.latitude,
        position.longitude,
        forceOverwrite: true,
      );

      if (updated) {
        _showSuccess('Alamat domisili berhasil dideteksi dari lokasi GPS Anda.');
      } else {
        _showWarning('Koordinat GPS didapat, namun nama jalan/wilayah tidak ditemukan. Silakan lengkapi alamat secara manual.');
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Error reverse geocoding address: $e');
      _showWarning('Gagal mendeteksi alamat dari GPS. Pastikan GPS aktif dan terhubung ke internet.');
    } finally {
      if (mounted) {
        setState(() => _isDetectingAddress = false);
      }
    }
  }

  /// Mendeteksi cabang terdekat dari posisi koordinat GPS pengguna
  Future<void> _detectNearestCabang() async {
    setState(() {
      _isDetectingLocation = true;
      _nearestCabangDetectedMessage = null;
    });

    try {
      final position = await _acquireCurrentPosition();
      if (position == null) return;

      // Hitung & urutkan cabang terdekat + isi alamat jika masih kosong
      final sortedFuture = CabangService.getCabangsSortedByDistance(
        position.latitude,
        position.longitude,
      );
      final addressFuture = _addressController.text.trim().isEmpty
          ? _applyAddressFromCoordinates(
              position.latitude,
              position.longitude,
              forceOverwrite: false,
            )
          : Future.value(false);

      final sortedCabangs = await sortedFuture;
      await addressFuture;

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
      final String? alamat = ocrResult.alamat;
      final addrDetail = ocrResult.addressDetail;

      if (nik != null && nik.isNotEmpty) {
        _nikController.text = nik;
      }
      if (nama != null && nama.isNotEmpty) {
        _nameController.text = nama;
      }
      if (ocrResult.tempatLahir != null && ocrResult.tempatLahir!.isNotEmpty) {
        _birthPlaceController.text = ocrResult.tempatLahir!;
      }
      if (ocrResult.tanggalLahir != null) {
        _selectedBirthDate = ocrResult.tanggalLahir;
        _birthDateController.text = _formatIndonesianDate(ocrResult.tanggalLahir!);
      }
      if (ocrResult.jenisKelamin != null && ocrResult.jenisKelamin!.isNotEmpty) {
        _selectedGender = ocrResult.jenisKelamin!;
      }
      if (ocrResult.agama != null && ocrResult.agama!.isNotEmpty) {
        _selectedReligion = ocrResult.agama;
      }
      if (ocrResult.pekerjaan != null && ocrResult.pekerjaan!.isNotEmpty) {
        _jobController.text = ocrResult.pekerjaan!;
      }
      if (alamat != null && alamat.isNotEmpty) {
        final streetParts = <String>[
          if (addrDetail?.alamat != null && addrDetail!.alamat!.isNotEmpty)
            addrDetail.alamat!,
          if (addrDetail?.rtRw != null &&
              addrDetail!.rtRw!.isNotEmpty &&
              !(addrDetail.alamat ?? '').toUpperCase().contains('RT'))
            'RT/RW ${addrDetail.rtRw!}',
        ];
        _addressController.text = streetParts.isNotEmpty
            ? streetParts.join(', ')
            : alamat;

        if (mounted) {
          setState(() {
            if (addrDetail?.provinsi != null && addrDetail!.provinsi!.isNotEmpty) {
              _alamatProvinsi = addrDetail.provinsi;
            }
            if (addrDetail?.kabupatenKota != null &&
                addrDetail!.kabupatenKota!.isNotEmpty) {
              _alamatKabupatenKota = addrDetail.kabupatenKota;
            }
            if (addrDetail?.kecamatan != null &&
                addrDetail!.kecamatan!.isNotEmpty) {
              _alamatKecamatan = addrDetail.kecamatan;
            }
            if (addrDetail?.kelurahanDesa != null &&
                addrDetail!.kelurahanDesa!.isNotEmpty) {
              _alamatKelurahan = addrDetail.kelurahanDesa;
            }
            _detectedAddressSource = 'e-KTP (OCR)';
          });
        }
      }

      final detectedFields = <String>[
        if (nik != null && nik.isNotEmpty) 'NIK',
        if (nama != null && nama.isNotEmpty) 'Nama',
        if (ocrResult.tempatLahir != null && ocrResult.tempatLahir!.isNotEmpty) 'Tempat Lahir',
        if (ocrResult.tanggalLahir != null) 'Tgl Lahir',
        if (ocrResult.jenisKelamin != null) 'Jenis Kelamin',
        if (ocrResult.agama != null) 'Agama',
        if (ocrResult.pekerjaan != null) 'Pekerjaan',
        if (alamat != null && alamat.isNotEmpty) 'Alamat',
      ];

      if (detectedFields.length >= 4) {
        _showSuccess('KTP berhasil dipindai! ${detectedFields.join(', ')} terisi otomatis.');
      } else if (detectedFields.isNotEmpty) {
        _showSuccess(
          '${detectedFields.join(' & ')} berhasil terbaca dari KTP. Silakan periksa & lengkapi kolom lainnya.',
        );
      } else {
        _showWarning('Foto KTP tersimpan. AI belum dapat mendeteksi data dengan jelas, mohon isi manual.');
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
    final tempatLahir = _birthPlaceController.text.trim();
    final job = _jobController.text.trim();
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

    if (_fotoKtp == null) {
      _showWarning('Foto e-KTP wajib dipindai / diambil terlebih dahulu untuk verifikasi pendaftaran.');
      return;
    }

    if (_fotoWajah == null) {
      _showWarning('Foto selfie wajah wajib diambil terlebih dahulu untuk verifikasi identitas (KYC).');
      return;
    }

    if (tempatLahir.isEmpty) {
      _showWarning('Silakan masukkan tempat lahir sesuai KTP.');
      return;
    }

    if (_selectedBirthDate == null) {
      _showWarning('Silakan pilih tanggal lahir Anda.');
      return;
    }

    if (_selectedGender.isEmpty) {
      _showWarning('Silakan pilih jenis kelamin Anda.');
      return;
    }

    if (_selectedReligion == null || _selectedReligion!.isEmpty) {
      _showWarning('Silakan pilih agama Anda.');
      return;
    }

    if (job.isEmpty) {
      _showWarning('Silakan masukkan atau pilih pekerjaan Anda.');
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

    if (address.isEmpty) {
      _showWarning('Alamat domisili wajib diisi (ketik manual, scan e-KTP, atau deteksi lokasi GPS).');
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

    if (!_isConsentChecked) {
      _showWarning('Harap centang persetujuan penggunaan data dan ketentuan layanan untuk melanjutkan pendaftaran.');
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
      alamat: address,
      tempatLahir: tempatLahir,
      tanggalLahir: _formatBackendDate(_selectedBirthDate!),
      jenisKelamin: _selectedGender,
      agama: _selectedReligion,
      pekerjaan: job,
      provinsi: _alamatProvinsi,
      kabupatenKota: _alamatKabupatenKota,
      kecamatan: _alamatKecamatan,
      kelurahan: _alamatKelurahan,
      cabangId: _selectedCabangModel!.id,
      cabang: _selectedCabangModel!.name,
      fotoWajah: _fotoWajah,
      fotoKtp: _fotoKtp,
    );

    if (!mounted) return;

    if (success) {
      await AppDialog.showSuccess(
        context,
        title: 'Pendaftaran Berhasil',
        message: 'Selamat datang di KSPPS PASTI. Akun Anda telah berhasil dibuat.',
        buttonText: 'Masuk Beranda',
        barrierDismissible: true,
        showCloseButton: true,
      );

      // Aktifkan sesi login dan arahkan langsung ke Beranda
      authProvider.setAuthenticated();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      }
    } else {
      _showError(authProvider.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.');
    }
  }

  void _showSuccess(String message) {
    AppDialog.showSuccess(
      context,
      title: 'Berhasil',
      message: message,
    );
  }

  void _showWarning(String message) {
    AppDialog.showWarning(
      context,
      title: 'Perhatian',
      message: message,
    );
  }

  void _showError(String message) {
    AppDialog.showError(
      context,
      title: 'Terjadi Kesalahan',
      message: message,
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
                          Expanded(
                            child: Text(
                              'Tersedia ${filteredList.length} kantor cabang',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                                    Flexible(
                                                      child: Text(
                                                        cabang.city!,
                                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
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
    if (!widget.isEmbedded) {
      return const LoginScreen(initialIsRegister: true);
    }

    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
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
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DataConsentScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.privacy_tip_outlined, size: 14, color: Color(0xFF0F766E)),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'UU PDP No. 27/2022 • Kebijakan Privasi & Data',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0F766E)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section 1: Verifikasi Identitas (KYC)
                    _buildSectionHeader('Dokumen Identitas (KYC)', Icons.verified_user_outlined),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildInfoAlert(
                        'Unggah foto selfie wajah (otomatis menjadi foto profil akun) dan scan e-KTP. AI OCR akan otomatis membaca NIK, Nama, dan Alamat KTP Anda.',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoUploadCard(
                              title: 'Foto Selfie *',
                              subtitle: 'Ambil Selfie (Wajib)',
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
                              title: 'Scan e-KTP *',
                              subtitle: 'Pindai KTP (Wajib)',
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

                    // Section 2: Data Pribadi Sesuai KTP
                    _buildSectionHeader('Data Pribadi (Sesuai KTP)', Icons.badge_outlined),
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
                        icon: Icons.credit_card_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16, maxLengthEnforcement: MaxLengthEnforcement.enforced),
                        ],
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      
                      // Tempat Lahir
                      _buildTextField(
                        label: 'Tempat Lahir *',
                        controller: _birthPlaceController,
                        hint: 'Contoh: Banyumas',
                        icon: Icons.location_city_outlined,
                        enabled: !isLoading,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Tanggal Lahir
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Lahir *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: isLoading ? null : _selectBirthDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: Color(0xFF94A3B8), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedBirthDate != null
                                          ? _formatIndonesianDate(_selectedBirthDate!)
                                          : 'Pilih Tanggal',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedBirthDate != null
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Jenis Kelamin
                      _buildGenderSelector(isLoading),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Agama
                      _buildDropdownSelector(
                        label: 'Agama *',
                        value: _selectedReligion ?? 'Pilih Agama',
                        hasValue: _selectedReligion != null,
                        icon: Icons.account_balance_outlined,
                        enabled: !isLoading,
                        onTap: _openReligionSelector,
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Pekerjaan / Profesi
                      _buildJobField(isLoading),
                    ]),
                    const SizedBox(height: 24),

                    // Section 3: Keamanan Akun & Kontak
                    _buildSectionHeader('Keamanan Akun & Kontak', Icons.security_rounded),
                    const SizedBox(height: 12),
                    _buildInputCard([
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

                    // Section 4: Domisili & Pilihan Kantor Cabang
                    _buildSectionHeader('Domisili & Kantor Cabang KSPPS', Icons.location_city_rounded),
                    const SizedBox(height: 12),
                    _buildInputCard([
                      _buildTextField(
                        label: 'Alamat Domisili *',
                        controller: _addressController,
                        hint: 'Contoh: Jl. Merdeka No. 12, RT 01/RW 02',
                        icon: Icons.location_on_outlined,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 10),
                      _buildAddressLocationHelperCard(isLoading),
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

                    // Checkbox Kesediaan Penggunaan Data & Ketentuan Layanan
                    Container(
                      margin: const EdgeInsets.only(top: 24, bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isConsentChecked ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isConsentChecked ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isConsentChecked,
                              onChanged: isLoading
                                  ? null
                                  : (val) => setState(() => _isConsentChecked = val ?? false),
                              activeColor: const Color(0xFF0F766E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => setState(() => _isConsentChecked = !_isConsentChecked),
                                  child: const Text(
                                    'Pernyataan Kesediaan & Persetujuan Data',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    text: 'Saya menyatakan bersedia dan menyetujui ',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.45),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                                          ),
                                          child: const Text(
                                            'Ketentuan Layanan',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F766E),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' serta '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const DataConsentScreen()),
                                          ),
                                          child: const Text(
                                            'Kebijakan & Persetujuan Penggunaan Data Pribadi',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F766E),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' KSPPS PASTI sesuai UU PDP No. 27/2022.'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (isLoading || !_isConsentChecked) ? null : _submitRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: _isConsentChecked ? 3 : 0,
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
                        onPressed: () {
                          if (widget.onSwitchToLogin != null) {
                            widget.onSwitchToLogin!();
                          } else if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
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

  Widget _buildGenderSelector(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                label: 'Laki-laki',
                icon: Icons.male_rounded,
                isSelected: _selectedGender == 'Laki-laki',
                onTap: isLoading ? null : () => setState(() => _selectedGender = 'Laki-laki'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard(
                label: 'Perempuan',
                icon: Icons.female_rounded,
                isSelected: _selectedGender == 'Perempuan',
                onTap: isLoading ? null : () => setState(() => _selectedGender = 'Perempuan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobField(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Pekerjaan / Profesi *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: isLoading ? null : _openJobSelector,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 14, color: Color(0xFF0F766E)),
                    SizedBox(width: 4),
                    Text(
                      'Pilih Daftar',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: isLoading ? null : _openJobSelector,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _jobController.text.trim().isNotEmpty
                        ? _jobController.text.trim()
                        : 'Pilih atau ketik pekerjaan Anda',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _jobController.text.trim().isNotEmpty
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF94A3B8), size: 22),
              ],
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

  Widget _buildAddressLocationHelperCard(bool isLoading) {
    final regionParts = <String>[
      if (_alamatKelurahan != null && _alamatKelurahan!.isNotEmpty) _alamatKelurahan!,
      if (_alamatKecamatan != null && _alamatKecamatan!.isNotEmpty) _alamatKecamatan!,
      if (_alamatKabupatenKota != null && _alamatKabupatenKota!.isNotEmpty) _alamatKabupatenKota!,
      if (_alamatProvinsi != null && _alamatProvinsi!.isNotEmpty) _alamatProvinsi!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: (isLoading || _isDetectingAddress)
              ? null
              : _detectAddressFromCurrentLocation,
          icon: _isDetectingAddress
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
          label: Text(
            _isDetectingAddress
                ? 'Mendeteksi alamat dari GPS...'
                : 'Deteksi Alamat dari Lokasi Sekarang',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFFF0FDF4),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (regionParts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_detectedAddressSource != null)
                        Text(
                          'Wilayah terdeteksi ($_detectedAddressSource)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      Text(
                        regionParts.join(', '),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: isLoading
                      ? null
                      : () {
                          setState(() {
                            _alamatKelurahan = null;
                            _alamatKecamatan = null;
                            _alamatKabupatenKota = null;
                            _alamatProvinsi = null;
                            _detectedAddressSource = null;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _nearestCabangDetectedMessage != null
                          ? 'Terpilih: $_nearestCabangDetectedMessage'
                          : 'Aktifkan GPS untuk memilih cabang paling dekat dengan Anda secara otomatis.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _nearestCabangDetectedMessage != null
                            ? const Color(0xFF047857)
                            : const Color(0xFF065F46).withValues(alpha: 0.85),
                        fontWeight: _nearestCabangDetectedMessage != null ? FontWeight.w600 : FontWeight.normal,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMapModal,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Buka Peta', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF047857),
                    side: const BorderSide(color: Color(0xFF86EFAC), width: 1.2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDetectingLocation ? null : _detectNearestCabang,
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.near_me_rounded, size: 16),
                  label: Text(
                    _isDetectingLocation ? 'Mencari...' : 'Deteksi GPS',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                    shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
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
        constraints: const BoxConstraints(minHeight: 135),
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
                mainAxisSize: MainAxisSize.min,
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
                    textAlign: TextAlign.center,
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
          // Header Badge (Responsive without overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
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
                      Flexible(
                        child: Text(
                          'CABANG PENDAFTARAN ANDA',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (cabang.formattedDistance != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, color: Color(0xFF166534), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        cabang.formattedDistance!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                Expanded(
                  child: Text(
                    cabang.phone!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
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

