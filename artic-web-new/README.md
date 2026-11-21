# artic-web-new

React rebuild of the ArticSentinel web client (Vite + React 18), talking to the
same Django API at `api.articsentinel.com` as the Flutter app.

## Run

```bash
npm install
npm run dev        # http://localhost:5173 — /api proxied to the live backend
npm run build      # production bundle in dist/
npm run preview    # serve the production build locally
```

## UAT deployment

`https://uat.articsentinel.com` is served by nginx from
`/var/www/uat.articsentinel.com`. Build with `npm run build`, then publish the
contents of `dist/` to that directory using your normal deployment process.
Preserve the `/api/` backend proxy and SPA history fallback. No backend migrations
are needed for the redesign.

## Redesign

All routes share the responsive monitoring workspace, persistent desktop navigation,
mobile drawer, accessible focus states, refreshed forms, data tables and status colours.
The dashboard adds equipment search, connectivity filters, and temperature/reporting
graphs from the production `dashboard-data/` endpoint. Select equipment and Today or
7 days; absent telemetry is shown as missing rather than zero. Expand View chart data
for a tabular alternative. The sign-in page has a custom cold-storage illustration.

`npm test` verifies telemetry normalization, device scoping and sensor selection.

## What's rebuilt

- **Auth** — email/password against `POST /api/login/`, DRF token held in
  localStorage (`artic_auth`), logout.
- **Dashboard** — fleet stats (devices, online, gas cylinders, 30-day gas
  alerts) + device grid.
- **Devices** — full table with add / edit / delete against
  `api/devices/create|update|delete/`. The form requires **Floor** (the
  backend column is NOT NULL even though the serializer doesn't validate it —
  an omitted floor 500s).
- **Gas dashboard** — full port of the Flutter `lib/gasmon/` module: SVG
  cylinder gauge, level bands, today usage, 7-day burn projection, 30/60/90-day
  performance charts (daily bars / weekly buckets), alerts, PDF + CSV exports.
  Data is the deterministic demo series (keyed on `device_id`, labelled "DEMO
  DATA") until the backend exposes gas-weight telemetry.
- **Device detail (other types)** — equipment record view; live temperature
  telemetry is a listed follow-up.

## API base

The client calls `/api/...` relative to the page origin. `vite.config.js`
proxies that to `https://api.articsentinel.com` in dev. For a standalone build
served from a different origin than the API, set `VITE_API_BASE` at build time.

## Dashboard telemetry

Legacy dashboard data lives at `https://api.articsentinel.com/dashboard-data/`
(outside `/api/`). `VITE_TELEMETRY_BASE` can override its origin. The backend permits
cross-origin calls; existing token authentication is sent on requests. Today uses
hourly aggregates for the backend's current date; 7 days uses daily aggregates.
Chart timestamps are displayed in the viewer's timezone. Graphs refresh on equipment
selection and with Refresh graphs. No simulated data is used in these charts.
