---
name: popcorn-harness
description: >-
  Instant on-the-fly harness assembler. Given any task, discovers available
  skills, agents, and commands across the current platform, reasons about the
  best combination, and executes immediately. Works seamlessly across Claude
  Code, Hermes, and OpenClaw. Trigger on: "popcorn", "assemble harness for",
  "use available skills to", or any task where the user wants the agent to
  self-compose its capabilities rather than manually selecting tools.
origin: community
version: 0.1.0
---

# Popcorn Harness

Given a task, pop the right capabilities together and execute — no manual tool selection needed.

Inspired by ECC's `team-builder` (agent dispatch) and `agent-sort` (evidence-first classification). Popcorn Harness extends those ideas to skills, agents, and commands simultaneously, with progressive disclosure and cross-platform support.

---

## When to Use

- User says "popcorn", "assemble harness for X", or "use your skills to do X"
- Task touches multiple domains (e.g., security + testing + deployment)
- You're unsure which skill combination is optimal and want to reason explicitly
- User wants transparency into how you composed the execution

**Do not use** when a single skill or tool clearly covers the task — just invoke that directly.

---

## Progressive Disclosure Tiers

Assess task complexity before acting. Choose the tier that matches:

### Tier 1 — Quick Pop
**When:** Task is clear, maps to 1-2 capabilities, no ambiguity.
**Behavior:** Silently select capabilities, announce briefly, execute.
```
Popping: security-review + e2e-testing
[executes immediately]
```
No plan display, no confirmation needed.

### Tier 2 — Standard Pop
**When:** Task spans 2-4 capabilities or has mild ambiguity.
**Behavior:** Show assembled harness, pause briefly for correction, then execute.
```
Harness assembled:
  1. research-ops     — gather context
  2. security-review  — audit attack surface
  3. deployment-patterns — generate deploy checklist

Executing in 3s... (say "stop" to adjust)
[executes]
```

### Tier 3 — Full Pop
**When:** Task is complex, spans 5+ capabilities, or is ambiguous.
**Behavior:** Full discovery display + explicit confirmation before execution.
```
Task: "prepare this app for production"

Discovered capabilities:
  Skills:  security-review, e2e-testing, seo, deployment-patterns, docker-patterns
  Agents:  security-engineer (if Claude Code)
  Commands: /review, /deploy (if Claude Code)

Proposed harness:
  Phase 1 (parallel): security-review + e2e-testing + seo
  Phase 2 (sequential): deployment-patterns → docker-patterns

Proceed? [y/n/adjust]
```

Tier escalates automatically if discovery reveals unexpected complexity.

---

## Platform Detection

Run this check at the start of every invocation. The platform determines the discovery strategy.

```bash
# Detect Claude Code
which claude > /dev/null 2>&1 && echo "claude-code" || echo "not-claude-code"
ls .claude/ > /dev/null 2>&1 && echo "project-claude" || true
```

| Signal | Platform |
|--------|----------|
| `claude` CLI available + `.claude/` exists | Claude Code (project) |
| `claude` CLI available, no `.claude/` | Claude Code (user-level) |
| `available_skills` injected in system prompt, no `claude` CLI | Hermes / Fox |
| `available_skills` injected + OpenClaw context | OpenClaw |

---

## Capability Discovery by Platform

### Claude Code

Run all three in parallel:

```bash
# 1. Agents
claude agents 2>/dev/null

# 2. Skills (ECC external_dirs + local)
ls ~/.claude/plugins/marketplaces/ecc/skills/ 2>/dev/null
ls .claude/skills/ 2>/dev/null

# 3. Commands
ls ~/.claude/commands/ 2>/dev/null
ls .claude/commands/ 2>/dev/null
```

Parse agents output:
- `plugin-name:agent-name` → domain = plugin-name
- bare name → read from `~/.claude/agents/` or `./agents/`

Priority: user agents > plugin agents > built-in agents (skip built-ins unless requested)

### Hermes / Fox / OpenClaw

Available capabilities are already injected as `available_skills` in the system prompt.
No CLI discovery needed. Read from context directly.

