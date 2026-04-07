#!/usr/bin/env bash
# detect-platform.sh — Detect current runtime platform for popcorn-harness.
# Outputs a single JSON object to stdout. Never halts; always returns a result.
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
  # Check for openclaw-imports category in environment (set by OpenClaw runtime)
  if [ -n "${OPENCLAW_RUNTIME:-}" ]; then
    PLATFORM="openclaw"
    EVIDENCE+=("OPENCLAW_RUNTIME-env-set")
  fi
fi

# --- Build JSON evidence array ---
EVIDENCE_JSON="["
for i in "${!EVIDENCE[@]}"; do
  [ $i -gt 0 ] && EVIDENCE_JSON+=","
  EVIDENCE_JSON+="\"${EVIDENCE[$i]}\""
done
EVIDENCE_JSON+="]"

printf '{"platform":"%s","scope":"%s","evidence":%s}\n' \
  "$PLATFORM" "$SCOPE" "$EVIDENCE_JSON"
