# Codex Cloud setup

Repository: `Thulani54/ArticSentinel`
Website branch: `codex/website-redesign`
Suggested environment name: `ArticSentinel Website`
Runtime: universal image, Node.js 22.

Use the following as both the setup and maintenance script in the cloud environment. The conditional supports cache preparation on the repository's default branch, which may not contain the website. Select `codex/website-redesign` when starting a cloud task.

```bash
set -euo pipefail
if [ -f artic-web-new/scripts/codex-setup.sh ]; then
  bash artic-web-new/scripts/codex-setup.sh
elif [ -f artic-web-new/package-lock.json ]; then
  npm ci --prefix artic-web-new --no-audit --no-fund
else
  echo 'Website not present on this checkout. Select codex/website-redesign for website tasks.'
fi
```

No secrets or environment variables are required to install, test, or build. Setup requires npm registry access. Live UI checks additionally need access to `api.articsentinel.com` and an authorized app login; do not put passwords in the setup script. The Flutter sources remain in the repository, but this environment setup installs the website toolchain only.

Validation commands:

```bash
npm test --prefix artic-web-new
npm run build --prefix artic-web-new
```

Preview command:

```bash
npm run dev --prefix artic-web-new -- --host 0.0.0.0 --port 5173
```

Reference: https://learn.chatgpt.com/docs/environments/cloud-environment
