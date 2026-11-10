<p align="center">
  <img src="assets/images/logo-kspps-pasti.png" width="120" alt="KSPPS PASTI Logo">
</p>

<h1 align="center">KSPPS PASTI Mobile</h1>
<h3 align="center">Si Hijau by INTIRA — Aplikasi Keuangan Koperasi Syariah Digital</h3>

<p align="center">
  Aplikasi mobile modern untuk anggota <b>KSPPS INOVASI PASTI NUSANTARA</b> berbasis Flutter.<br/>
  Menyediakan layanan simpanan syariah, deposito berjangka (SIJAKA), transaksi digital, cetak struk resmi, dan otentikasi biometrik yang aman dan terpercaya.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-Feature--First%20Provider-4CAF50" alt="Architecture">
  <img src="https://img.shields.io/badge/Package-com.ksppspasti.mobile-1B5E20" alt="Package">
  <img src="https://img.shields.io/badge/License-Proprietary-blue.svg" alt="License">
</p>

---

## 📑 Daftar Isi

- [Tentang Aplikasi](#-tentang-aplikasi)
- [Fitur Utama](#-fitur-utama)
- [Arsitektur & Struktur Direktori](#-arsitektur--struktur-direktori)
- [Teknologi & Dependensi](#-teknologi--dependensi)
- [Prasyarat & Persiapan](#-prasyarat--persiapan)
- [Panduan Instalasi & Menjalankan](#-panduan-instalasi--menjalankan)
- [Membangun Aplikasi (Build APK & AAB)](#-membangun-aplikasi-build-apk--aab)
- [Konfigurasi API & Environment](#-konfigurasi-api--environment)
- [Keamanan & Privasi](#-keamanan--privasi)

---

## 🌟 Tentang Aplikasi

**KSPPS PASTI Mobile** adalah gerbang digital bagi seluruh anggota Koperasi Simpan Pinjam dan Pembiayaan Syariah (KSPPS) Inovasi Pasti Nusantara. Aplikasi ini dirancang untuk memudahkan nasabah melakukan pendaftaran keanggotaan (KYC digital), memantau saldo simpanan syariah, mengajukan deposito bagi hasil mudharabah (SIJAKA), serta melakukan setoran dan penarikan secara mandiri 24 jam sehari sesuai prinsip syariat Islam.

---

## ✨ Fitur Utama

### 🔐 1. Autentikasi & Keamanan Berlapis
- **Login Biometrik Cepat**: Masuk ke aplikasi instan menggunakan **Sidik Jari (*Fingerprint*)** atau **Face ID / Pengenalan Wajah** melalui integrasi `local_auth`.
- **PIN Transaksi 6-Digit**: Proteksi otorisasi setiap kali melakukan transaksi finansial, perubahan profil sensitif, atau penarikan dana.
- **Lupa Password via OTP Email**: Reset password mandiri dengan kode verifikasi OTP yang dikirimkan langsung ke email terdaftar.
- **Manajemen Sesi Aman**: Penyimpanan token terenkripsi dan auto-login berbasis penyimpanan lokal aman.

### 💰 2. Layanan Simpanan Syariah
- **Simpanan Pokok & Wajib**: Pemantauan status setoran pokok dan angsuran wajib bulanan, lengkap dengan kalkulator tunggakan otomatis dan tagihan aktif.
- **Simpanan Sukarela (Tabungan Transaksional)**: Penyetoran dana (*Top Up*) dan penarikan langsung ke rekening bank anggota.
- **Multi Payment Gateway**: Integrasi gateway pembayaran digital (DOKU Checkout & Midtrans) mendukung QRIS (Semua Bank/E-Wallet), Virtual Account (Mandiri, BRI, BNI, Permata, dll.).
- **Mutasi & Riwayat Lengkap**: Filter mutasi masuk/keluar, rentang tanggal dinamis, dan riwayat transaksi mendalam.

### 🧾 3. Cetak & Bagikan Struk Transaksi Resmi
- **Nota Transaksi Elektronik Resmi**: Struk kasir berlogo KSPPS PASTI dengan nomor referensi unik, rincian biaya, dan keterangan transaksi.
- **QR Code Keaslian**: QR code verifikasi untuk menjamin validitas bukti pembayaran koperasi.
- **Bagikan Langsung ke WhatsApp**: Export otomatis ke file gambar PNG resolusi tinggi (3x pixel ratio) yang siap dibagikan ke keluarga, bendahara, atau disimpan ke Galeri HP.

### 📈 4. SIJAKA (Simpanan Berjangka / Deposito Syariah)
- **Simulasi Nisbah Bagi Hasil**: Estimasi imbal hasil mudharabah berdasarkan jangka waktu penempatan (1, 3, 6, 12 bulan).
- **Pengajuan Bilyet Baru**: Pembukaan deposito syariah digital langsung dari aplikasi.
- **Portofolio Aktif**: Pemantauan sertifikat bilyet, tanggal jatuh tempo, status perpanjangan (*ARO/Non-ARO*), dan laporan bagi hasil bulanan.

### 🆔 5. Registrasi Anggota & KYC Cerdas
- **OCR KTP Otomatis**: Pemindaian KTP menggunakan kamera on-device (*Google ML Kit Text Recognition*) yang mengekstrak NIK, Nama, dan Tempat/Tgl Lahir tanpa mengetik manual.
- **Verifikasi Selfie KYC**: Kamera swafoto native untuk verifikasi identitas anggota baru.
- **Peta Interaktif Kantor Cabang**: Pencarian kantor cabang pendaftaran terdekat menggunakan lokasi GPS (*Geolocator* & *Flutter Map OpenStreetMap*).

### 🚀 6. Pembaruan Otomatis & Splash Interaktif
- **In-App Update Reminder**: Notifikasi pop-up otomatis ketika ada versi aplikasi terbaru yang dirilis di Google Play Store.
- **Splash Screen Dinamis**: Media pembuka (video/gambar) yang tersinkronisasi langsung dari CMS Admin Web KSPPS.

---

## 📂 Arsitektur & Struktur Direktori

Aplikasi dibangun menggunakan pola **Feature-First Clean Architecture** dengan manajemen state terpusat via **Provider**:

```text
lib/
├── core/                         # Komponen Inti & Infrastruktur
│   ├── constants/                # Endpoint API, warna, dan aset global
│   │   └── api_constants.dart
│   ├── network/                  # HTTP client, interceptor, timeout & error handler
│   │   └── api_client.dart
│   ├── services/                 # Layanan platform (Biometrik, Update, Download, Storage)
│   │   ├── biometric_service.dart
│   │   ├── in_app_update_service.dart
│   │   └── storage_service.dart
│   ├── utils/                    # Formatter rupiah, tanggal, terbilang, validator
│   └── widgets/                  # Dialog pembaruan, widget reusable inti
│       └── in_app_update_dialog.dart
│
├── features/                     # Modul Fungsional Aplikasi
│   ├── auth/                     # Login, Register, KYC Kamera, Lupa Password, PIN
│   ├── home/                     # Beranda, Saldo Ringkasan, Promo, Tunggakan
│   ├── savings/                  # Simpanan Pokok, Wajib, Sukarela, Form Penarikan
│   ├── payment/                  # Checkout DOKU/Midtrans, Webview, Bukti Pembayaran
│   ├── history/                  # Mutasi Transaksi, Filter Tanggal, Cetak Struk
│   ├── sijaka/                   # Portofolio Deposito, Simulasi, Pengajuan, SHU
│   ├── profile/                  # Data Pribadi, Rekening Bank, Keamanan, Pengunduran Diri
│   ├── notification/             # Notifikasi Anggota, Aktivasi, Pengingat Tunggakan
│   ├── promo/                    # Informasi & Berita Promo Koperasi
│   ├── qris/                     # Pemindai QRIS & Pembayaran Merchant
│   ├── gadai/                    # Pembiayaan Gadai Syariah (Rahn)
│   └── splash/                   # Layar Splash Dinamis (Video/Image Cache)
│
├── shared/                       # Widget UI Bersama
│   └── widgets/
│       ├── app_dialog.dart       # Dialog konfirmasi, sukses, peringatan seragam
│       ├── premium_header.dart   # Header lengkung khas hijau KSPPS
│       └── struk_transaksi_dialog.dart # Dialog Nota & Share WhatsApp
│
└── main.dart                     # Entry point, Provider setup, Theme configuration
```

---

## 🛠️ Teknologi & Dependensi

| Pustaka / Plugin | Versi | Kegunaan |
| :--- | :---: | :--- |
| **`flutter`** | `^3.10.7` | Framework UI multiplatform utama |
| **`provider`** | `^6.1.5` | State management teruji dan reaktif |
| **`local_auth`** | `^3.0.2` | Autentikasi biometrik Sidik Jari & Face ID |
| **`google_mlkit_text_recognition`** | `^0.17.1` | OCR pemindaian KTP otomatis offline di HP |
| **`camera`** | `^0.12.1` | Pengambilan foto KTP & selfie KYC |
| **`qr_flutter`** | `^4.1.0` | Generator QR Code bukti transaksi elektronik |
| **`share_plus`** | `^13.3.1` | Berbagi gambar struk langsung ke WhatsApp |
| **`gal`** | `^2.3.3` | Menyimpan gambar struk resmi ke Galeri HP |
| **`flutter_map` & `latlong2`** | `^8.3.2` | Peta satelit & sebaran kantor cabang koperasi |
| **`geolocator`** | `^14.1.1` | Deteksi koordinat GPS lokasi perangkat nasabah |
| **`video_player`** | `^2.14.1` | Pemutaran video pembuka (*splash screen*) |
| **`package_info_plus`** | `^10.2.2` | Pemeriksaan versi aplikasi untuk In-App Update |

---

## 🚀 Panduan Instalasi & Menjalankan

### 1. Kloning Repositori
```bash
git clone https://github.com/ksppspasti/mobile-app.git
cd mobile-app
```

### 2. Pasang Dependensi
```bash
flutter pub get
```

### 3. Jalankan di Emulator atau Perangkat Fisik
Pastikan HP Android Anda telah mengaktifkan **USB Debugging**:
```bash
# Mode Debug
flutter run

# Mode Release di perangkat fisik
flutter run --release
```

---

## 📦 Membangun Aplikasi (Build APK & AAB)

### Membangun APK Uji Coba (*Debug APK*):
```bash
flutter build apk --debug
```
*Output*: `build/app/outputs/flutter-apk/app-debug.apk`

### Membangun Android App Bundle (*Release .aab*) untuk Google Play:
Pastikan file kunci rilis `key.properties` dan `upload-keystore.jks` telah terpasang di folder `android/app/`:
```bash
flutter build appbundle
```
*Output*: `build/app/outputs/bundle/release/app-release.aab`

---

## ⚙️ Konfigurasi API & Environment

Konfigurasi alamat server backend diatur pada file [`lib/core/constants/api_constants.dart`](lib/core/constants/api_constants.dart):

```dart
class ApiConstants {
  // Production / Demo URL Server Koperasi
  static const String defaultLocalhostUrl = 'https://demo.ksppspasti.com/api';
  static const String androidEmulatorUrl  = 'https://demo.ksppspasti.com/api';

  // Base Host untuk gambar & dokumen
  static String get baseHost => baseUrl.replaceAll(RegExp(r'/api/?$'), '');
}
```

---

## 🔒 Keamanan & Privasi

1. **Kepatuhan Privasi Google Play**:
   Aplikasi ini **100% patuh** terhadap *Photo and Video Permissions Policy* Google Play. Aplikasi menggunakan fitur resmi sistem *Android Photo Picker* dan kamera langsung, tanpa meminta izin *broad external storage* yang berbahaya.
2. **Perlindungan Token & Data**:
   Autentikasi menggunakan standar *Bearer Token* yang otomatis kedaluwarsa jika terjadi anomali atau permintaan logout.
3. **Penyimpanan Transaksi**:
   File struk sementara dibersihkan dari cache perangkat dan hanya diexport atas persetujuan pengguna saat tombol *"Bagikan"* ditekan.

---

<p align="center">
  <b>KSPPS INOVASI PASTI NUSANTARA</b><br/>
  <i>Membangun Ekonomi Umat, Menjaga Amanah dengan Profesionalisme & Syariat.</i>
</p>
