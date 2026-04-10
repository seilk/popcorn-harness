# Project Instructions

## What This Is

Popcorn Harness is a cross-platform Claude Code plugin (also works on Hermes and OpenClaw). It dynamically discovers available skills, agents, and commands, then assembles them into an execution harness for any task. No compiled code — all logic is in structured markdown files interpreted by AI agents.

## Tech Stack

- **Bash 3.x+** scripts for platform detection and capability discovery (macOS compatible, not POSIX sh, no jq)
- **Markdown** skill/agent/command definitions (the "code" of this project)
- **Claude Code plugin system** via `.claude-plugin/plugin.json`

## Project Structure

```
skills/popcorn-harness/SKILL.md    Core orchestration logic (5-step workflow)
skills/popcorn-harness/references/ Tier decision tree + assembly patterns (loaded on demand)
skills/popcorn-harness/scripts/    detect-platform.sh, discover-capabilities.sh
agents/                            popcorn-orchestrator.md, popcorn-critic.md
commands/popcorn.md                /popcorn slash command entrypoint
.claude-plugin/                    Plugin manifest + marketplace metadata
hooks/hooks.json                   Session start context injection
GEMINI.md                          Gemini CLI entrypoint (@ reference)
gemini-extension.json              Gemini extension manifest
assets/banner.svg                  README banner
```

## Conventions

- File/directory names: kebab-case
- Bash scripts must work on bash 3.x+ (no associative arrays, no jq, not POSIX sh)
- JSON output built via string concatenation in bash
- Git commits: conventional commits (feat, fix, docs, chore)
- Version: semver, kept in sync across `package.json`, `.claude-plugin/plugin.json`, and `gemini-extension.json`
- Hard cap of 5 capabilities per harness run

## Testing

- `bash skills/popcorn-harness/scripts/detect-platform.sh` — should output valid JSON
- `bash skills/popcorn-harness/scripts/discover-capabilities.sh --platform claude-code` — should output valid JSON
- `claude --plugin-dir .` — load plugin locally and test `/popcorn <task>`

## Key Design Decisions

- No JavaScript/TypeScript runtime — markdown-as-code pattern
- Progressive disclosure: Tier 1 (auto-execute), Tier 2 (confirm), Tier 3 (full discovery + confirm)
- Platform detection defaults to Hermes when ambiguous — Hermes is the most permissive platform and least likely to block capability discovery, so it is the safest fallback. Never halts.
- Capability selection is description-based, not name-based
- Subagents have no shared memory — all context must be passed explicitly
- OpenClaw support is runtime-only (via detect-platform.sh env var check), not manifest-declared
