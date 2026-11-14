# 🛡️ OWASP Top 10 Security Compliance & Mitigation Matrix

**Aplikasi**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Tinjauan Keamanan**: QA & Security Engineering  
**Standar Referensi**: OWASP Top 10 (2021/2026 Edition)

---

## 📋 Matriks Kepatuhan & Mitigasi Risiko

| Kategori Risiko OWASP | Status | Mitigasi Teknis di SIMKODES | File / Komponen Terkait |
| :--- | :---: | :--- | :--- |
| **A01: Broken Access Control** | **Terkontrol** | Penerapan middleware `auth` untuk panel web, middleware `auth:sanctum` untuk REST API, serta isolasi akses staging dengan HTTP Basic Auth dinamis via Apache `.htpasswd`. | [staging.yml](file:///.github/workflows/staging.yml)<br>`app/Http/Middleware` |
| **A02: Cryptographic Failures** | **Terkontrol** | Enkripsi password menggunakan `bcrypt` dengan cost factor 12. Transport data diamankan via HTTPS TLS 1.3 LiteSpeed. Hash Basic Auth menggunakan algoritma Apache MD5 (`openssl passwd -apr1`). | `config/hashing.php`<br>`routes/api.php` |
| **A03: Injection (SQL & Command)** | **Terkontrol** | Penggunaan Laravel Eloquent ORM & PDO Parameterized Query secara 100% pada seluruh controller. Input NIK, nama, dan parameter disanitasi ketat melalui FormRequest classes. | `app/Http/Requests/Api/`<br>`MemberController.php` |
| **A04: Insecure Design** | **Terkontrol** | Pemisahan tegas antara antarmuka publik warga (Cek NIK Subsidi) tanpa mengekspos field sensitif (gaji, simpanan, riwayat pinjaman). Standarisasi respons format JSend Envelope. | [ApiResponseTrait.php](file:///app/Traits/ApiResponseTrait.php)<br>`SubsidyCheckController.php` |
| **A05: Security Misconfiguration** | **Terkontrol** | Pencegahan akses publik langsung ke file sensitif (`.env`, `.git`, `composer.json`, `storage/logs`) melalui aturan strict di root `.htaccess`. Flag `APP_DEBUG=false` pada environment Staging & Production. | `.htaccess`<br>`config/app.php` |
| **A06: Vulnerable and Outdated Components** | **Terkontrol** | Otomatisasi CI/CD `security.yml` (*task-b1*) yang menjalankan `composer audit --locked` dan `npm audit --audit-level=high`. Penambalan 5 CVE dependensi frontend via `npm audit fix`. | [security.yml](file:///.github/workflows/security.yml)<br>`package-lock.json` |
| **A07: Identification and Auth Failures** | **Terkontrol** | Proteksi brute force login via throttling limit, masa berlaku token Sanctum yang dapat di-revoke instan (`tokens()->delete()`), dan session timeout terenkripsi. | `AuthController.php`<br>`config/sanctum.php` |
| **A08: Software and Data Integrity Failures** | **Terkontrol** | Integritas package dijamin melalui `composer.lock` hash verifikasi dan `package-lock.json`. Download backup database via koneksi SSH terenkripsi port 65002. | [backup.yml](file:///.github/workflows/backup.yml)<br>`composer.lock` |
| **A09: Security Logging and Monitoring Failures** | **Terkontrol** | Integrasi Sentry Cloud SDK untuk real-time crash capture & anomalous exceptions (`SIMKODES-1`). Audit log rotasi harian 14 hari di `storage/logs/`. | `bootstrap/app.php`<br>`config/logging.php` |
| **A10: Server-Side Request Forgery (SSRF)** | **Terkontrol** | Seluruh proses upload lampiran surat dan foto anggota hanya menerima file fisik lokal dari multipart form (`UploadedFile::fake()` / PHP `is_uploaded_file()`), tidak menerima URL remote bebas. | `app/Http/Requests/` |
