import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom Metrics
export const errorRate = new Rate('errors');
export const apiResponseTime = new Trend('api_response_time');

// Load Test Configuration: Ramp-up to 50 concurrent users
export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Warm-up
    { duration: '1m', target: 50 },  // Sustained load: 50 Virtual Users
    { duration: '30s', target: 100 }, // Peak load: 100 Virtual Users
    { duration: '30s', target: 0 },   // Cool-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete under 500ms
    http_req_failed: ['rate<0.01'],    // Error rate must be less than 1%
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://simkodes-staging.sranak.com';

export default function () {
  group('1. Public Landing & Informational Pages', function () {
    const res = http.get(`${BASE_URL}/`);
    check(res, {
      'status is 200': (r) => r.status === 200,
      'response time < 400ms': (r) => r.timings.duration < 400,
    }) || errorRate.add(1);
    sleep(1);
  });

  group('2. Public Subsidy NIK Verification', function () {
    const payload = JSON.stringify({
      nik: '3522010101900001',
    });
    const headers = { 'Content-Type': 'application/json' };

    const res = http.post(`${BASE_URL}/cek-subsidi`, payload, { headers });
    apiResponseTime.add(res.timings.duration);
    check(res, {
      'status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    }) || errorRate.add(1);
    sleep(1);
  });

  group('3. RESTful API Member Index (Sanctum)', function () {
    const params = {
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${__ENV.API_TOKEN || 'dummy_test_token'}`,
      },
    };

    const res = http.get(`${BASE_URL}/api/members?page=1`, params);
    apiResponseTime.add(res.timings.duration);
    check(res, {
      'status is 200 or 401': (r) => r.status === 200 || r.status === 401,
    }) || errorRate.add(1);
    sleep(1);
  });
}

