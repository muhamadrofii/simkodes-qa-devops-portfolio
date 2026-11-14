# Root Cause Analysis (RCA): BUG-002

**ID**: BUG-002  
**Title**: `HTTP 500 in DashboardController: Call to unsupported DATE_FORMAT function in SQLite CI runner`  
**Severity**: High (CI Pipeline Blocker)  
**Environment**: GitHub Actions Ubuntu Runner (PHPUnit Test Suite)  
**Investigator**: Muhamad Rofii  

---

## 1. Problem Description
The CI workflow failed during the test step:
```text
FAIL Tests\Feature\AuthTest > authenticated user can access dashboard
Expected response status code [200] but received 500.
```
Tests passed locally on MySQL 8.0, but consistently returned HTTP 500 inside the GitHub Actions runner which uses SQLite for in-memory test execution.

---

## 2. Root Cause
In `DashboardController.php`, monthly member growth was calculated using MySQL's native `DATE_FORMAT()` function:
```php
Member::selectRaw("DATE_FORMAT(created_at, '%Y-%m') as month, count(*) as count")
    ->groupBy('month')
    ->get();
```
SQLite does not support `DATE_FORMAT()`; it uses `strftime('%Y-%m', created_at)` instead. When the query ran against SQLite in the CI environment, the database engine threw an unrecognized function error.

---

## 3. Resolution
Added dynamic database driver detection using `DB::connection()->getDriverName()`:

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

## 4. Verification
- `Tests\Feature\AuthTest > authenticated user can access dashboard`: Passed (HTTP 200) on the SQLite CI runner.
- The MySQL queries on Staging and Production continue using native `DATE_FORMAT()` without behavioral change.
