# 🚀 Roadmap Pengembangan MobileIntira

Berdasarkan analisis struktur direktori dan fitur yang sudah kita bangun (Auth, Home, Navigasi Utama, Katalog Produk, Simpanan, Gadai, dan Sijaka), aplikasi MobileIntira sudah memiliki fondasi *UI/UX* yang sangat kuat dan modern. 

Untuk menjadikan aplikasi ini sekelas aplikasi *mobile banking / fintech* syariah *Top Tier*, berikut adalah riset dan rekomendasi fitur lanjutan yang bisa kita kembangkan di fase berikutnya, diurutkan berdasarkan prioritas:

---

## 🔴 Prioritas Tinggi (Fitur Inti Keuangan)

### 1. Mutasi Rekening & Riwayat Transaksi (Transaction History)
Fitur paling esensial dalam aplikasi finansial. 
- **Fitur**: Menampilkan uang masuk/keluar, filter berdasarkan tanggal/bulan, dan filter jenis transaksi (Simpanan, PPOB, Transfer).
- **UI/UX**: Desain *list* transaksi dengan *icon* indikator hijau (masuk) dan merah (keluar), serta halaman detail transaksi yang bisa diunduh sebagai resi (PDF/Gambar).

### 2. Modul Transfer Dana (Transfer Module)
- **Transfer Antar Anggota**: Transfer saldo gratis antar rekening anggota koperasi.
- **Transfer Bank**: Integrasi untuk transfer ke bank umum nasional.
- **Daftar Favorit**: Menyimpan nomor rekening yang sering ditransfer.

### 3. Pemindai QRIS (QRIS Payment Scanner)
Tombol raksasa di tengah *navbar* saat ini belum berfungsi.
- **Fitur**: Membuka kamera untuk *scan* kode QRIS, input nominal pembayaran, validasi PIN, dan layar struk keberhasilan.

### 4. Layar Profil & Pengaturan Keamanan (Profile & Security)
Menu "Profil" di *navbar* saat ini masih berstatus WIP (*Work in Progress*).
- **Fitur**: Menampilkan e-KTP/Data Anggota, ubah kata sandi/PIN, pengaturan notifikasi, dan **Autentikasi Biometrik** (*Fingerprint / FaceID*) untuk login dan transaksi.

---

## 🟡 Prioritas Menengah (Ekspansi Produk & Layanan)

### 5. Eksekusi Pembayaran PPOB (Pulsa, Token, Tagihan)
Saat ini menu PPOB di beranda masih berupa *shortcut UI*.
- **Fitur**: Alur lengkap pembelian pulsa (pilih nomor dari kontak, pilih nominal dari *grid*, layar konfirmasi, masukkan PIN, dan struk sukses).

### 6. Kalkulator & Pengajuan Pembiayaan (Financing Module)
Melanjutkan halaman "Katalog Produk".
- **Fitur**: Saat pengguna menekan "Ajukan Sekarang" pada Murabahah/Multijasa, mereka akan dibawa ke layar simulasi margin syariah (pilih tenor, hitung cicilan) lalu form pengajuan foto jaminan/berkas.

### 7. Fitur Zakat, Infaq, Shadaqah & Wakaf (ZISWAF) Terpadu
- **Fitur**: *Kalkulator Zakat* (Zakat Maal, Profesi), pilihan lembaga amil, dan laporan donasi transparan.

---

## 🟢 Prioritas Lanjut (Infrastruktur & Arsitektur)

### 8. Pusat Notifikasi (Inbox & Alerts)
- **Fitur**: Lonceng di pojok kanan atas beranda dapat dibuka untuk melihat notifikasi sistem (promo, peringatan jatuh tempo Sijaka/Gadai, dan status pengajuan).

### 9. Integrasi Backend & State Management Lanjutan
- **Saran Arsitektur**: Mulai mengintegrasikan `Dio` (untuk API HTTP) dan mengubah *dummy data* di UI menjadi data dinamis.
- **Caching**: Menggunakan `Hive` atau `Shared Preferences` untuk menyimpan sesi pengguna (Token JWT).

---

## 💡 Apa yang ingin Anda kerjakan selanjutnya?

Pilih salah satu area di atas, atau jika Anda memiliki ide spesifik lainnya, beri tahu saya dan kita akan mulai mendesain layarnya!
