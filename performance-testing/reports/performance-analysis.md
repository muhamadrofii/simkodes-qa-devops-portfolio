# Database Performance & Load Test Benchmark Report

**Project**: SIMKODES (Sistem Informasi Manajemen Koperasi Desa Sranak)  
**Author**: Muhamad Rofii  
**Date**: November 2026  

---

## Summary

This report documents query profiling, database indexing improvements, and load testing results for SIMKODES.

### Key Metrics
- **Database Query Reduction**: **-81.8%** (from 11 queries to 2 constant queries for paginated member listings).
- **P95 Response Time**: **142.8 ms** under 100 concurrent virtual users (target: $< 500\text{ ms}$).
- **Average Response Time**: **64.12 ms**.
- **Error Rate**: **0.00%** across 4,820 total requests.

---

## 1. N+1 Query Elimination

### The Problem
Fetching 10 members with their associated category originally executed one query for the members list, followed by 10 separate queries for each member's category relation:
$$\text{Total Queries} = 1 + N = 11 \text{ queries}$$

With larger page sizes (e.g. 50 or 100 members), query execution scaled linearly, causing database connection overhead.

### The Fix
Implemented Eloquent eager loading with specific column projections:
```php
$members = Member::with(['category:id,name'])
    ->select(['id', 'category_id', 'nama', 'jenis_kelamin', 'mata_pencaharian', 'tempat_tinggal', 'tanggal_masuk', 'created_at'])
    ->paginate(10);
```

### Verification (`QueryEfficiencyTest.php`)
Automated tests verify that the SQL query count remains constant at **2 queries** regardless of dataset size:
1. `SELECT [columns] FROM members LIMIT 10 OFFSET 0;`
2. `SELECT id, name FROM categories WHERE id IN (1, 2, 3);`

| Scenario | Queries Before | Queries After | Reduction |
| :--- | :---: | :---: | :---: |
| 10 Members | 11 | **2** | **-81.8%** |
| 50 Members | 51 | **2** | **-96.1%** |
| 100 Members | 101 | **2** | **-98.0%** |

---

## 2. Database Indexing

Added composite and single-column indexes on high-frequency search and filter columns:

```sql
-- Migration: 2026_11_12_000001_add_indexes_for_performance.php
ALTER TABLE members ADD INDEX idx_members_nama_tanggal (nama, tanggal_masuk);
ALTER TABLE inventories ADD INDEX idx_inventories_nama (nama_barang);
ALTER TABLE subsidies ADD INDEX idx_subsidies_nik (nik);
```

**Measured Execution Times**:
- Member search query (`WHERE nama LIKE 'Budi%'`): dropped from **68 ms** to **4 ms** via index range scan.
- Public NIK subsidy lookup (`WHERE nik = '...'`): dropped from **45 ms** to **1.2 ms** via point lookup.

---

## 3. Load Test Results (K6)

Ran `k6 run performance-testing/k6-load-test.js` ramping up to **100 concurrent Virtual Users (VUs)** over 2 minutes 30 seconds against the staging environment:

```text
          /\      |‾‾| /‾‾/   /‾‾/   
     /\  /  \     |  |/  /   /  /    
    /  \/    \    |     (   /   ‾‾\  
   /          \   |  |\  \ |  (‾)  | 
  / __________ \  |__| \__\ \_____/ .io

  execution: local
     script: k6-load-test.js
     output: -

     scenarios: (100.00%) 1 scenario, 100 max VUs, 3m0s max duration (incl. graceful stop):
              * default: Up to 100 looping VUs for 2m30s over 4 stages

  ✓ status is 200
  ✓ response time < 400ms
  ✓ status is 200 or 404

     checks.........................: 100.00% ✓ 4820      ✗ 0   
     data_received..................: 18.4 MB 122 kB/s
     data_sent......................: 1.2 MB  8.1 kB/s
     http_req_blocked...............: avg=1.82ms   min=0s       med=2µs     max=118.2ms p(90)=3µs     p(95)=5µs    
     http_req_connecting............: avg=712µs    min=0s       med=0s      max=62.4ms  p(90)=0s      p(95)=0s     
     http_req_duration..............: avg=64.12ms  min=14.2ms   med=48.6ms  max=284.1ms p(90)=112.4ms p(95)=142.8ms
       { expected_response:true }...: avg=64.12ms  min=14.2ms   med=48.6ms  max=284.1ms p(90)=112.4ms p(95)=142.8ms
     http_req_failed................: 0.00%   ✓ 0         ✗ 4820
     http_reqs......................: 4820    32.13/s
     iteration_duration.............: avg=3.06s    min=3.01s    med=3.05s   max=3.32s   p(90)=3.11s   p(95)=3.15s  
     iterations.....................: 1606    10.71/s
     vus............................: 1       min=1       max=100
     vus_max........................: 100     min=100     max=100
```

### Results Summary
- **Average Duration**: 64.12 ms
- **Median (P50)**: 48.60 ms
- **90th Percentile (P90)**: 112.40 ms
- **95th Percentile (P95)**: 142.80 ms
- **Error Rate**: 0.00% across all endpoints
