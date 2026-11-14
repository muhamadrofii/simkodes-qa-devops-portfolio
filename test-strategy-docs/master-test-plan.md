# 📋 Master Test Plan & Quality Assurance Strategy

**Aplikasi**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Tujuan Dokumen**: Panduan strategi pengujian menyeluruh berbasis 7 Pilar QA Industri  
**Penyusun**: Muhamad Rofii (QA Automation & DevOps Engineer)  

---

## 1. Lingkup Pengujian (Scope of Testing)

### A. Fitur Dalam Lingkup (In-Scope)
1. **Autentikasi & Otorisasi**: Login sesi web, validasi password, proteksi guest, dan Sanctum Bearer Token API.
2. **Master Data Anggota & Cetak KTA**: Operasi CRUD, validasi NIK/nama/kontak, dan generasi dokumen fisik KTA PDF berstandar cetak.
3. **Struktur Pengurus & Pengawas**: Pencatatan dewan koperasi, upload pas foto, tanda tangan digital, dan KTA pengurus.
4. **Pengarsipan Persuratan**: Upload dan download lampiran PDF berkas Surat Masuk dan Surat Keluar.
5. **Inventaris & Manajemen Aset**: Pencatatan barang, kalkulasi jumlah/harga, dan ekspor multi-format (PDF & XLSX).
6. **Bantuan & Subsidi Warga**: Verifikasi kelayakan NIK penerima subsidi, rekapitulasi bantuan, dan filter rentang tanggal laporan.
7. **RESTful API**: Format respons standar JSend Envelope, kode status HTTP konsisten (200, 201, 401, 404, 422).
8. **Efisiensi Database**: Eliminasi query N+1 dan pengujian indeks pencarian.

---

## 2. Pendekatan Piramida Pengujian (Test Pyramid Strategy)

```
        / \
       /   \      12 Playwright E2E Tests (End-to-End User Journeys)
      / E2E \     - Login, Dashboard Stats, CRUD Form, Modal & PDF Download
     /-------\
    /   API   \   19 API Tests & SQL Efficiency Tests
   /           \  - Sanctum Auth, JSend Envelope, N+1 Prevention
  /-------------\
 /  Unit & Feat  \ 60 PHPUnit Feature Tests
/                 \ - Controller CRUD Logic, File Uploads, Model Relationships
-------------------
```

---

## 3. Matriks Lingkungan Uji (Test Environments)

| Parameter | Local Testing | CI Runner Testing | Staging (Pre-Prod) | Production |
| :--- | :--- | :--- | :--- | :--- |
| **OS** | Windows 11 / Linux | Ubuntu Latest | Cloud Linux (Hostinger) | Cloud Linux |
| **Database** | MySQL 8.0 & SQLite | SQLite (In-Memory) | MySQL 8.0 (Staging DB) | MySQL 8.0 (Prod DB) |
| **Web Server** | `php artisan serve` | Auto-webserver Playwright | LiteSpeed Enterprise | LiteSpeed Enterprise |
| **Runner** | Developer Machine | GitHub Actions Runner | Hostinger Staging Host | Hostinger Live Host |

---

## 4. Kriteria Masuk & Keluar (Entry & Exit Criteria)

### A. Kriteria Masuk (Entry Criteria)
- Kode lolos kompilasi Vite (`npm run build`).
- Dependency bersih dari kerentanan kritis (`composer audit --locked` & `npm audit`).
- Migrasi database dan seeder berjalan tanpa error.

### B. Kriteria Keluar (Exit Criteria)
- **100% PHPUnit Test Suite Lulus** (79/79 Passed).
- **100% Playwright E2E Test Suite Lulus** (12/12 Passed).
- **Zero Critical / Blocker Defects** tercatat di issue tracker.
- **Waktu Eksekusi Query Bebas N+1** pada seluruh endpoint daftar data.
- **Persetujuan UAT** oleh tim pengurus koperasi desa di Staging.
