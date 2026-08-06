/**
 * Stress: keep raising VUs to find the breaking point (errors / latency cliff).
 *
 *   k6 run stress.js
 *   k6 run -e BASE_URL=https://api.alrasmarketapp.com stress.js
 *
 * Do NOT run against production at peak traffic. Watch server CPU/RAM
 * (docker stats) while this runs.
 *
 * Capacity hint: highest VU stage where http_req_failed stays low and
 * p(95) http_req_duration is still acceptable.
 */
import { stressThresholds } from './lib/config.js';
import { browseJourney } from './lib/journey.js';

export const options = {
  scenarios: {
    stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '2m', target: 100 },
        { duration: '2m', target: 200 },
        { duration: '2m', target: 300 },
        { duration: '2m', target: 400 },
        { duration: '2m', target: 500 },
        { duration: '2m', target: 500 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '1m',
    },
  },
  thresholds: stressThresholds,
};

export default function () {
  browseJourney();
}
