// agent-kit: k6 smoke/load test. Run: .agent/scripts/kit-run perf   (BASE_URL=http://localhost:8080 by default)
// Thresholds encode the SLO; a failing threshold fails the run.
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    smoke: { executor: 'constant-vus', vus: 5, duration: '30s' },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

const BASE = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  const res = http.get(`${BASE}/health`);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
