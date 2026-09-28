# Dokumentasi REST API - KSPPS PASTI Mobile App

Dokumentasi resmi REST API untuk aplikasi mobile & integrasi KSPPS PASTI (Fokus Nasabah / Member).

---

## 📌 Informasi Umum

- **Base URL**: `http://localhost/api` (atau `https://<domain-kspps>/api`)
- **Format Data**: JSON (`Content-Type: application/json`, `Accept: application/json`)
- **Autentikasi**: Laravel Sanctum Bearer Token via Header `Authorization: Bearer <token>`

### 📑 Ringkasan Daftar Endpoint API

| Modul | Method | Endpoint | Auth | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| **Autentikasi** | `POST` | `/api/auth/register` | Public | **Registrasi akun nasabah baru & penerbitan No. Anggota** |
| | `POST` | `/api/auth/login` | Public | Login nasabah dengan Email & Password |
| | `GET` | `/api/auth/me` | Bearer | Cek profil user & status keanggotaan aktif |
| | `POST` | `/api/auth/logout` | Bearer | Logout & cabut token sesi |
| **Dashboard** | `GET` | `/api/member/dashboard` | Bearer | Data ringkasan saldo simpanan & portofolio |
| **Simpanan** | `GET` | `/api/member/simpanan/riwayat` | Bearer | Riwayat mutasi simpanan & filter jenis |
| **Sijaka** | `GET` | `/api/member/sijaka` | Bearer | Daftar bilyet simpanan berjangka aktif |
| | `GET` | `/api/member/sijaka/{id}` | Bearer | Detail bilyet Sijaka & log bagi hasil |
| **Payment Gateway** | `POST` | `/api/payment/snap-token` | Bearer | Request Midtrans Snap Token & redirect URL |
| | `POST` | `/api/payment/midtrans-notification` | Public | Webhook notifikasi settlement pembayaran |
| | `GET` | `/api/payment/status/{orderId}` | Bearer | Cek status transaksi pembayaran live |
| | `GET` | `/api/payment/history` | Bearer | Riwayat transaksi pembayaran digital |
| **Profil & KYC** | `GET` | `/api/member/profile` | Bearer | Data profil lengkap & ringkasan saldo |
| | `PUT` | `/api/member/profile` | Bearer | Update data pribadi, alamat & foto profil |
| | `PUT` | `/api/member/profile/password` | Bearer | Ubah password akun nasabah |

---

## 🔄 Standar Respon JSON

Seluruh endpoint API mengembalikan format respon seragam yang ditangani oleh `App\Traits\ApiResponse`.

### Respon Sukses (200 OK / 201 Created)

```json
{
  "success": true,
  "message": "Pesan deskriptif keberhasilan",
  "data": { ... },
  "errors": null
}
```

### Respon Gagal / Error (4xx / 5xx)

```json
{
  "success": false,
  "message": "Pesan deskriptif kesalahan",
  "data": null,
  "errors": {
    "field_name": [
      "Detail pesan validasi error"
    ]
  }
}
```

---

## 🔑 1. Autentikasi (`/auth`)

### 1.1 Login Nasabah

Digunakan untuk otentikasi akun nasabah/member melalui aplikasi mobile menggunakan Email dan Password.

- **Method**: `POST`
- **URL Path**: `/auth/login`
- **Auth Required**: Tidak (Public)
- **Headers**: 
  - `Content-Type: application/json`
  - `Accept: application/json`

#### Request Body:

| Parameter | Tipe | Wajib | Keterangan |
| :--- | :--- | :--- | :--- |
| `email` | `string` | Ya | Email terdaftar nasabah |
| `password` | `string` | Ya | Password akun |

