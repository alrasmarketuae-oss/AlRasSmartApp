/**
 * One virtual-user iteration: typical anonymous browse path (+ optional myOrders).
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, SEARCH_Q, authHeaders, TOKEN, okJson } from './config.js';

export function browseJourney() {
  const headers = authHeaders();
  const tags = { journey: 'browse' };

  const health = http.get(`${BASE_URL}/api/health`, { headers, tags: { ...tags, name: 'health' } });
  check(health, {
    'health status 200': (r) => r.status === 200,
    'health body ok-ish': (r) => {
      try {
        const body = r.json();
        return body && (body.status === 'ok' || body.status === 'db_unreachable');
      } catch (_) {
        return false;
      }
    },
  });

  sleep(0.3 + Math.random() * 0.4);

  const products = http.get(`${BASE_URL}/api/Products?page=1&pageSize=20`, {
    headers,
    tags: { ...tags, name: 'products_list' },
  });
  check(products, {
    'products list 200': okJson,
  });

  sleep(0.2 + Math.random() * 0.5);

  const q = encodeURIComponent(SEARCH_Q);
  const suggest = http.get(`${BASE_URL}/api/Products/search-suggest?q=${q}&limit=8`, {
    headers,
    tags: { ...tags, name: 'search_suggest' },
  });
  check(suggest, {
    'search-suggest 200': okJson,
  });

  sleep(0.2 + Math.random() * 0.4);

  const search = http.get(`${BASE_URL}/api/Products/search?q=${q}&page=1&pageSize=20`, {
    headers,
    tags: { ...tags, name: 'search' },
  });
  check(search, {
    'search 200': okJson,
  });

  if (TOKEN) {
    sleep(0.2 + Math.random() * 0.3);
    const orders = http.get(`${BASE_URL}/api/Orders/myOrders?page=1&pageSize=20`, {
      headers,
      tags: { ...tags, name: 'my_orders' },
    });
    check(orders, {
      'myOrders 200 or 401': (r) => r.status === 200 || r.status === 401,
    });
  }

  // Think time between iterations (human-like pause).
  sleep(1 + Math.random() * 2);
}
