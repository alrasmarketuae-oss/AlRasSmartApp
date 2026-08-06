/**
 * Smoke: 1–2 VUs for ~1 minute — verify endpoints and script wiring.
 *
 *   k6 run smoke.js
 *   k6 run -e BASE_URL=https://api.alrasmarketapp.com smoke.js
 */
import { smokeThresholds } from './lib/config.js';
import { browseJourney } from './lib/journey.js';

export const options = {
  scenarios: {
    smoke: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 2 },
        { duration: '45s', target: 2 },
        { duration: '10s', target: 0 },
      ],
      gracefulRampDown: '5s',
    },
  },
  thresholds: smokeThresholds,
};

export default function () {
  browseJourney();
}
