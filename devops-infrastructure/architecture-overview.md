# ⚙️ DevOps Infrastructure & Shared Hosting Engineering Solution

**Sistem**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Platform Cloud**: Hostinger LiteSpeed Enterprise Shared Hosting  
**DevOps Engineer**: Muhamad Rofii  

---

## 1. Arsitektur Lingkungan Multi-Tier

SIMKODES menerapkan strategi isolasi 3 lingkungan (*Local, Staging, Production*) untuk memastikan kode yang masuk ke live server telah teruji 100% bebas dari regresi maupun bug kritis.

```mermaid
flowchart TD
    subgraph Local Development
        LOCAL_DEV["Developer Workstation"]
        DOCKER["Docker Compose (App + DB + phpMyAdmin)"]
        TEST_LOCAL["Local PHPUnit (79 Tests) & Playwright (12 Tests)"]
        LOCAL_DEV --> DOCKER
        LOCAL_DEV --> TEST_LOCAL
    end

    subgraph CI/CD Quality Gate (GitHub Actions)
        GIT_PUSH["Git Push master / staging"]
        CI_JOB["ci.yml (SQLite Runner)"]
        SEC_JOB["security.yml (Composer & NPM Audit)"]
        GIT_PUSH --> CI_JOB
        GIT_PUSH --> SEC_JOB
    end

    subgraph Staging Environment (Hostinger)
        STAGING_DEPLOY["staging.yml (CD Pipeline)"]
        BASIC_AUTH["Dynamic OpenSSL HTTP Basic Auth"]
        STAGING_HOST["simkodes-staging.sranak.com"]
        CI_JOB -->|Pass| STAGING_DEPLOY
        STAGING_DEPLOY --> BASIC_AUTH
        BASIC_AUTH --> STAGING_HOST
    end

    subgraph Live Production (Hold on Standby)
        PROD_GATE["production.yml (Requires Manual 'DEPLOY' Input)"]
        PROD_HOST["sranak.com / simkodes.sranak.com"]
        UAT_APPROVAL["UAT Approval by Cooperative Team"] --> PROD_GATE
        PROD_GATE --> PROD_HOST
    end
```

---

## 2. Tantangan Rekayasa Shared Hosting & Solusinya

Shared hosting sering dianggap tidak ramah untuk alur DevOps modern karena ketiadaan akses root, Docker, dan izin kustomisasi daemon. Namun, SIMKODES membuktikan bahwa shared hosting dapat dikelola setara arsitektur enterprise melalui solusi rekayasa berikut:

### A. Bypass Fungsi PHP `symlink()` yang Dinonaktifkan
* **Kendala**: Hostinger mematikan fungsi PHP `symlink()` di `php.ini` untuk keamanan server bersama, sehingga perintah standar `php artisan storage:link` memicu fatal error:
  `Call to undefined function Illuminate\Filesystem\symlink()`.
* **Solusi Rekayasa**: Membuka jalur symbolic link menggunakan shell Linux langsung di level sistem operasi via script deployment:
  ```bash
  cd public && ln -sfn ../storage/app/public storage || true
  ```
  Trik ini berhasil membuat folder link storage tanpa melewati interpreter PHP sama sekali.

### B. Otomatisasi Dynamic HTTP Basic Auth di Staging
* **Kendala**: Lingkungan Staging harus tertutup dari umum agar tidak diindeks mesin pencari Google atau diakses sembarang pihak.
* **Solusi Rekayasa**: Workflow GitHub Actions secara dinamis membuat hash password Apache menggunakan OpenSSL sebelum proses transfer berkas (rsync):
  ```bash
  HTPASSWD_HASH=$(openssl passwd -apr1 "${{ secrets.STAGING_AUTH_PASS }}")
  echo "${{ secrets.STAGING_AUTH_USER }}:${HTPASSWD_HASH}" > public/.htpasswd
  sed -i "1i AuthType Basic\nAuthName \"Restricted Staging Access\"\nAuthUserFile /home/u849825724/domains/sranak.com/public_html/simkodes-staging/public/.htpasswd\nRequire valid-user\n" public/.htaccess
  ```

### C. Port Kustom SSH `65002` & Multi-Secret Fallback
* **Kendala**: Hostinger menggunakan custom port `65002` (bukan port 22 standar). Inkonsistensi penamaan secret di GitHub Actions kerap memicu error `Bad port '-H'`.
* **Solusi Rekayasa**: Deklarasi job-level environment variables dengan fallback cerdas:
  ```yaml
  env:
    SSH_PORT: ${{ secrets.HOSTINGER_SSH_PORT || secrets.SSH_PORT || '65002' }}
    SSH_HOST: ${{ secrets.HOSTINGER_SSH_HOST || secrets.SSH_HOST || '195.35.48.228' }}
    SSH_USER: ${{ secrets.HOSTINGER_SSH_USER || secrets.SSH_USER || 'u849825724' }}
  ```
  Ini menjamin pipeline tidak pernah gagal meskipun secret port kosong atau salah nama.

---

## 3. Matriks Lingkungan & Direktori Server

| Parameter | Staging Server | Production Server |
| :--- | :--- | :--- |
| **URL Akses** | `https://simkodes-staging.sranak.com` | `https://simkodes.sranak.com` |
| **Path Direktori** | `/home/u849825724/domains/sranak.com/public_html/simkodes-staging/` | `/home/u849825724/domains/sranak.com/public_html/simkodes/` |
| **Proteksi Akses** | HTTP Basic Auth `.htpasswd` | Publik & Pengurus Terdaftar |
| **Mekanisme Rilis** | Otomatis setiap push ke `master` / `staging` | Manual dispatch dengan input wajib `"DEPLOY"` |
| **Database** | `u849825724_simkodes_staging` | `u849825724_simkodes_prod` |
| **Caching Engine** | `php artisan optimize` | `php artisan optimize` |