#### Contoh Request Body:
```json
{
  "email": "nasabah@ksppspasti.com",
  "password": "password123"
}
```

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "1|abcdef1234567890qwertyuiop...",
    "user": {
      "id": 5,
      "name": "Budi Santoso",
      "email": "nasabah@ksppspasti.com",
      "no_anggota": "PASTI-0005",
      "status_keanggotaan": "aktif",
      "cabang": "Pusat",
      "roles": [
        "member"
      ]
    }
  },
  "errors": null
}
```

#### Kemungkinan Status Error:
- **422 Unprocessable Entity**: Format email tidak valid atau password kosong.
- **401 Unauthorized**: Email atau password tidak cocok.
- **403 Forbidden**: Akun tidak memiliki hak akses nasabah/member.

---

### 1.2 Registrasi Nasabah Baru

Mendaftarkan akun nasabah baru secara mandiri dari aplikasi mobile. Sistem secara otomatis membuat akun user dengan role `member`, menerbitkan Nomor Anggota unik, menginisialisasi saldo simpanan, dan mengembalikan token otentikasi Sanctum.

- **Method**: `POST`
- **URL Path**: `/auth/register`
- **Auth Required**: Tidak (Public)
- **Headers**: 
  - `Content-Type: application/json`
  - `Accept: application/json`

#### Request Body:

| Parameter | Tipe | Wajib | Keterangan | Contoh |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `string` | Ya | Nama lengkap sesuai KTP | `Budi Santoso` |
| `email` | `string` | Ya | Alamat email unik | `budi@gmail.com` |
| `password` | `string` | Ya | Password akun (min. 6 karakter) | `secret123` |
| `password_confirmation` | `string` | Opsional | Konfirmasi password | `secret123` |
| `nik` / `no_ktp` | `string` | Ya | Nomor Induk Kependudukan (16 digit) | `3301012345678901` |
| `no_hp` / `no_telpon` | `string` | Ya | Nomor handphone aktif / WhatsApp | `081234567890` |
| `alamat` | `string` | Opsional | Alamat domisili lengkap | `Jl. Pemuda No. 10, Semarang` |
| `tempat_lahir` | `string` | Opsional | Tempat lahir (Default: Semarang) | `Semarang` |
| `tanggal_lahir` | `string` | Opsional | Tanggal lahir (`YYYY-MM-DD`) | `1995-08-17` |
| `jenis_kelamin` | `string` | Opsional | `Laki-laki` / `Perempuan` atau `L` / `P` | `Laki-laki` |
| `provinsi` | `string` | Opsional | Provinsi domisili | `Jawa Tengah` |
| `kabupaten_kota` | `string` | Opsional | Kota/Kabupaten domisili | `Semarang` |
| `kecamatan` | `string` | Opsional | Kecamatan | `Semarang Tengah` |
| `kelurahan` | `string` | Opsional | Kelurahan/Desa | `Pendrikan Kidul` |
| `agama` | `string` | Opsional | Agama (Default: Islam) | `Islam` |
| `pekerjaan` | `string` | Opsional | Pekerjaan nasabah | `Wiraswasta` |
| `cabang` | `string` | Opsional | Cabang pendaftaran (Default: Pusat) | `Pusat` |

#### Contoh Request Body:
```json
{
  "name": "Budi Santoso",
  "email": "budi.santoso@gmail.com",
  "password": "password123",
  "password_confirmation": "password123",
  "nik": "3301012345678901",
  "no_hp": "081234567890",
  "alamat": "Jl. Pemuda No. 10, Semarang",
  "cabang": "Pusat"
}
```

#### Contoh Respon Sukses (201 Created):
```json
{
  "success": true,
  "message": "Pendaftaran nasabah berhasil.",
  "data": {
    "token": "24|YKqUtdwjqu1YnxUbYXdAFrYXGlb9JiQHvXpwUAoq7cf8ce1d",
    "user": {
      "id": 18,
      "name": "Budi Santoso",
      "email": "budi.santoso@gmail.com",
      "no_anggota": "2409260001",
      "status_keanggotaan": "aktif",
      "cabang": "Pusat",
      "roles": [
        "member"
      ]
    }
  },
  "errors": null
}
```

---

### 1.3 Profil Nasabah yang Sedang Login (`/me`)

Mendapatkan informasi detail profil nasabah serta status keanggotaan berdasarkan Sanctum Token yang dikirim.

- **Method**: `GET`
- **URL Path**: `/auth/me`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Data profil berhasil diambil",
  "data": {
    "id": 5,
    "name": "Budi Santoso",
    "email": "nasabah@ksppspasti.com",
    "profile_photo_url": null,
    "anggota": {
      "id": 12,
      "no_anggota": "PASTI-0005",
      "nik": "3201123456780001",
      "no_hp": "081234567890",
      "alamat": "Jl. Merdeka No. 45, Banjarmasin",
      "cabang": "Pusat",
      "status": "aktif",
      "tgl_bergabung": "2024-01-15"
    }
  },
  "errors": null
}
```

---

### 1.3 Logout Nasabah

Mencabut (revoke) `currentAccessToken` yang sedang aktif digunakan di device mobile.

