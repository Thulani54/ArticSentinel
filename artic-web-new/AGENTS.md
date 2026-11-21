# ArticSentinel website

This directory is the React 18 / Vite website deployed to UAT. The repository root contains the Flutter application; do not confuse its build with this website.

## Setup and checks

From the repository root:

- Install: `bash artic-web-new/scripts/codex-setup.sh`
- Test: `npm test --prefix artic-web-new`
- Build: `npm run build --prefix artic-web-new`
- Development server: `npm run dev --prefix artic-web-new -- --host 0.0.0.0 --port 5173`

Node.js 22 is recommended for the cloud environment. Dependencies are pinned by package-lock.json. Tests and builds do not require account credentials or a running backend.

## Data and architecture

- `src/api.js` is the API client. Vite proxies `/api/` to `https://api.articsentinel.com`; dashboard telemetry also uses that origin directly.
- This is a live backend. Use existing account permissions and avoid mutating live equipment during UI checks.
- `src/components/DetailedPerformance.jsx` renders device-type analytics. Empty reading periods retain chart frames but must not plot synthetic zero readings.
- `src/lib/telemetry/` contains normalization and reading-count helpers. Preserve missing values, real zeroes, and negative sensor readings distinctly.
- Backend source is a separate server repository. `backend-patches/` records relevant deployed patches, not a local Django installation.
- Never commit credentials, tokens, private keys, node_modules, or dist. Deployment access is not part of the cloud setup.
- UAT is https://uat.articsentinel.com. Build and validate changes before a requested deployment.
