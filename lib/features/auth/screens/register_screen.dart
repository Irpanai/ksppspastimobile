import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../main_nav/screens/main_nav_screen.dart';
import '../models/cabang_model.dart';
import '../providers/auth_provider.dart';
import '../services/cabang_service.dart';

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

  bool _isObscure1 = true;
  bool _isObscure2 = true;

  File? _fotoKtp;
  File? _fotoWajah;
  bool _isOcrLoading = false;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickKtp() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _fotoKtp = File(pickedFile.path);
      });
      _scanOcr();
    }
  }

  Future<void> _scanOcr() async {
    if (_fotoKtp == null) return;
    setState(() => _isOcrLoading = true);
    
    try {
      final inputImage = InputImage.fromFile(_fotoKtp!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      String? nik;
      String? nama;

      // Parse NIK (16 digit angka)
      final nikRegExp = RegExp(r'(?:NIK|N I K|KIK|NIK:|KTP)[\W_]*(\d{16})', caseSensitive: false);
      final nikMatch = nikRegExp.firstMatch(text);
      if (nikMatch != null) {
        nik = nikMatch.group(1);
      } else {
        // Coba cari deretan 16 angka saja
        final angkaRegExp = RegExp(r'\b(\d{16})\b');
        final angkaMatch = angkaRegExp.firstMatch(text);
        if (angkaMatch != null) {
          nik = angkaMatch.group(1);
        }
      }

      // Parse Nama (Biasanya baris di bawah NIK atau mengandung kata NAMA)
      final namaRegExp = RegExp(r'Nama[\W_]*([A-Z\s]+)', caseSensitive: false);
      final namaMatch = namaRegExp.firstMatch(text);
      if (namaMatch != null) {
        nama = namaMatch.group(1)?.trim();
        // Hapus teks berlebih seperti 'Tempat' jika terikut
        if (nama != null && nama.contains('TEMPAT')) {
          nama = nama.split('TEMPAT')[0].trim();
        }
      }

      if (nik != null) {
        _nikController.text = nik;
      }
      if (nama != null && nama.isNotEmpty) {
        _nameController.text = nama;
      }
      
      if (nik != null || nama != null) {
        _showSuccess('KTP berhasil dipindai!');
      } else {
        _showWarning('Gagal menemukan data NIK/Nama di foto.');
      }

      textRecognizer.close();
    } catch (e) {
      _showError('Terjadi kesalahan saat membaca KTP.');
    } finally {
      if (mounted) setState(() => _isOcrLoading = false);
    }
  }

  Future<void> _pickWajah() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _fotoWajah = File(pickedFile.path);
      });
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

    if (nik.length != 16) {
      _showWarning('NIK harus berjumlah 16 digit angka.');
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

    // Validasi pemilihan cabang
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
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Pendaftaran berhasil! Selamat datang di KSPPS PASTI.', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    // Handle Bar
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
                              color: const Color(0xFF0E7955).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.map_rounded, color: Color(0xFF0E7955), size: 22),
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
                                  'Pilih provinsi lokasi kantor cabang KSPPS PASTI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
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

                    // Search Input Field
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

                    // Counter
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

                    // List View
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
                                          color: isSelected ? const Color(0xFF0E7955) : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            prov,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? const Color(0xFF0E7955) : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF0E7955), size: 18)
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

    final searchController = TextEditingController();
    List<CabangModel> filteredList = List.from(_cabangsInProvince);

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
                    // Handle Bar
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
                              color: const Color(0xFF0E7955).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0E7955), size: 22),
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

                    // Search Input Field
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
                                        filteredList = List.from(_cabangsInProvince);
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
                                filteredList = List.from(_cabangsInProvince);
                              } else {
                                final q = query.trim().toLowerCase();
                                filteredList = _cabangsInProvince.where((c) {
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

                    // Counter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text(
                            'Tersedia ${filteredList.length} kantor cabang',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
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
                                            color: isSelected ? const Color(0xFF0E7955) : const Color(0xFFF1F5F9),
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
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      cabang.name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? const Color(0xFF0E7955) : const Color(0xFF1E293B),
                                                      ),
                                                    ),
                                                  ),
                                                  if (cabang.code.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF0E7955).withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        cabang.code,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0E7955),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (cabang.displayLocation.isNotEmpty) ...[
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        cabang.displayLocation,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade700,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (cabang.address != null && cabang.address!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  cabang.address!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF0E7955), size: 20)
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Anggota Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Text
              const Text(
                'Bergabunglah bersama KSPPS PASTI.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data diri Anda di bawah ini untuk membuka rekening simpanan syariah secara instan.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _buildPhotoUploadButton(
                      title: 'Foto Wajah',
                      file: _fotoWajah,
                      onTap: _pickWajah,
                      icon: Icons.face_retouching_natural_rounded,
                      isLoading: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoUploadButton(
                      title: 'Scan KTP',
                      file: _fotoKtp,
                      onTap: _pickKtp,
                      icon: Icons.credit_card_rounded,
                      isLoading: _isOcrLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildLabel('Nama Lengkap (Sesuai KTP) *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Contoh: Budi Santoso',
                icon: Icons.person_outline_rounded,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Nomor Induk Kependudukan (NIK 16 Digit) *'),
              const SizedBox(height: 8),
              _buildTextField(
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
              const SizedBox(height: 18),

              _buildLabel('Nomor Handphone / WhatsApp *'),
              const SizedBox(height: 8),
              _buildTextField(
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
              const SizedBox(height: 18),

              _buildLabel('Alamat Email Aktif *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'nasabah@domain.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              _buildLabel('Password Akun *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Min. 6 karakter',
                icon: Icons.lock_outline_rounded,
                isObscure: _isObscure1,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(_isObscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Konfirmasi Password *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Ulangi password',
                icon: Icons.lock_outline_rounded,
                isObscure: _isObscure2,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(_isObscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Alamat Domisili (Opsional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hint: 'Jl. Pemuda No. 10, Semarang',
                icon: Icons.location_on_outlined,
                enabled: !isLoading,
              ),
              const SizedBox(height: 18),

              // SECTION PEMILIHAN CABANG (PROVINSI DULU -> LALU DATA CABANG TERDAFTAR)
              _buildLabel('Provinsi Kantor Cabang *'),
              const SizedBox(height: 8),
              _buildDropdownSelector(
                label: _selectedProvinceCabang ?? 'Pilih Provinsi Kantor Cabang',
                hasValue: _selectedProvinceCabang != null,
                icon: Icons.map_outlined,
                isLoading: _isLoadingProvinces,
                enabled: !isLoading,
                onTap: _openProvinceSearchModal,
              ),
              const SizedBox(height: 18),

              _buildLabel('Kantor Cabang Terdaftar *'),
              const SizedBox(height: 8),
              _buildDropdownSelector(
                label: _selectedCabangModel != null
                    ? _selectedCabangModel!.name
                    : (_selectedProvinceCabang == null
                        ? 'Pilih provinsi terlebih dahulu'
                        : (_isLoadingCabangs
                            ? 'Memuat daftar cabang...'
                            : 'Pilih Kantor Cabang (${_cabangsInProvince.length} cabang)')),
                subtitle: _selectedCabangModel != null
                    ? '${_selectedCabangModel!.code} • ${_selectedCabangModel!.displayLocation}'
                    : null,
                hasValue: _selectedCabangModel != null,
                icon: Icons.account_balance_outlined,
                isLoading: _isLoadingCabangs,
                enabled: !isLoading && _selectedProvinceCabang != null && !_isLoadingCabangs,
                isLocked: _selectedProvinceCabang == null,
                onTap: _openCabangSearchModal,
              ),
              const SizedBox(height: 36),

              // Submit Button
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
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
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

              // Back to login
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  /// Custom Selector Card untuk Searchable Dropdown
  Widget _buildDropdownSelector({
    required String label,
    String? subtitle,
    required bool hasValue,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool enabled = true,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? (hasValue ? const Color(0xFFF0FDF4).withOpacity(0.4) : const Color(0xFFF8FAFC))
              : const Color(0xFFF1F5F9).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? const Color(0xFF0E7955).withOpacity(0.5) : const Color(0xFFE2E8F0),
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasValue
                  ? const Color(0xFF0E7955)
                  : (isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8)),
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.bold : FontWeight.w500,
                      color: hasValue
                          ? const Color(0xFF1E293B)
                          : (isLocked ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0E7955),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7955))),
              )
            else if (isLocked)
              const Icon(Icons.lock_outline_rounded, color: Color(0xFFCBD5E1), size: 18)
            else if (hasValue)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF0E7955), size: 20)
            else
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        inputFormatters: [
          if (inputFormatters != null) ...inputFormatters,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength, maxLengthEnforcement: MaxLengthEnforcement.enforced),
        ],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
            letterSpacing: isObscure ? 2 : 0,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadButton({
    required String title,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: file != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file != null ? const Color(0xFF0E7955) : const Color(0xFFE2E8F0),
            width: file != null ? 2 : 1,
          ),
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7955)))))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    file != null ? Icons.check_circle_rounded : icon,
                    color: file != null ? const Color(0xFF0E7955) : const Color(0xFF94A3B8),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    file != null ? 'Selesai' : title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: file != null ? const Color(0xFF0E7955) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