- **Method**: `POST`
- **URL Path**: `/auth/logout`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Berhasil logout",
  "data": null,
  "errors": null
}
```

---

## 📊 2. Dashboard Nasabah (`/member`)

### 2.1 Summary Dashboard

Ringkasan total akumulasi saldo simpanan (pokok, wajib, sukarela, Sijaka, bagi hasil Sijaka) dan statistik nasabah.

- **Method**: `GET`
- **URL Path**: `/member/dashboard`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Dashboard member berhasil dimuat",
  "data": {
    "anggota": {
      "id": 12,
      "no_anggota": "PASTI-0005",
      "nama": "Budi Santoso",
      "status": "aktif",
      "cabang": "Pusat"
    },
    "ringkasan_saldo": {
      "saldo_pokok": 1000000,
      "saldo_wajib": 600000,
      "saldo_sukarela": 2500000,
      "saldo_sijaka": 10000000,
      "saldo_bagihasil_sijaka": 150000,
      "total_simpanan": 14100000
    },
    "statistiks": {
      "jumlah_bilyet_sijaka_aktif": 1
    }
  },
  "errors": null
}
```

#### Kemungkinan Status Error:
- **404 Not Found**: Data profil keanggotaan nasabah tidak ditemukan.

---

## 💰 3. Simpanan & Mutasi (`/member/simpanan`)

### 3.1 Riwayat Mutasi Simpanan

Mendapatkan daftar riwayat transaksi mutasi simpanan anggota (setoran/penarikan/pencairan) dilengkapi pagination dan filter.

- **Method**: `GET`
- **URL Path**: `/member/simpanan/riwayat`
- **Auth Required**: Ya (`Bearer <token>`)

#### Query Parameters:

| Parameter | Tipe | Wajib | Keterangan | Contoh |
| :--- | :--- | :--- | :--- | :--- |
| `jenis` | `string` | Tidak | Filter jenis simpanan (`pokok`, `wajib`, `sukarela`, `sijaka`, `sijaka_bagihasil`) | `sijaka_bagihasil` |
| `tipe` | `string` | Tidak | Filter tipe transaksi (`masuk`, `keluar`) | `masuk` |
| `tgl_mulai` | `string` | Tidak | Tanggal awal rentang transaksi (`YYYY-MM-DD`) | `2026-01-01` |
| `tgl_selesai` | `string` | Tidak | Tanggal akhir rentang transaksi (`YYYY-MM-DD`) | `2026-12-31` |
| `page` | `integer` | Tidak | Nomor halaman pagination (Default: 1) | `1` |

