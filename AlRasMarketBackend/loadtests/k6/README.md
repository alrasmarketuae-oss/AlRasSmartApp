# k6 load tests — Al Ras Market API

Measure how many concurrent browse users the backend can serve before latency or errors climb.

## Install k6 (Windows)

```powershell
winget install GrafanaLabs.k6 --accept-package-agreements --accept-source-agreements
```

Restart the terminal, then:

```powershell
k6 version
```

Docs: https://grafana.com/docs/k6/latest/

## Scripts

| File | Purpose |
|------|---------|
| `smoke.js` | 2 VUs ~1 min — verify wiring |
| `browse.js` | Ramp to 100 VUs — realistic load |
| `stress.js` | Ramp to 500 VUs — find breaking point |

Shared journey (per VU iteration):

1. `GET /api/health`
2. `GET /api/Products?page=1&pageSize=20`
3. `GET /api/Products/search-suggest?q=…`
4. `GET /api/Products/search?q=…`
5. Optional: `GET /api/Orders/myOrders` if `K6_TOKEN` is set

AI / SignalR hubs are **not** stressed here (rate limits + OpenAI cost).

## Run

From this folder:

```powershell
cd "AlRasMarketBackend\loadtests\k6"

# Smoke against production API (light)
k6 run smoke.js

# Custom base URL (local docker API)
k6 run -e BASE_URL=http://localhost:8080 smoke.js

# Browse load (prefer off-peak on production)
k6 run browse.js

# Stress (do not run at peak traffic)
k6 run stress.js

# Authenticated myOrders step
k6 run -e K6_TOKEN=eyJhbGciOi... browse.js

# Different search term
k6 run -e SEARCH_Q=cardamom smoke.js
```

## How to read “how many users can we handle?”

After a run, look at the summary:

- **`vus_max` / stage targets** — concurrent virtual users in this browse journey
- **`http_reqs` / duration** — approximate RPS (requests per second)
- **`http_req_failed`** — keep ideally &lt; 1–2% for a “healthy” capacity number
- **`http_req_duration` p(95)** — browse threshold is 1.5s; if p95 climbs hard while RPS flattens, you hit a bottleneck

**Practical capacity:** highest VU level in `browse.js` / `stress.js` where:

- failed rate stays low, and  
- p95 stays acceptable for your product (e.g. &lt; 1.5s)

That number is **concurrent browse sessions**, not daily active users (DAU). Rough rule of thumb: many apps support far more DAU than peak concurrent users.

## Watch the server while testing

On the VPS:

```bash
docker stats alras-api alras-redis alras-nginx alras-meilisearch
```

Also check Prometheus/Grafana if you use them.

## Safety

- Start with `smoke.js` always.
- Avoid heavy `stress.js` on production during peak hours.
- Do not add AI assistant / chat hubs to these scripts without a dedicated low-rate scenario.
- You are responsible for load against live customer traffic.

## Default BASE_URL

`https://api.alrasmarketapp.com` (override with `-e BASE_URL=...`).
