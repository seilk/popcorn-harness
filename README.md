# popcorn-harness

> Instant on-the-fly harness assembler for Claude Code, Hermes, and OpenClaw.

Given a task, popcorn-harness discovers your available skills, agents, and
commands — then pops them together into an execution harness immediately.
No manual tool selection. No guessing.

```
User: popcorn — prep this app for production

Harness assembled:
  Phase 1 (parallel): security-review + e2e-testing + seo
  Phase 2: deployment-patterns
Executing...
```

---

## How It Works

1. Detects the current platform (Claude Code / Hermes / OpenClaw)
2. Discovers available capabilities for that platform
3. Applies progressive disclosure based on task complexity:
   - **Quick Pop** — 1-2 skills, execute silently
   - **Standard Pop** — 2-4 skills, show plan briefly
   - **Full Pop** — 5+ skills or ambiguous task, full confirmation
4. Assembles a parallel/sequential execution graph
5. Executes and synthesizes results

---

## Usage

### Claude Code
```
/popcorn <task description>
```

### Hermes / Fox
```
popcorn — <task description>
```
or just describe your task and say "use available skills"

### OpenClaw
Same as Hermes — the skill is auto-loaded from external_dirs.

---

## Platform Support

| Platform    | Discovery Method                          |
|-------------|-------------------------------------------|
| Claude Code | `claude agents` + skills dirs + commands  |
| Hermes/Fox  | `available_skills` from system prompt     |
| OpenClaw    | `available_skills` from system prompt     |

---

## Installation

### Claude Code (via plugin)
```bash
# Coming soon: claude plugin install popcorn-harness
# For now, copy to ~/.claude/plugins/
cp -r popcorn-harness ~/.claude/plugins/
```

### Hermes / OpenClaw
```bash
cp -r skills/popcorn-harness ~/.hermes/skills/
```

---

## References

Built on patterns from:
- [ECC](https://github.com/everything-claude-code/ecc) — team-builder, agent-sort, agent-harness-construction
- [Superpowers](https://github.com/anthropics/claude-plugins-official) — brainstorming, writing-plans
