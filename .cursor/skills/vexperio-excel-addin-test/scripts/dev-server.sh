#!/usr/bin/env bash
# Start (or restart) the Vite dev server for observable local Excel testing.
# Usage: ./scripts/dev-server.sh [stop|status]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)/excel-addin"
PORT=3000

stop() {
  local pids
  pids="$(lsof -ti:"$PORT" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    echo "Stopping process(es) on :$PORT — $pids"
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 1
  fi
  if lsof -ti:"$PORT" >/dev/null 2>&1; then
    echo "ERROR: port $PORT still in use" >&2
    exit 1
  fi
  echo "Port $PORT is free."
}

status() {
  if lsof -ti:"$PORT" >/dev/null 2>&1; then
    echo "RUNNING on https://localhost:$PORT/"
    curl -sk -o /dev/null -w "  dialog.html HTTP %{http_code}\n" "https://localhost:$PORT/dialog.html" || true
  else
    echo "NOT RUNNING (port $PORT free)"
  fi
}

case "${1:-start}" in
  stop)
    stop
    ;;
  status)
    status
    ;;
  start)
    stop
    echo "Starting Vite in $ROOT (logs to stdout)…"
    cd "$ROOT"
    exec npm run dev
    ;;
  *)
    echo "Usage: $0 [start|stop|status]" >&2
    exit 2
    ;;
esac