Extract skill names and descriptions from the injected list. Group by category if available.
MCP tools in the current session are also available capabilities — include them.

---

## Harness Assembly Logic

After discovery, map capabilities to the task using this reasoning model:

### Step 1: Task Decomposition
Break the task into sub-goals (2-6 typically). Each sub-goal should be independently addressable.

### Step 2: Capability Mapping
For each sub-goal, find the best matching capability:
- Prefer specific skills over generic ones
- Prefer skills with descriptions that explicitly cover the sub-goal
- On Claude Code: agents for persona-driven work, skills for procedural how-to, commands for workflow entry points
- On Hermes: skills for procedural guidance, MCP tools for live data/actions

### Step 3: Execution Graph
Decide ordering:
- **Parallel**: sub-goals with no shared state or output dependency
- **Sequential**: sub-goal B depends on output of sub-goal A
- **Hybrid**: parallel phases separated by sync points

```
Example:
  [security-review]──┐
                     ├──► [deployment-checklist]──► [execute-deploy]
  [e2e-testing]──────┘
```

### Step 4: Context Budget Check
Count selected capabilities. If > 5, flag and ask user to narrow scope.
Loading too many skills simultaneously degrades quality (per ECC agent-harness-construction pattern).

---

## Execution

### On Claude Code

Load each skill via the skill loading mechanism, then dispatch:
- Skills: load SKILL.md content into context
- Agents: spawn via subagent with agent file as system prompt
- Parallel execution: use parallel Agent tool calls (same pattern as team-builder)

### On Hermes / OpenClaw

Load each skill via `skill_view(name)`, then follow its instructions.
For parallel work, use `delegate_task` with isolated subagent contexts.
Announce which skill is active at each phase.

---

## Output Format

Always end with a synthesis section regardless of tier:

```
--- Popcorn Harness Results ---

[Phase 1]
  security-review: [summary]
  e2e-testing: [summary]

[Phase 2]
  deployment-patterns: [checklist]

--- Synthesis ---
  Agreements: [...]
  Conflicts: [...]
  Next steps: [...]
```

For Tier 1, synthesis can be a single paragraph.

---

## Rules

- Never hardcode skill lists. Always discover dynamically.
- Announce the platform detected and capabilities found (Tier 2+).
- If a required capability is missing, say so explicitly rather than silently degrading.
- Max 5 capabilities per harness. Enforce at assembly time.
- Escalate tier if task complexity grows during execution.
- On error in one capability, note it inline and continue with remaining.

---

## Anti-Patterns

- Loading all available skills "just in case" — this floods context and reduces quality
- Picking skills by name-matching alone without reading descriptions
- Running everything sequentially when parallel is possible
- Skipping synthesis when multiple capabilities were used
- Assuming Claude Code is available when running inside Hermes

---

## Examples

### Hermes / Fox

```
User: popcorn — review my portfolio vault and suggest improvements

Fox detects: Hermes platform
Discovers: obsidian-finance-vault, tossctl, market-research (from available_skills)
Tier: 2 — Standard Pop

Harness assembled:
  1. obsidian-finance-vault — read current vault structure
  2. tossctl               — fetch live portfolio data
  3. market-research       — benchmark against market context
Executing...
```

### Claude Code

```
User: popcorn — get this Next.js app ready for production

Detects: Claude Code (project), .claude/ found
Discovers:
  Skills: security-review, e2e-testing, seo, deployment-patterns
  Agents: security-engineer
  Commands: /review
Tier: 3 — Full Pop (5 capabilities)

Proposed harness:
  Phase 1 (parallel): security-engineer + e2e-testing + seo
  Phase 2: deployment-patterns
Proceed?
```

---

## References

- ECC `team-builder` — agent discovery and parallel dispatch pattern
- ECC `agent-sort` — evidence-first capability classification
- ECC `agent-harness-construction` — action space design, context budget rules
- Superpowers `brainstorming` — progressive disclosure and tier escalation
- Superpowers `writing-plans` — phase decomposition and synthesis format
