#!/usr/bin/env bash
set -euo pipefail
web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$web_root"
node --version
npm --version
npm ci --no-audit --no-fund
