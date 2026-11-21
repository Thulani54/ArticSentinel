#!/usr/bin/env bash
set -euo pipefail

echo "Preparing the Luthando Flutter development environment..."
flutter --version
flutter pub get
flutter doctor --verbose

cat <<'EOF'

Environment ready.
Start the web app with:
  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
EOF
