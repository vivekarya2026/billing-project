#!/usr/bin/env bash
# run.sh — build + serve the Flutter web app in one step.
# Usage:
#   ./run.sh            # build (if needed) and serve on http://localhost:3012
#   ./run.sh --rebuild  # force a clean rebuild, then serve
#
# The app runs in offline demo mode (BYPASS_AUTH=true), so no Supabase/AI
# backend is required — it auto-logs in and uses seeded demo bills.

set -euo pipefail

PORT="${PORT:-3012}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND="$ROOT/frontend"
WEB="$FRONTEND/build/web"

export PATH="$HOME/flutter/bin:$PATH"

echo "▶ Billing Project — build & serve"
echo "  frontend: $FRONTEND"
echo "  port:     $PORT"

# ── 1. Build if missing, or when --rebuild is passed ──────────────────────
if [[ "${1:-}" == "--rebuild" || ! -f "$WEB/main.dart.js" ]]; then
  echo "▶ Building web bundle (offline demo mode)…"
  cd "$FRONTEND"
  [[ "${1:-}" == "--rebuild" ]] && rm -rf build/web
  flutter build web --dart-define=BYPASS_AUTH=true
else
  echo "▶ Reusing existing build at $WEB (pass --rebuild to force a fresh build)."
fi

# ── 2. Free the port, then serve in the foreground ────────────────────────
echo "▶ Freeing port $PORT (if in use)…"
lsof -ti:"$PORT" | xargs kill -9 2>/dev/null || true

echo ""
echo "✅ Serving at:  http://localhost:$PORT"
echo "   (Press Ctrl+C to stop.)"
echo ""

# Foreground server — stays alive as long as this script runs.
cd "$WEB"
exec python3 -m http.server "$PORT"
