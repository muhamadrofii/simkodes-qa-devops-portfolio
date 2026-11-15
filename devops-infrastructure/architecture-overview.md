# DevOps Infrastructure & Shared Hosting Workarounds

**System**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Target Environment**: Hostinger LiteSpeed Shared Hosting  
**Maintainer**: Muhamad Rofii  

---

## 1. Environment Architecture

The deployment topology uses three distinct environments: Local development, Staging for pre-production verification, and Live Production.

```mermaid
flowchart TD
    subgraph Local Development
        LOCAL_DEV["Developer Workstation"]
        DOCKER["Docker Compose (PHP 8.2 + MySQL 8.0 + phpMyAdmin)"]
        TEST_LOCAL["Local Test Execution (PHPUnit + Playwright)"]
        LOCAL_DEV --> DOCKER
        LOCAL_DEV --> TEST_LOCAL
    end

    subgraph GitHub Actions CI/CD
        GIT_PUSH["Push / PR to master or staging"]
        CI_JOB["ci.yml (SQLite In-Memory Runner)"]
        SEC_JOB["security.yml (Composer & NPM Audit)"]
        GIT_PUSH --> CI_JOB
        GIT_PUSH --> SEC_JOB
    end

    subgraph Hostinger Staging
        STAGING_DEPLOY["staging.yml (CD Pipeline)"]
        BASIC_AUTH["Dynamic OpenSSL Basic Auth (.htpasswd)"]
        STAGING_HOST["simkodes-staging.sranak.com"]
        CI_JOB -->|Pass| STAGING_DEPLOY
        STAGING_DEPLOY --> BASIC_AUTH
        BASIC_AUTH --> STAGING_HOST
    end

    subgraph Hostinger Production
        PROD_GATE["production.yml (Requires manual 'DEPLOY' input)"]
        PROD_HOST["simkodes.sranak.com"]
        PROD_GATE --> PROD_HOST
    end
```

---

## 2. Shared Hosting Constraints & Technical Workarounds

Hostinger shared hosting runs on LiteSpeed Enterprise without root access, custom daemons, or container runtimes. The following technical workarounds were implemented:

### A. Storage Symlink Workaround
* **Constraint**: Hostinger disables `symlink()` in `php.ini` for security reasons. Running `php artisan storage:link` throws `Call to undefined function Illuminate\Filesystem\symlink()`.
* **Fix**: The CI/CD post-deployment script creates the symlink directly via the Linux shell over SSH:
  ```bash
  cd public && ln -sfn ../storage/app/public storage || true
  ```
  This creates the symbolic link at the OS filesystem level without invoking PHP's disabled function.

### B. Dynamic HTTP Basic Auth on Staging
* **Constraint**: The staging site must be restricted from public access and search engine crawlers without hardcoding plaintext credentials in Git.
* **Fix**: The `staging.yml` workflow generates an Apache-compatible `.htpasswd` file using OpenSSL before rsyncing:
  ```bash
  HTPASSWD_HASH=$(openssl passwd -apr1 "${{ secrets.STAGING_AUTH_PASS }}")
  echo "${{ secrets.STAGING_AUTH_USER }}:${HTPASSWD_HASH}" > public/.htpasswd
  sed -i "1i AuthType Basic\nAuthName \"Restricted Staging Access\"\nAuthUserFile /home/u849825724/domains/sranak.com/public_html/simkodes-staging/public/.htpasswd\nRequire valid-user\n" public/.htaccess
  ```

### C. SSH Port 65002 & Secret Fallback
* **Constraint**: Hostinger uses port `65002` for SSH connections. Missing or inconsistently named GitHub secrets can cause `ssh-keyscan` to fail with `Bad port '-H'`.
* **Fix**: Workflows declare job-level environment variables with fallback values:
  ```yaml
  env:
    SSH_PORT: ${{ secrets.HOSTINGER_SSH_PORT || secrets.SSH_PORT || '65002' }}
    SSH_HOST: ${{ secrets.HOSTINGER_SSH_HOST || secrets.SSH_HOST || '195.35.48.228' }}
    SSH_USER: ${{ secrets.HOSTINGER_SSH_USER || secrets.SSH_USER || 'u849825724' }}
  ```
  This ensures `ssh-keyscan` always receives a valid port integer and host string.

### D. Pre-Deployment Automatic Database Snapshot (Zero Data Loss)
* **Constraint**: Live production upgrades must guarantee zero data loss with instant rollback capability if a schema migration fails.
* **Fix**: Before rsyncing code or running migrations, the pipeline SSHs into the server and creates an automated compressed dump:
  ```bash
  mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > ~/backups/pre_deploy_$(date +%Y%m%d_%H%M%S).sql.gz
  ```

### E. Self-Healing Environment Recovery (.env Protection)
* **Constraint**: During infrastructure migrations or folder reorganizations (e.g., migrating from `core/` to `/public_html/simkodes/`), missing `.env` files cause HTTP 500 errors.
* **Fix**: The post-deploy automation script verifies and auto-recovers the environment file:
  ```bash
  if [ ! -f .env ]; then
    if [ -f /home/u849825724/domains/sranak.com/public_html/core/.env ]; then
      cp /home/u849825724/domains/sranak.com/public_html/core/.env .env
    elif [ -f .envprod ]; then
      cp .envprod .env
    fi
  fi
  ```

### F. Branded SIMKODES Maintenance Pre-Rendering (HTTP 503)
* **Constraint**: Unstyled 503 text ("503 | Service Unavailable") degrades user trust during schema migration.
* **Fix**: The pipeline activates maintenance with `--render="errors.503"`:
  ```bash
  php artisan down --render="errors.503" || true
  ```
  This serializes a fully styled, self-contained HTML page into `storage/framework/down`, served instantly by LiteSpeed with a rotating cog animation and a 30-second countdown auto-refresh.

---

## 3. Environment Matrix

| Parameter | Staging Environment | Production Environment |
| :--- | :--- | :--- |
| **URL** | `https://simkodes-staging.sranak.com` | `https://simkodes.sranak.com` |
| **Server Directory** | `/home/u849825724/domains/sranak.com/public_html/simkodes-staging/` | `/home/u849825724/domains/sranak.com/public_html/simkodes/` *(Migrated from `core/`)* |
| **Access Control** | HTTP Basic Auth (`.htpasswd`) | Public & Authenticated Users |
| **Release Trigger** | Automatic on push to `master` or `staging` | Manual `workflow_dispatch` with confirmation input `"DEPLOY"` |
| **Database** | `u849825724_simkodes_staging` | `u849825724_kdmp` *(Hostinger MySQL, 0% data loss)* |
| **Optimization** | `php artisan optimize` | `php artisan optimize` |
