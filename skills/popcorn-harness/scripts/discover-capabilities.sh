#!/usr/bin/env bash
# discover-capabilities.sh — Discover available skills, agents, and commands.
# Outputs structured JSON to stdout. Silently skips unavailable sources.
# Requires bash 3.x+ (not POSIX sh).
#
# Usage: bash discover-capabilities.sh [--platform claude-code|hermes|openclaw]
# Output: {"platform":"...","skills":[...],"agents":[...],"commands":[...],"sources":[...],"errors":[...]}

set -uo pipefail

PLATFORM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      if [[ $# -lt 2 ]]; then
        printf '{"error":"--platform requires a value"}\n' >&2; exit 1
      fi
      PLATFORM="${2}"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate platform if explicitly provided
if [[ -n "$PLATFORM" ]]; then
  case "$PLATFORM" in
    claude-code|hermes|openclaw) ;;
    *)
      printf '{"error":"unknown platform: %s. Expected: claude-code|hermes|openclaw"}\n' "$PLATFORM" >&2
      exit 1
      ;;
  esac
fi

# Auto-detect platform if not provided
if [[ -z "$PLATFORM" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  detection="$(bash "$SCRIPT_DIR/detect-platform.sh" 2>/dev/null || printf '{"platform":"hermes"}')"
  # Extract platform from JSON — anchored to "platform" key to avoid false matches in evidence array
  PLATFORM="$(printf '%s' "$detection" | grep -o '"platform":"[^"]*"' | head -1 | cut -d'"' -f4)"
  if [[ -z "$PLATFORM" ]]; then
    PLATFORM="hermes"
    ERRORS+=("detect-platform.sh returned unparseable output; defaulting to hermes")
  fi
fi

# JSON-safe string escaping (bash 3.x compatible)
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# Dedup tracking via tmp file (bash 3.x: no associative arrays)
TMPDIR_DEDUP="$(mktemp -d)" || {
  printf '{"error":"mktemp failed: cannot create temp dir"}\n' >&2
  exit 1
}
trap 'rm -rf "$TMPDIR_DEDUP"' EXIT INT TERM
_seen_file="$TMPDIR_DEDUP/seen"
touch "$_seen_file"

is_seen() { grep -qxF "$1:$(json_escape "$2")" "$_seen_file" 2>/dev/null; }
mark_seen() { printf '%s\n' "$1:$(json_escape "$2")" >> "$_seen_file"; }

SKILLS=()
AGENTS=()
COMMANDS=()
SOURCES=()
ERRORS=()

add_skill() {
  local name; name="$(json_escape "$1")"
  local src;  src="$(json_escape "$2")"
  is_seen "skill" "$1" && return 0
  mark_seen "skill" "$1"
  SKILLS+=("{\"name\":\"$name\",\"source\":\"$src\"}")
}
add_agent() {
  local name; name="$(json_escape "$1")"
  local src;  src="$(json_escape "$2")"
  is_seen "agent" "$1" && return 0
  mark_seen "agent" "$1"
  AGENTS+=("{\"name\":\"$name\",\"source\":\"$src\"}")
}
add_cmd() {
  local name; name="$(json_escape "$1")"
  local src;  src="$(json_escape "$2")"
  is_seen "cmd" "$1" && return 0
  mark_seen "cmd" "$1"
  COMMANDS+=("{\"name\":\"$name\",\"source\":\"$src\"}")
}

# ─── Claude Code discovery ───────────────────────────────────────────────────
if [[ "$PLATFORM" == "claude-code" ]]; then

  # Agents via CLI (primary)
  # Output format: "  agent-name · model" with header lines like "User agents:"
  if command -v claude > /dev/null 2>&1; then
    agents_before=${#AGENTS[@]}
    while IFS= read -r line; do
      # ltrim whitespace
      line="${line#"${line%%[![:space:]]*}"}"
      # skip empty lines, count lines ("N active agents"), header lines ending with ":"
      [[ -z "$line" ]] && continue
      [[ "$line" =~ ^[0-9]+\ active ]] && continue
      [[ "$line" == *":" ]] && continue
      # strip " · model" suffix and any trailing whitespace
      name="${line%% ·*}"
      name="${name%% }"
      [[ -z "$name" ]] && continue
      add_agent "$name" "claude-cli"
    done < <(claude agents 2>/dev/null || true)
    [[ ${#AGENTS[@]} -gt $agents_before ]] && SOURCES+=("claude-agents-cli")
  fi

  # Agents via filesystem (fallback + supplement)
  for agents_dir in "$HOME/.claude/agents" "./agents" ".claude/agents"; do
    [[ -d "$agents_dir" ]] || continue
    agents_before=${#AGENTS[@]}
    while IFS= read -r f; do
      add_agent "$(basename "$f" .md)" "fs:$agents_dir"
    done < <(find "$agents_dir" -maxdepth 2 -name "*.md" -not -name ".*" 2>/dev/null || true)
    [[ ${#AGENTS[@]} -gt $agents_before ]] && SOURCES+=("agents-dir:$(json_escape "$agents_dir")")
  done

  # Skills — ECC marketplace, user-level, project-level, all plugin skills
  while IFS= read -r skills_dir; do
    [[ -d "$skills_dir" ]] || continue
    skills_before=${#SKILLS[@]}
    while IFS= read -r d; do
      [[ -f "$d/SKILL.md" ]] && add_skill "$(basename "$d")" "fs:$skills_dir"
    done < <(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)
    [[ ${#SKILLS[@]} -gt $skills_before ]] && SOURCES+=("skills-dir:$(json_escape "$skills_dir")")
  done < <(
    printf '%s\n' \
      "$HOME/.claude/plugins/marketplaces/ecc/skills" \
      "$HOME/.claude/skills" \
      ".claude/skills"
    find "$HOME/.claude/plugins" -maxdepth 4 -type d -name "skills" 2>/dev/null || true
  )

  # Commands
  for cmd_dir in "$HOME/.claude/commands" ".claude/commands"; do
    [[ -d "$cmd_dir" ]] || continue
    cmds_before=${#COMMANDS[@]}
    while IFS= read -r f; do
      add_cmd "$(basename "$f" .md)" "fs:$cmd_dir"
    done < <(find "$cmd_dir" -maxdepth 2 -name "*.md" -not -name ".*" 2>/dev/null || true)
    [[ ${#COMMANDS[@]} -gt $cmds_before ]] && SOURCES+=("commands-dir:$(json_escape "$cmd_dir")")
  done

# ─── Hermes / OpenClaw ────────────────────────────────────────────────────────
else
  SOURCES+=("system-prompt-injection")
  ERRORS+=("hermes-openclaw: capabilities are in available_skills context -- read them from the injected system prompt, not this script.")
fi

# ─── JSON output ─────────────────────────────────────────────────────────────
join_obj_arr() {
  local result="["
  local first=1
  for v in "$@"; do
    [[ $first -eq 0 ]] && result+=","
    result+="$v"
    first=0
  done
  result+="]"
  printf '%s' "$result"
}
join_str_arr() {
  local result="["
  local first=1
  for v in "$@"; do
    [[ $first -eq 0 ]] && result+=","
    result+="\"$(json_escape "$v")\""
    first=0
  done
  result+="]"
  printf '%s' "$result"
}

printf '{"platform":"%s","skills":%s,"agents":%s,"commands":%s,"sources":%s,"errors":%s}\n' \
  "$(json_escape "$PLATFORM")" \
  "$(join_obj_arr "${SKILLS[@]+"${SKILLS[@]}"}")" \
  "$(join_obj_arr "${AGENTS[@]+"${AGENTS[@]}"}")" \
  "$(join_obj_arr "${COMMANDS[@]+"${COMMANDS[@]}"}")" \
  "$(join_str_arr "${SOURCES[@]+"${SOURCES[@]}"}")" \
  "$(join_str_arr "${ERRORS[@]+"${ERRORS[@]}"}")"
