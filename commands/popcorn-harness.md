---
name: popcorn-harness
description: "Instant harness assembler — discovers available skills, agents, and commands, pops them together, and executes your task. Usage: /popcorn-harness <task description>"
---

This command is Claude Code only. On Hermes/OpenClaw, use: `popcorn — <task>`

Load the popcorn-harness skill by reading the first file that exists from these paths:
1. `~/.claude/plugins/marketplaces/popcorn-harness/skills/popcorn-harness/SKILL.md`
2. `~/.claude/plugins/popcorn-harness/skills/popcorn-harness/SKILL.md`
3. `~/.claude/skills/popcorn-harness/SKILL.md`
4. `.claude/skills/popcorn-harness/SKILL.md`

Then follow the skill's instructions with this task: $ARGUMENTS

If the popcorn-harness skill is not found at any path, respond with:
"popcorn-harness skill not found. Install with:
/plugin marketplace add seilk/popcorn-harness"
