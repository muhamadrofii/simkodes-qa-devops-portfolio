# 🐛 Incident & Root Cause Analysis (RCA): BUG-002

**ID**: BUG-002  
**Judul**: `HTTP 500 on DashboardController: Call to unsupported function DATE_FORMAT in SQLite CI Runner`  
**Tingkat Keparahan**: High (Memblokir Pipeline Continuous Integration)  
**Lingkungan Terkena**: GitHub Actions Ubuntu Runner (PHPUnit Test Suite)  
**Penyelidik / Engineer**: Muhamad Rofii  

---

## 1. Deskripsi Gejala Masalah
Saat pipeline CI GitHub Actions menjalankan `php artisan test`, pengujian fitur dashboard gagal:
```text
FAIL Tests\Feature\AuthTest > authenticated user can access dashboard
Expected response status code [200] but received 500.
```
Pada lingkungan lokal pengembang (MySQL 8.0), pengujian dashboard berjalan normal 200 OK. Namun di runner CI yang menggunakan database file SQLite yang ringan dan cepat, query menghasilkan error 500.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)
Di dalam `DashboardController.php`, statistik pertumbuhan anggota per bulan dihitung menggunakan query raw SQL yang spesifik untuk dialek MySQL:
```php
Member::selectRaw("DATE_FORMAT(created_at, '%Y-%m') as month, count(*) as count")
    ->groupBy('month')
    ->get();
```
Fungsi `DATE_FORMAT()` adalah sintaks khusus MySQL. Mesin SQLite tidak memiliki fungsi `DATE_FORMAT()`, melainkan menggunakan fungsi bawaan `strftime('%Y-%m', created_at)`. Karena runner CI mengeksekusi tes di atas SQLite untuk menghemat waktu spin-up container, pemanggilan fungsi memicu query failure.

---

## 3. Tindakan Perbaikan (Resolution)
Mengimplementasikan deteksi driver database dinamis secara agnostik menggunakan `DB::connection()->getDriverName()` dan konstruksi `match`:

```php
// app/Http/Controllers/DashboardController.php
$driver = DB::connection()->getDriverName();
$dateFormat = match ($driver) {
    'sqlite' => "strftime('%Y-%m', created_at)",
    default  => "DATE_FORMAT(created_at, '%Y-%m')",
};

$memberGrowth = Member::selectRaw("{$dateFormat} as month, count(*) as count")
    ->groupBy('month')
    ->orderBy('month', 'asc')
    ->get();
```

---

## 4. Verifikasi & Dampak
- `Tests\Feature\AuthTest > authenticated user can access dashboard`: Lulus 200 OK di runner SQLite CI.
- Di lingkungan Staging dan Production (MySQL 8.0), query tetap memanfaatkan fungsi native `DATE_FORMAT`.
- Waktu eksekusi suite CI tetap cepat (< 10 detik) tanpa perlu menjalankan container database MySQL di GitHub Actions.
