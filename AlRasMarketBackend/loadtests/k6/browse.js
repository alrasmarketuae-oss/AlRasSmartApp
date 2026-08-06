/**
 * Browse / load: ramp 10 → 50 → 100 VUs on the marketplace browse journey.
 *
 *   k6 run browse.js
 *   k6 run -e BASE_URL=https://api.alrasmarketapp.com browse.js
 *   k6 run -e K6_TOKEN=<jwt> browse.js
 *
 * Prefer off-peak if pointing at production.
 */
import { browseThresholds } from './lib/config.js';
import { browseJourney } from './lib/journey.js';

export const options = {
  scenarios: {
    browse_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '2m', target: 50 },
        { duration: '3m', target: 100 },
        { duration: '2m', target: 100 },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: browseThresholds,
};

export default function () {
  browseJourney();
}
