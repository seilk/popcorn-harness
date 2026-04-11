#!/usr/bin/env bash
# Tests for commands/popcorn-harness.md path coverage
# RED-GREEN-REFACTOR: run before and after fixes

set -euo pipefail

COMMAND_FILE="$(dirname "$0")/../commands/popcorn-harness.md"
PASS=0
FAIL=0

assert_contains() {
    local description="$1"
    local pattern="$2"
    if grep -qF "$pattern" "$COMMAND_FILE"; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        expected to find: $pattern"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local description="$1"
    local pattern="$2"
    if ! grep -qF "$pattern" "$COMMAND_FILE"; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        should NOT contain: $pattern"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== popcorn-harness command path tests ==="
echo ""

echo "--- Skill lookup paths ---"
# Must include the marketplace install path (the actual installed location)
assert_contains \
    "includes marketplace install path" \
    "~/.claude/plugins/marketplaces/popcorn-harness/skills/popcorn-harness/SKILL.md"

# Must still support manual/legacy install path
assert_contains \
    "includes legacy plugin path" \
    "~/.claude/plugins/popcorn-harness/skills/popcorn-harness/SKILL.md"

# Must support user-level skills dir
assert_contains \
    "includes user skills dir path" \
    "~/.claude/skills/popcorn-harness/SKILL.md"

# Must support project-local path
assert_contains \
    "includes project-local path" \
    ".claude/skills/popcorn-harness/SKILL.md"

echo ""
echo "--- Error message quality ---"
# Install instruction should use /plugin marketplace add
assert_contains \
    "error message uses marketplace add command" \
    "/plugin marketplace add seilk/popcorn-harness"

# Should NOT have the outdated /plugin install form
assert_not_contains \
    "no outdated /plugin install command" \
    "/plugin install popcorn-harness@popcorn-harness"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
