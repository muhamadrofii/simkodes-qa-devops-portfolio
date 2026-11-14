# Master Test Plan & QA Strategy

**Project**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Author**: Muhamad Rofii  
**Standard**: Agile Testing & Test Pyramid  

---

## 1. Scope of Testing

### In-Scope Features
1. **Authentication & Authorization**: Web session login, password validation, guest redirection, and Sanctum Bearer token API.
2. **Member Management & Digital Cards**: CRUD operations, NIK/name validation, and Dompdf member card (KTA) generation.
3. **Officer & Supervisor Directory**: Cooperative board records, image uploads, digital signatures, and officer card generation.
4. **Letter Archiving**: PDF and image uploads for incoming and outgoing letters.
5. **Inventory & Asset Tracking**: Item catalog, quantity/pricing calculation, and PDF/Excel export.
6. **Subsidies & Public Service**: Beneficiary verification, public NIK lookup, and date-range report filtering.
7. **RESTful API**: Standard JSend responses (`success`, `code`, `message`, `data`, `meta`) with standard HTTP status codes (200, 201, 401, 404, 422).
8. **Database Efficiency**: N+1 query elimination and search index coverage.

---

## 2. Test Pyramid Strategy

```text
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

## 3. Test Environments

| Parameter | Local Testing | CI Runner Testing | Staging (Pre-Prod) | Production |
| :--- | :--- | :--- | :--- | :--- |
| **OS** | Windows 11 / Linux | Ubuntu Latest | Cloud Linux (Hostinger) | Cloud Linux |
| **Database** | MySQL 8.0 & SQLite | SQLite (In-Memory) | MySQL 8.0 (Staging DB) | MySQL 8.0 (Prod DB) |
| **Web Server** | `php artisan serve` | Auto-webserver Playwright | LiteSpeed Enterprise | LiteSpeed Enterprise |
| **Runner** | Developer Machine | GitHub Actions Runner | Hostinger Staging Host | Hostinger Live Host |

---

## 4. Entry & Exit Criteria

### Entry Criteria
- Frontend assets compile successfully (`npm run build`).
- Dependency check passes without critical CVEs (`composer audit --locked` & `npm audit`).
- Database migrations and seeders execute cleanly.

### Exit Criteria
- **100% PHPUnit Test Suite Passing** (79/79 passed, 468 assertions).
- **100% Playwright E2E Suite Passing** (12/12 passed, 7 specs).
- **Zero Blocker / Critical Defects** in issue tracker.
- **N+1 Query Elimination Verified** on all listing endpoints.
- **UAT Sign-off** on the Staging environment.
