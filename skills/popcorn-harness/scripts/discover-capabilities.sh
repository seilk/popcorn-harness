#!/usr/bin/env bash
# discover-capabilities.sh — Discover available skills, agents, and commands.
# Outputs structured JSON to stdout. Silently skips unavailable sources.
#
# Usage: bash discover-capabilities.sh [--platform claude-code|hermes|openclaw]
# Output: {"skills":[...],"agents":[...],"commands":[...],"sources":[...],"errors":[...]}

set -uo pipefail

PLATFORM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  detection="$(bash "$SCRIPT_DIR/detect-platform.sh" 2>/dev/null || echo '{"platform":"hermes"}')"
  PLATFORM="$(echo "$detection" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)"
fi

SKILLS=()
AGENTS=()
COMMANDS=()
SOURCES=()
ERRORS=()

# Helper: add item to array as JSON string
add_skill() { SKILLS+=("$(printf '{"name":"%s","source":"%s"}' "$1" "$2")"); }
add_agent() { AGENTS+=("$(printf '{"name":"%s","source":"%s"}' "$1" "$2")"); }
add_cmd()   { COMMANDS+=("$(printf '{"name":"%s","source":"%s"}' "$1" "$2")"); }

# ─── Claude Code discovery ───────────────────────────────────────────────────
if [ "$PLATFORM" = "claude-code" ]; then

  # Agents via CLI (primary)
  if command -v claude > /dev/null 2>&1; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      add_agent "$line" "claude-cli"
    done < <(claude agents 2>/dev/null || true)
    SOURCES+=("claude-agents-cli")
  fi

  # Agents via filesystem (fallback + supplement)
  for agents_dir in "$HOME/.claude/agents" "./agents" ".claude/agents"; do
    if [ -d "$agents_dir" ]; then
      while IFS= read -r f; do
        name="$(basename "$f" .md)"
        add_agent "$name" "fs:$agents_dir"
      done < <(find "$agents_dir" -name "*.md" -not -name ".*" 2>/dev/null || true)
      SOURCES+=("agents-dir:$agents_dir")
    fi
  done

  # Skills
  for skills_dir in \
    "$HOME/.claude/plugins/marketplaces/ecc/skills" \
    "$HOME/.claude/skills" \
    ".claude/skills"
  do
    if [ -d "$skills_dir" ]; then
      while IFS= read -r d; do
        name="$(basename "$d")"
        [ -f "$d/SKILL.md" ] && add_skill "$name" "fs:$skills_dir"
      done < <(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)
      SOURCES+=("skills-dir:$skills_dir")
    fi
  done

  # Commands
  for cmd_dir in "$HOME/.claude/commands" ".claude/commands"; do
    if [ -d "$cmd_dir" ]; then
      while IFS= read -r f; do
        name="$(basename "$f" .md)"
        add_cmd "$name" "fs:$cmd_dir"
      done < <(find "$cmd_dir" -name "*.md" -not -name ".*" 2>/dev/null || true)
      SOURCES+=("commands-dir:$cmd_dir")
    fi
  done

# ─── Hermes / OpenClaw discovery ─────────────────────────────────────────────
else
  # Hermes/OpenClaw: capabilities are injected via available_skills in system prompt.
  # This script signals that to the LLM — actual extraction happens in SKILL.md logic.
  SOURCES+=("system-prompt-injection")
  ERRORS+=("hermes-openclaw: read available_skills from context — cannot enumerate via script")
fi

# ─── Build output JSON ───────────────────────────────────────────────────────
join_array() {
  local arr=("$@")
  local result="["
  for i in "${!arr[@]}"; do
    [ $i -gt 0 ] && result+=","
    result+="${arr[$i]}"
  done
  result+="]"
  echo "$result"
}

str_array() {
  local arr=("$@")
  local result="["
  for i in "${!arr[@]}"; do
    [ $i -gt 0 ] && result+=","
    result+="\"${arr[$i]}\""
  done
  result+="]"
  echo "$result"
}

printf '{"platform":"%s","skills":%s,"agents":%s,"commands":%s,"sources":%s,"errors":%s}\n' \
  "$PLATFORM" \
  "$(join_array "${SKILLS[@]+"${SKILLS[@]}"}")" \
  "$(join_array "${AGENTS[@]+"${AGENTS[@]}"}")" \
  "$(join_array "${COMMANDS[@]+"${COMMANDS[@]}"}")" \
  "$(str_array "${SOURCES[@]+"${SOURCES[@]}"}")" \
  "$(str_array "${ERRORS[@]+"${ERRORS[@]}"}")"
