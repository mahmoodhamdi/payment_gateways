#!/usr/bin/env bash
# Spin up the backend companion and the template app together for local
# development.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f backend_companion/.env.local ]; then
  echo "Bootstrapping backend_companion/.env.local from .env.example"
  cp backend_companion/.env.example backend_companion/.env.local
  echo ""
  echo "⚠️  Fill in the gateway secrets in backend_companion/.env.local"
  echo "    before running this script again."
  exit 1
fi

# Start backend in background.
(
  cd backend_companion
  if [ ! -d node_modules ]; then
    npm install
  fi
  echo "▶️  Starting backend on :4000"
  npm run dev
) &
BACKEND_PID=$!

trap "kill $BACKEND_PID 2>/dev/null || true" EXIT INT TERM

# Wait for backend to be healthy.
echo "Waiting for backend health…"
for _ in $(seq 1 30); do
  if curl -sf http://localhost:4000/health > /dev/null; then
    echo "✅ backend healthy"
    break
  fi
  sleep 1
done

# Start the template app.
cd template_app
echo "▶️  Starting template_app"
flutter pub get
flutter run
