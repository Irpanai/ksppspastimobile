# 🚀 Roadmap & Status Pengembangan KSPPS PASTI Mobile

Dokumen ini memetakan tahapan dan status pengembangan aplikasi **KSPPS PASTI Mobile (Si Hijau)** terintegrasi dengan backend **Laravel Sanctum**.

---

## 🎯 Arahan Strategis Saat Ini: FOKUS SIMPANAN
> **Keputusan**: Modul **Gadai / Rahn Syariah** dialihkan ke fase berikutnya (Backlog). Fokus utama saat ini dipusatkan sepenuhnya pada penguatan dan penyempurnaan **Ekosistem Simpanan & SIJAKA (Simpanan Berjangka Syariah)**.

---

## 🟢 FASE AKTIF: Ekosistem Simpanan & Layanan Finansial Terpadu

### 1. Setor Simpanan & Payment Gateway Multi-Kanal (✅ Selesai)
- [x] **Simpanan Sukarela**: Setor nominal bebas kapan saja dengan batas minimal Rp 10.000.
- [x] **Simpanan Wajib**: Validasi otomatis periode bulan/tahun, pencegahan bayar ganda/sebelum pendaftaran, kalkulator tunggakan.
- [x] **Simpanan Pokok**: Pembayaran wajib 1x saat awal keanggotaan.
- [x] **7 Bank Virtual Account Native In-App**: BSI Syariah (Real VA), BCA, Mandiri, BRI (BRIVA), BNI, CIMB Niaga, Danamon (verifikasi instan tanpa buka web).
- [x] **QRIS Versi Native In-App**:
  - Render vector QR dinamis resmi Bank Indonesia (NMID KSPPS PASTI) di dalam aplikasi.
  - Countdown timer kedaluwarsa tagihan & auto-polling status realtime.
  - Tombol **Download QR ke Galeri HP** (resolusi tinggi 3.0x via `gal`) & Salin Kode QR.
- [x] **Manajemen Kanal Admin**: Web admin dapat mengaktifkan/menonaktifkan metode pembayaran secara dinamis.

### 2. Penarikan Simpanan Sukarela (Withdrawal) (✅ Selesai)
- [x] **Form Penarikan In-App** (`tarik_simpanan_screen.dart`):
  - Pilihan preset nominal cepat & input nominal kustom.
  - Deteksi otomatis nomor rekening bank pencairan terdaftar milik anggota.
  - Validasi saldo minimal mengendap (Rp 25.000) & batas saldo sukarela.
- [x] **Keamanan Transaksi**: Wajib verifikasi 6-digit PIN transaksi sebelum submit.
- [x] **Status & Riwayat Penarikan**: Tab pantauan status pengajuan (`pending`, `disetujui`, `ditransfer`, `ditolak`).
- [x] **Panel Persetujuan Admin / Finance** (`PenarikanSimpananController.php`):
  - Verifikasi ketersediaan saldo, tombol cairkan (konfirmasi transfer manual), dan tolak pengajuan disertai alasan penolakan.
  - Pencatatan mutasi debet otomatis & jurnal pembukuan koperasi saat dicairkan.

### 3. SIJAKA - Simpanan Berjangka Mudharabah (✅ Selesai)
- [x] **Katalog Produk SIJAKA**: Tenor 1, 3, 6, dan 12 bulan dengan nisbah bagi hasil kompetitif.
- [x] **Pengajuan Bilyet Baru**: Form pembukaan bilyet digital, opsi perpanjangan otomatis (ARO) / manual, data ahli waris, & integrasi pembayaran setoran awal.
- [x] **Portofolio Bilyet Anggota**: Pemantauan bilyet aktif, nominal penempatan, tanggal jatuh tempo, dan estimasi bagi hasil.
- [x] **Log Bagi Hasil Bulanan**: Riwayat penerimaan bagi hasil per bilyet & resi PDF transaksi nisbah.

### 4. Mutasi & Riwayat Transaksi Finansial (✅ Selesai)
- [x] **Ringkasan Saldo di Beranda**: Visualisasi total akumulasi simpanan, pokok, wajib, sukarela, dan SIJAKA.
- [x] **Layar Simpanan & Mutasi**: Filter rentang tanggal, filter jenis simpanan (Semua, Sukarela, Wajib, Pokok), indikator hijau (masuk) / merah (keluar).
- [x] **Detail Transaksi**: Tampilan resi rincian transaksi dengan kode referensi & tanggal validasi.

---

## 🟡 FASE BERIKUTNYA (Backlog / Future Enhancements)

### 5. Gadai / Rahn Syariah (Ditunda ke Fase Berikutnya)
- [ ] Simulasi taksiran harga emas & barang elektronik.
- [ ] Kalkulator ujrah (biaya pemeliharaan barang jaminan) sesuai fatwa DSN-MUI.
- [ ] Form pengajuan gadai online, unggah foto barang jaminan, & pemilihan cabang penaksir.
- [ ] Pemantauan status akad rahn, jatuh tempo, & pelunasan / perpanjangan.

### 6. Transfer Saldo Antar Anggota
- [ ] Transfer saldo simpanan sukarela sesama anggota KSPPS PASTI secara instan.
- [ ] Validasi nomor rekening koperasi / no. anggota penerima.
- [ ] Konfirmasi nama penerima & validasi PIN keamanan.

### 7. Layanan PPOB (Pulsa, Token Listrik, Tagihan)
- [ ] Pembelian pulsa & paket data.
- [ ] Token PLN & tagihan pascabayar.

### 8. Modul ZISWAF Terpadu
- [ ] Kalkulator zakat maal & zakat profesi.
- [ ] Penyaluran infaq & sedekah langsung dari saldo simpanan sukarela.