#### Contoh Request URL:
`GET /api/member/simpanan/riwayat?jenis=wajib&tgl_mulai=2026-08-01`

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Riwayat simpanan berhasil dimuat",
  "data": {
    "items": [
      {
        "id": 105,
        "jenis": "wajib",
        "tipe": "setor",
        "nominal": 50000,
        "bulan": 8,
        "tahun": 2026,
        "keterangan": "Setoran Simpanan Wajib Bulan Agustus 2026",
        "tgl_transaksi": "2026-08-10 09:15:00"
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1
  },
  "errors": null
}
```

---

## 📜 4. Portofolio Sijaka (`/member/sijaka`)

### 4.1 Daftar Bilyet Sijaka

Mendapatkan daftar seluruh Bilyet Simpanan Berjangka (Sijaka) milik nasabah.

- **Method**: `GET`
- **URL Path**: `/member/sijaka`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Daftar bilyet Sijaka berhasil dimuat",
  "data": [
    {
      "id": 3,
      "no_bilyet": "SJK-2026-0003",
      "nama_produk": "Sijaka Mudharabah 12 Bulan",
      "nominal_modal": 10000000,
      "saldo_bagihasil": 150000,
      "persen_nisbah_bulanan": 0.8,
      "tenor_bulan": 12,
      "tgl_setor": "2026-01-10",
      "tgl_jatuh_tempo": "2027-01-10",
      "metode_penyerahan_bagihasil": "Setiap Bulan",
      "status": "aktif"
    }
  ],
  "errors": null
}
```

---

### 4.2 Detail Bilyet Sijaka & Riwayat Bagi Hasil

Mendapatkan rincian detail bilyet Sijaka tertentu beserta riwayat pembagian nisbah bagi hasil per periode bulanan.

- **Method**: `GET`
- **URL Path**: `/member/sijaka/{rekening_id}`
- **Auth Required**: Ya (`Bearer <token>`)

#### Path Parameters:
- `rekening_id` (`integer`): ID Bilyet Rekening Sijaka.

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Detail Bilyet Sijaka berhasil dimuat",
  "data": {
    "bilyet": {
      "id": 3,
      "no_bilyet": "SJK-2026-0003",
      "no_pemohonan": "SP-2026-0003",
      "no_akad": "AKAD-SJK-003",
      "nama_produk": "Sijaka Mudharabah 12 Bulan",
      "nominal_modal": 10000000,
      "saldo_bagihasil": 150000,
      "persen_nisbah_bulanan": 0.8,
      "tenor_bulan": 12,
      "jumlah_bulan_dibayar": 2,
      "total_bagihasil_diterima": 160000,
      "tgl_setor": "2026-01-10",
      "tgl_jatuh_tempo": "2027-01-10",
      "metode_penyerahan_bagihasil": "Setiap Bulan",
      "status": "aktif"
    },
    "riwayat_bagihasil": [
      {
        "id": 12,
        "periode": "2026-02",
        "modal_sijaka": 10000000,
        "nominal_bagihasil": 80000,
        "created_at": "2026-02-10 10:00:00"
      },
      {
        "id": 25,
        "periode": "2026-03",
        "modal_sijaka": 10000000,
        "nominal_bagihasil": 80000,
        "created_at": "2026-03-10 10:00:00"
      }
    ]
  },
  "errors": null
}
```

#### Kemungkinan Status Error:
- **403 Forbidden**: Jika nasabah yang sedang login bukan pemilik dari Bilyet Sijaka tersebut.
- **404 Not Found**: ID Bilyet Sijaka tidak terdaftar di sistem.

---

## 🔒 5. Middleware & Keamanan

1. **Authentication Guard**: Menggunakan Laravel Sanctum (`auth:sanctum`).
2. **Access Control**: Validasi role pada saat login memastikan hanya pengguna yang relevan yang dapat mengakses API mobile.
3. **Owner Authorization**: Endpoint detail (`/member/sijaka/{rekening}`) memiliki verifikasi kepemilikan data (`anggota_id === $rekening->anggota_id`) untuk proteksi privasi antar-nasabah.

---

## 💳 6. Payment Gateway Midtrans (`/payment`)

Modul integrasi pembayaran digital mandiri (Virtual Account Bank, QRIS, GoPay, ShopeePay) menggunakan Midtrans Snap API.

### 6.1 Generate Snap Token

Membuat pesanan pembayaran digital baru untuk Setor Simpanan Wajib, Simpanan Pokok, Top-Up Sukarela, atau Pembukaan Sijaka.

- **Method**: `POST`
- **URL Path**: `/payment/snap-token`
- **Auth Required**: Ya (`Bearer <token>`)

#### Request Body (`application/json`):

| Field | Tipe | Wajib | Keterangan | Contoh |
| :--- | :--- | :--- | :--- | :--- |
| `type` | `string` | Ya | `simpanan_wajib`, `simpanan_pokok`, `simpanan_sukarela`, `pembukaan_sijaka` | `simpanan_wajib` |
| `nominal` | `integer` | Ya | Nominal pembayaran (Min. Rp 1.000) | `50000` |
| `bulan` | `integer` | Ya (jika `simpanan_wajib`) | Periode bulan simpanan wajib (1-12) | `9` |
| `tahun` | `integer` | Ya (jika `simpanan_wajib`) | Periode tahun simpanan wajib | `2026` |
| `sijaka_produk_id` | `integer` | Ya (jika `pembukaan_sijaka`) | ID Produk Sijaka yang dipilih | `1` |
| `nama_ahli_waris` | `string` | Tidak | Nama ahli waris (khusus Sijaka) | `Siti Aminah` |
| `hubungan_ahli_waris` | `string` | Tidak | Hubungan ahli waris (khusus Sijaka) | `Istri` |
| `metode_penyerahan_bagihasil` | `string` | Tidak | `Setiap Bulan` atau `Saat Jatuh Tempo` | `Setiap Bulan` |

#### Contoh Request Body (Setor Simpanan Wajib):
```json
{
  "type": "simpanan_wajib",
  "nominal": 50000,
  "bulan": 9,
  "tahun": 2026
}
```

#### Contoh Respon Sukses (201 Created):
```json
{
  "success": true,
  "message": "Snap Token berhasil dibuat.",
  "data": {
    "order_id": "PASTI-WJB-260921143000-123",
    "snap_token": "d76c3f30-891a-4c46-9d8a-123456789abc",
    "snap_redirect_url": "https://app.sandbox.midtrans.com/snap/v3/redirection/d76c3f30-891a-4c46-9d8a-123456789abc",
    "nominal": 50000,
    "nominal_format": "Rp 50.000",
    "type": "simpanan_wajib",
    "status": "pending",
    "client_key": "Mid-client-2Cc2SpmfT0nBrHqF",
    "created_at": "2026-09-21T14:30:00+08:00"
  }
}
```

---

### 6.2 Webhook Notification Callback

Endpoint publik yang dipanggil secara otomatis oleh server Midtrans saat terjadi perubahan status pembayaran (misal nasabah selesai transfer Virtual Account / scan QRIS).

- **Method**: `POST`
- **URL Path**: `/payment/midtrans-notification`
- **Auth Required**: Tidak (Verifikasi SHA-512 `signature_key` dari Midtrans)

#### Payload Respon dari Midtrans (`application/json`):
* `order_id`: ID Pesanan KSPPS
* `transaction_status`: `settlement`, `pending`, `expire`, `cancel`, `deny`
* `signature_key`: SHA-512 Signature Key
* `gross_amount`: Total nominal transaksi
* `payment_type`: `bank_transfer`, `qris`, `gopay`, dll

#### Respon Server KSPPS (200 OK):
```json
{
  "success": true,
  "message": "Notifikasi Midtrans berhasil diproses.",
  "data": {
    "order_id": "PASTI-WJB-260921143000-123",
    "status": "settlement"
  }
}
```

> **Catatan:** Saat status `settlement`, sistem backend secara otomatis menambah saldo simpanan anggota dan mencatat Jurnal Akuntansi.

---

### 6.3 Cek Live Status Pembayaran

Melakukan sinkronisasi dan pengecekan status live pesanan pembayaran ke server Midtrans.

- **Method**: `GET`
- **URL Path**: `/payment/status/{orderId}`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Status transaksi berhasil diperbarui.",
  "data": {
    "order_id": "PASTI-WJB-260921143000-123",
    "type": "simpanan_wajib",
    "nominal": 50000,
    "nominal_format": "Rp 50.000",
    "status": "settlement",
    "payment_type": "bank_transfer",
    "payment_channel": "bca",
    "va_number": "987654321012345",
    "paid_at": "2026-09-21T14:35:10+08:00"
  }
}
```

