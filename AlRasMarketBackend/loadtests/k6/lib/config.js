/**
 * Shared k6 config for Al Ras Market API load tests.
 *
 * Env:
 *   BASE_URL   - API root (default: https://api.alrasmarketapp.com)
 *   K6_TOKEN   - optional Bearer JWT for authenticated reads (myOrders)
 *   SEARCH_Q   - search query (default: هيل)
 */

export const BASE_URL = (
  __ENV.BASE_URL || 'https://api.alrasmarketapp.com'
).replace(/\/$/, '');

export const TOKEN = (__ENV.K6_TOKEN || '').trim();
export const SEARCH_Q = (__ENV.SEARCH_Q || 'هيل').trim();

export const defaultHeaders = {
  Accept: 'application/json',
  'Accept-Language': 'ar',
};

export function authHeaders() {
  if (!TOKEN) return { ...defaultHeaders };
  return {
    ...defaultHeaders,
    Authorization: `Bearer ${TOKEN}`,
  };
}

/** Soft quality gates for browse/load (not stress). */
export const browseThresholds = {
  http_req_failed: ['rate<0.02'],
  http_req_duration: ['p(95)<1500'],
  checks: ['rate>0.95'],
};

/** Smoke gates — catch broken scripts / wrong BASE_URL. */
export const smokeThresholds = {
  http_req_failed: ['rate<0.05'],
  http_req_duration: ['p(95)<3000'],
  checks: ['rate>0.90'],
};

/**
 * Stress: keep collecting metrics; do not fail the run on latency so we can
 * see the breaking point in the summary.
 */
export const stressThresholds = {
  http_req_failed: ['rate<0.15'],
};

export function okJson(res) {
  return res.status === 200;
}
