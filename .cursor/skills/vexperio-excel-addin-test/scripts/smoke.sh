#!/usr/bin/env bash
# Deploy smoke checks for vexperio-addin static host (from excel-addin/README.md).
# Usage: smoke.sh <BASE_URL>
# Example: smoke.sh https://vexperio-addin-ciffwglwbq-ew.a.run.app

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <BASE_URL>" >&2
  echo "Example: $0 https://vexperio-addin-ciffwglwbq-ew.a.run.app" >&2
  exit 1
fi

URL="${1%/}"
fail=0

check_head() {
  local path="$1"
  local expect="${2:-200}"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -I "${URL}${path}")
  if [[ "$code" != "$expect" ]]; then
    echo "FAIL ${path}: HTTP ${code} (expected ${expect})"
    fail=1
  else
    echo "OK   ${path}: HTTP ${code}"
  fi
}

check_body() {
  local path="$1"
  local needle="$2"
  local body
  body=$(curl -s "${URL}${path}")
  if [[ "$body" != *"$needle"* ]]; then
    echo "FAIL ${path}: body missing '${needle}'"
    fail=1
  else
    echo "OK   ${path}: contains '${needle}'"
  fi
}

echo "Smoke testing ${URL}"
check_head "/dialog.html"
check_head "/icon-32.png"
check_head "/manifest.xml"
check_body "/healthz" "ok"

if [[ $fail -ne 0 ]]; then
  echo "Smoke checks failed."
  exit 1
fi

echo "All smoke checks passed."
