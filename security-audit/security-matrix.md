# OWASP Top 10 Security Compliance & Mitigation Matrix

**Application**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Standard**: OWASP Top 10  
**Evaluator**: Muhamad Rofii  

---

## Mitigation Matrix

| OWASP Category | Status | Technical Mitigation in SIMKODES | Reference |
| :--- | :---: | :--- | :--- |
| **A01: Broken Access Control** | **Mitigated** | Route protection via `auth` web middleware and `auth:sanctum` for APIs. Staging environment restricted by dynamic HTTP Basic Auth (`.htpasswd`). | `routes/web.php`<br>`routes/api.php` |
| **A02: Cryptographic Failures** | **Mitigated** | User passwords hashed using `bcrypt` (cost factor 12). HTTPS TLS 1.3 enforced by web server. Staging `.htpasswd` generated using Apache MD5 (`openssl passwd -apr1`). | `config/hashing.php` |
| **A03: Injection** | **Mitigated** | 100% of queries use Laravel Eloquent ORM and PDO parameterized statements. Input parameters validated via FormRequest classes before hitting controllers. | `app/Http/Requests/Api/` |
| **A04: Insecure Design** | **Mitigated** | Public subsidy lookup only accepts NIK and returns status without exposing sensitive financial or member data. API responses strictly follow the JSend envelope format. | `app/Traits/ApiResponseTrait.php`<br>`SubsidyCheckController.php` |
| **A05: Security Misconfiguration** | **Mitigated** | Root `.htaccess` denies direct access to sensitive files (`.env`, `.git`, `composer.lock`, `package-lock.json`). `APP_DEBUG=false` in Staging and Production. | `.htaccess`<br>`.github/workflows/` |
| **A06: Vulnerable and Outdated Components** | **Mitigated** | Automated scanning via `composer audit --locked` and `npm audit --audit-level=high` in CI (`security.yml`). 5 high-severity vulnerabilities resolved via `npm audit fix`. | `.github/workflows/security.yml`<br>`package-lock.json` |
| **A07: Identification and Auth Failures** | **Mitigated** | Login throttling enabled. Sanctum tokens revoked on logout (`tokens()->delete()`). Encrypted session cookies. | `AuthController.php` |
| **A08: Software and Data Integrity** | **Mitigated** | Package integrity locked in `composer.lock` and `package-lock.json`. Database backups transferred over encrypted SSH connections. | `.github/workflows/backup.yml` |
| **A09: Security Logging and Monitoring** | **Mitigated** | Integrated Sentry Cloud SDK (`sentry/sentry-laravel`) for real-time error tracking. Daily log rotation with 14-day retention. | `config/logging.php`<br>`bootstrap/app.php` |
| **A10: Server-Side Request Forgery (SSRF)** | **Mitigated** | File upload handlers validate local file streams directly from multipart requests; no arbitrary remote URLs are fetched. | `app/Http/Requests/` |