---

### 6.4 Riwayat Pembayaran Digital Anggota

Mendapatkan daftar seluruh transaksi pembayaran digital yang pernah dilakukan oleh anggota.

- **Method**: `GET`
- **URL Path**: `/payment/history`
- **Auth Required**: Ya (`Bearer <token>`)

#### Query Parameters:
* `status` (`string`, opsional): Filter status (`pending`, `settlement`, `expire`, `cancel`)
* `type` (`string`, opsional): Filter tipe (`simpanan_wajib`, `simpanan_pokok`, `simpanan_sukarela`, `pembukaan_sijaka`)
* `page` (`integer`, opsional): Nomor halaman (Default: 1)

---

## 👤 7. Profil & KYC Nasabah (`/member/profile`)

### 7.1 Detail Profil Lengkap

Mendapatkan informasi detail identitas nasabah, data pribadi, alamat domisili, dan ringkasan seluruh saldo simpanan.

- **Method**: `GET`
- **URL Path**: `/member/profile`
- **Auth Required**: Ya (`Bearer <token>`)

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Data profil nasabah berhasil dimuat.",
  "data": {
    "user": {
      "id": 1,
      "name": "Budi Santoso",
      "email": "budi@gmail.com",
      "profile_photo_url": "https://ksppspasti.com/storage/profile-photos/abc-123.webp",
      "roles": [
        "member"
      ]
    },
    "anggota": {
      "id": 1,
      "no_anggota": "2409260001",
      "no_ktp": "3301012345678901",
      "nik": "3301012345678901",
      "no_telpon": "081399887711",
      "no_hp": "081399887711",
      "tempat_lahir": "Semarang",
      "tanggal_lahir": "1995-08-17",
      "jenis_kelamin": "Laki-laki",
      "agama": "Islam",
      "pekerjaan": "Wiraswasta",
      "provinsi": "Jawa Tengah",
      "kabupaten_kota": "Kota Semarang",
      "kecamatan": "Semarang Tengah",
      "kelurahan": "Pendrikan Kidul",
      "alamat": "Jl. Pemuda No. 10, Semarang",
      "cabang": "Pusat",
      "jenis_keanggotaan": "Anggota Biasa",
      "status": "aktif",
      "status_keanggotaan": "aktif",
      "tgl_bergabung": "2026-09-24"
    },
    "ringkasan_saldo": {
      "saldo_pokok": 15000,
      "saldo_wajib": 50000,
      "saldo_sukarela": 500000,
      "saldo_sijaka": 5000000,
      "saldo_bagihasil_sijaka": 75000,
      "total_saldo": 5640000
    }
  },
  "errors": null
}
```

---

### 7.2 Update Data Pribadi & Alamat Nasabah

Memperbarui data diri, data pribadi, alamat domisili, dan foto profil nasabah secara mandiri.

- **Method**: `PUT` (atau `POST` jika mengirimkan multipart form data)
- **URL Path**: `/member/profile`
- **Auth Required**: Ya (`Bearer <token>`)
- **Headers**:
  - `Content-Type: application/json` atau `multipart/form-data`
  - `Accept: application/json`

#### Request Body:

| Parameter | Tipe | Wajib | Keterangan | Contoh |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `string` | Tidak | Nama lengkap nasabah | `Budi Santoso, S.Kom` |
| `email` | `string` | Tidak | Email akun nasabah | `budi.new@gmail.com` |
| `no_hp` / `no_telpon` | `string` | Tidak | Nomor handphone aktif / WA | `081399887711` |
| `tempat_lahir` | `string` | Tidak | Tempat lahir | `Kudus` |
| `tanggal_lahir` | `string` | Tidak | Tanggal lahir (`YYYY-MM-DD`) | `1996-05-12` |
| `jenis_kelamin` | `string` | Tidak | `Laki-laki` / `Perempuan` atau `L` / `P` | `Laki-laki` |
| `agama` | `string` | Tidak | Agama | `Islam` |
| `pekerjaan` | `string` | Tidak | Profesi / Pekerjaan | `Akuntan` |
| `provinsi` | `string` | Tidak | Nama Provinsi | `Jawa Tengah` |
| `kabupaten_kota` | `string` | Tidak | Nama Kota / Kabupaten | `Kota Semarang` |
| `kecamatan` | `string` | Tidak | Nama Kecamatan | `Gajahmungkur` |
| `kelurahan` | `string` | Tidak | Nama Kelurahan / Desa | `Bendan Ngisor` |
| `alamat` | `string` | Tidak | Alamat jalan / RT / RW lengkap | `Jl. Menoreh Raya No. 45B, Semarang` |
| `nik` / `no_ktp` | `string` | Tidak | NIK (16 digit) | `3301012345678901` |
| `photo` | `file` | Tidak | File foto profil baru (Max. 3MB) | `(binary)` |
| `photo_base64` | `string` | Tidak | Foto profil dalam format Base64 | `data:image/jpeg;base64,...` |

#### Contoh Request Body (`PUT /api/member/profile`):
```json
{
  "tempat_lahir": "Kudus",
  "tanggal_lahir": "1996-05-12",
  "jenis_kelamin": "Laki-laki",
  "agama": "Islam",
  "pekerjaan": "Akuntan",
  "provinsi": "Jawa Tengah",
  "kabupaten_kota": "Kota Semarang",
  "kecamatan": "Gajahmungkur",
  "kelurahan": "Bendan Ngisor",
  "alamat": "Jl. Menoreh Raya No. 45B, Semarang",
  "no_hp": "081399887711"
}
```

#### Contoh Respon Sukses (200 OK):
Mengembalikan struktur data profil lengkap terbaru persis seperti respon `GET /api/member/profile`.

---

### 7.3 Ubah Password Akun

Mengubah password login nasabah.

- **Method**: `PUT`
- **URL Path**: `/member/profile/password`
- **Auth Required**: Ya (`Bearer <token>`)

#### Request Body:

| Parameter | Tipe | Wajib | Keterangan | Contoh |
| :--- | :--- | :--- | :--- | :--- |
| `current_password` | `string` | Ya | Password saat ini | `passwordLama123` |
| `password` | `string` | Ya | Password baru (Min. 6 karakter) | `passwordBaru456` |
| `password_confirmation` | `string` | Ya | Konfirmasi password baru | `passwordBaru456` |

#### Contoh Respon Sukses (200 OK):
```json
{
  "success": true,
  "message": "Password akun berhasil diperbarui.",
  "data": null,
  "errors": null
}
```


