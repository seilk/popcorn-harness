#!/usr/bin/env bash
# detect-platform.sh — Detect current runtime platform for popcorn-harness.
# Outputs a single JSON object to stdout. Never halts; always returns a result.
# Requires bash 3.x+ (not POSIX sh).
#
# Usage: bash detect-platform.sh
# Output: {"platform":"claude-code"|"hermes"|"openclaw","scope":"project"|"user"|"unknown","evidence":[...]}

set -uo pipefail

PLATFORM="hermes"
SCOPE="unknown"
EVIDENCE=()

# --- Claude Code detection ---
if command -v claude > /dev/null 2>&1; then
  PLATFORM="claude-code"
  EVIDENCE+=("claude-cli-found")

  if [ -d ".claude" ]; then
    SCOPE="project"
    EVIDENCE+=("dot-claude-dir-exists")
  else
    SCOPE="user"
    EVIDENCE+=("no-dot-claude-dir")
  fi
fi

# --- OpenClaw detection (overrides hermes if signals present) ---
if [ "$PLATFORM" != "claude-code" ]; then
  if [ -n "${OPENCLAW:-}" ]; then
    PLATFORM="openclaw"
    EVIDENCE+=("OPENCLAW-env-set")
  fi
  if [ -n "${OPENCLAW_RUNTIME:-}" ]; then
    PLATFORM="openclaw"
    EVIDENCE+=("OPENCLAW_RUNTIME-env-set")
  fi
fi

# --- JSON-safe string escaping (bash 3.x compatible) ---
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# --- Build JSON evidence array ---
EVIDENCE_JSON="["
first=1
for item in "${EVIDENCE[@]+"${EVIDENCE[@]}"}"; do
  [ "$first" -eq 0 ] && EVIDENCE_JSON+=","
  EVIDENCE_JSON+="\"$(json_escape "$item")\""
  first=0
done
EVIDENCE_JSON+="]"

printf '{"platform":"%s","scope":"%s","evidence":%s}\n' \
  "$(json_escape "$PLATFORM")" "$(json_escape "$SCOPE")" "$EVIDENCE_JSON"
