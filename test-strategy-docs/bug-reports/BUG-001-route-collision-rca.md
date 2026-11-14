# 🐛 Incident & Root Cause Analysis (RCA): BUG-001

**ID**: BUG-001  
**Judul**: `LogicException: Unable to prepare route [members] for serialization. Another route has already been assigned name [members.index]`  
**Tingkat Keparahan**: Critical (Memblokir Deployment / Route Caching)  
**Lingkungan Terkena**: CI/CD Staging Deployment Pipeline  
**Penyelidik / Engineer**: Muhamad Rofii  

---

## 1. Deskripsi Gejala Masalah
Saat pipeline deployment GitHub Actions mengeksekusi step post-deploy `php artisan route:cache`, proses kompilasi gagal secara mendadak dengan stack trace:
```text
LogicException: Unable to prepare route [members] for serialization. Another route has already been assigned name [members.index].
#0 /vendor/laravel/framework/src/Illuminate/Routing/AbstractRouteCollection.php(247): ...
#5 /vendor/laravel/framework/src/Illuminate/Foundation/Console/RouteCacheCommand.php(109): ...
```
Error ini tertangkap dan dicatat oleh sistem monitoring **Sentry Cloud** sebagai unhandled exception.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)
Terjadi tabrakan penamaan route (*route naming collision*) antara route antarmuka web dan route RESTful API:
1. **Route Web** (`routes/web.php`):
   ```php
   Route::get('/members', [MemberController::class, 'index'])->name('members.index');
   ```
2. **Route API** (`routes/api.php`):
   ```php
   Route::apiResource('members', MemberController::class);
   ```
   Secara *default*, method `apiResource('members', ...)` di Laravel secara implisit menamai rute index-nya sebagai `members.index`.
3. Ketika Laravel mengeksekusi `route:cache`, compiler route collection melakukan iterasi dan menemukan dua entri berbeda yang berbagi nama route `members.index`. Hal ini memicu `LogicException` karena serialization membutuhkan nama route yang unik 100%.

---

## 3. Tindakan Perbaikan (Resolution)
Menambahkan prefix penamaan grup `->name('api.')` pada seluruh rute API yang dilindungi di `routes/api.php`:

```php
// routes/api.php
Route::middleware('auth:sanctum')->name('api.')->group(function () {
    Route::apiResource('members', MemberController::class);
    // Otomatis menjadi: api.members.index, api.members.store, api.members.show, dst.
});
```

---

## 4. Verifikasi & Dampak
- Eksekusi `php artisan route:cache` berhasil dengan output `INFO Routes cached successfully.`.
- Seluruh 79 tes PHPUnit dan 12 Playwright E2E tetap lulus 100%.
- Tidak ada breaking changes pada route web publik maupun internal.

---

## 5. Pelajaran yang Dipetik (Lessons Learned)
Selalu gunakan *namespaced route naming* (`api.*`, `admin.*`, `web.*`) saat membangun aplikasi monolitik hibrida yang menyediakan antarmuka web (Blade) sekaligus REST API JSON.
