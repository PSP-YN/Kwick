import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.KWICK_API_URL;
const anonKey = __ENV.KWICK_SUPABASE_ANON_KEY;
if (!baseUrl || !anonKey) {
  throw new Error('Set KWICK_API_URL and KWICK_SUPABASE_ANON_KEY for a dedicated staging project.');
}

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '2m', target: 100 },
    { duration: '2m', target: 250 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000', 'p(99)<2500'],
  },
};

export default function () {
  const response = http.get(`${baseUrl}/rest/v1/service_categories?select=id,name,slug&is_active=eq.true&order=sort_order.asc`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${anonKey}` },
    tags: { endpoint: 'active-service-categories' },
  });
  check(response, {
    'catalogue read returns 200': (r) => r.status === 200,
    'catalogue response is bounded': (r) => r.body.length < 100000,
  });
  sleep(1);
}
