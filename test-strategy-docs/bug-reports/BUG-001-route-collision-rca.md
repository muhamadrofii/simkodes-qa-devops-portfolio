# Root Cause Analysis (RCA): BUG-001

**ID**: BUG-001  
**Title**: `LogicException: Unable to prepare route [members] for serialization. Another route has already been assigned name [members.index]`  
**Severity**: Critical (Deployment Blocker)  
**Environment**: CI/CD Staging Deployment Pipeline  
**Investigator**: Muhamad Rofii  

---

## 1. Problem Description
During post-deployment execution of `php artisan route:cache`, the command aborted with the following stack trace:
```text
LogicException: Unable to prepare route [members] for serialization. Another route has already been assigned name [members.index].
#0 /vendor/laravel/framework/src/Illuminate/Routing/AbstractRouteCollection.php(247): ...
#5 /vendor/laravel/framework/src/Illuminate/Foundation/Console/RouteCacheCommand.php(109): ...
```
The failure was captured in Sentry Cloud as an unhandled exception during the release pipeline.

---

## 2. Root Cause
A route naming collision occurred between web routes and API routes:
1. **Web Route** (`routes/web.php`):
   ```php
   Route::get('/members', [MemberController::class, 'index'])->name('members.index');
   ```
2. **API Route** (`routes/api.php`):
   ```php
   Route::apiResource('members', MemberController::class);
   ```
   By default, `Route::apiResource('members', ...)` implicitly assigns resource names (`members.index`, `members.store`, `members.show`, etc.).
3. During route caching, Laravel's route collection compiler requires unique route names for serialization. Because two separate routes registered under the name `members.index`, compilation threw a `LogicException`.

---

## 3. Resolution
Scoped all protected API routes under the `api.` name prefix:

```php
// routes/api.php
Route::middleware('auth:sanctum')->name('api.')->group(function () {
    Route::apiResource('members', MemberController::class);
    // Generates: api.members.index, api.members.store, api.members.show, etc.
});
```

---

## 4. Verification
- `php artisan route:cache` executed successfully: `INFO Routes cached successfully.`.
- All 79 PHPUnit tests and 12 Playwright E2E tests passed with zero regressions.
