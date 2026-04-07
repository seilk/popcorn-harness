---
name: popcorn-harness
description: >-
  Instant on-the-fly harness assembler. Discovers available skills, agents, and
  commands on the current platform, reasons about the optimal combination, and
  executes with progressive disclosure. Works on Claude Code, Hermes, and
  OpenClaw. Trigger on: "popcorn", "assemble harness for", or "use your skills to".
---

# Popcorn Harness

Given a task, pop the right capabilities together and execute — no manual tool selection needed.

**Announce at start:** "🍿 Popping harness for: [task summary]"

**Supporting files in this skill (load on demand):**
- [references/tier-decision-tree.md](references/tier-decision-tree.md) — detailed tier selection logic and edge cases
- [references/assembly-patterns.md](references/assembly-patterns.md) — execution graph patterns and parallel dispatch mechanics
- [scripts/detect-platform.sh](scripts/detect-platform.sh) — deterministic platform detection (outputs JSON)
- [scripts/discover-capabilities.sh](scripts/discover-capabilities.sh) — capability discovery across all sources (outputs JSON)

**Note on SKILL_DIR:** When scripts are referenced below, `SKILL_DIR` refers to the directory containing this SKILL.md. Common locations:
- `~/.claude/plugins/popcorn-harness/skills/popcorn-harness/`
- `~/.claude/skills/popcorn-harness/`
- `~/.hermes/skills/popcorn-harness/`

Set it before running any script: `SKILL_DIR=~/.claude/plugins/popcorn-harness/skills/popcorn-harness`

---

## When to Use

- User says "popcorn", "assemble harness for X", or "use your skills to do X"
- Task spans multiple domains and you want explicit reasoning about capability selection
- User wants transparency into how the execution was composed

**Skip this skill** when a single skill clearly covers the task — invoke it directly.

---

## Step 0 — Detect Platform

Run the detection script first. It outputs JSON.

```bash
bash "$SKILL_DIR/scripts/detect-platform.sh"
# → {"platform":"claude-code","scope":"project","evidence":[...]}
```

**Windows users:** bash scripts require WSL2 or Git Bash. If unavailable, skip the script and use the fallback table directly.

If the script is unavailable (Hermes/OpenClaw context or no bash), use the fallback table:

| Signal | Platform |
|--------|----------|
| `claude` CLI in PATH + `.claude/` dir exists | Claude Code (project) |
| `claude` CLI in PATH, no `.claude/` dir | Claude Code (user) |
| `available_skills` in system prompt, no `claude` CLI | Hermes / Fox |
| Above + `OPENCLAW` env var set | OpenClaw |

**Ambiguous detection → default to Hermes (context-based). Never halt.**

---

## Step 1 — Discover Capabilities

### Claude Code

Run the discovery script:

```bash
bash "$SKILL_DIR/scripts/discover-capabilities.sh" --platform claude-code
# → {"skills":[...],"agents":[...],"commands":[...],"sources":[...],"errors":[...]}
```

Read the JSON output. The `errors` field lists what failed — surface it if critical.

**Zero results protocol:** report "No capabilities found via [sources]. Check installation." and halt. Do not proceed with an empty harness.

### Hermes / Fox / OpenClaw

Capabilities are already present in `available_skills` (injected in system prompt). Extract:
1. All skill names + one-line descriptions from the injected block
2. Categories (the indented structure)
3. Active MCP tools in the current session

**Zero results protocol:** same as above — report and halt.

---

## Step 2 — Choose Tier

Assess task complexity after discovery. For detailed edge cases, load [references/tier-decision-tree.md](references/tier-decision-tree.md).

**Quick reference (exclusive boundaries):**

| Condition | Tier |
|-----------|------|
| Exactly 1 capability, task unambiguous | **Tier 1 — Quick Pop** |
| 2-3 capabilities, OR 1 with mild ambiguity | **Tier 2 — Standard Pop** |
| 4-5 capabilities, OR significant ambiguity | **Tier 3 — Full Pop** |

### Tier 1 — Quick Pop
Announce, execute immediately. No confirmation.
```
🍿 Popping: security-review
[executes]
```

### Tier 2 — Standard Pop
Show plan. Wait for explicit confirmation before executing.
```
🍿 Harness assembled:
  1. research-ops        — gather context
  2. security-review     — audit attack surface
  3. deployment-patterns — generate deploy checklist

Proceed? [y / n / adjust]
```

### Tier 3 — Full Pop
Show full discovery + plan + pruning rationale. Require explicit confirmation.
```
🍿 Discovered (Claude Code):
  Skills:  security-review, e2e-testing, seo, deployment-patterns, docker-patterns
  Agents:  security-engineer
  Commands: /review

Assembled harness (5 of 7):
  Phase 1 (parallel): security-review + e2e-testing + seo
  Phase 2 (sequential): deployment-patterns → docker-patterns
  Pruned: security-engineer (overlaps security-review), /review (redundant)

Proceed? [y / n / adjust]
```

**Mid-execution escalation:** if a capability output reveals new required capabilities, see [references/tier-decision-tree.md](references/tier-decision-tree.md) § Tier Escalation.

### Adjust Flow (when user says "adjust" at Tier 2 or Tier 3)

1. Re-display the current harness as a numbered list
2. Ask: "Which capabilities to add, remove, or reorder? (e.g. 'remove 2, add docker-patterns')"
3. Apply the requested change — validate the result is still within budget (≤5)
4. Re-display the revised harness and ask "Proceed? [y / n / adjust]"
5. Repeat until user confirms with `y` or cancels with `n`

If user says "adjust" but provides no specifics: ask "What would you like to change? You can add, remove, or reorder capabilities."

---

## Step 3 — Assemble Harness

For full graph patterns and parallel dispatch mechanics, load [references/assembly-patterns.md](references/assembly-patterns.md).

**Quick reference:**

1. **Decompose** task into 2-6 independent sub-goals
2. **Map** each sub-goal to a capability — match on description content, not name alone
3. **Graph** execution order: parallel if no shared state, sequential if B needs A's output
4. **Enforce budget:** hard cap of 5 capabilities. If exceeded, prune lowest-relevance and report.

---

## Step 4 — Execute

### Claude Code

- **Skills:** read `SKILL.md` into context via file read tool, then follow its instructions
- **Agents:** spawn via Agent tool (`subagent_type: "general-purpose"`) with agent `.md` as system prompt
- **Parallel:** spawn all Phase 1 agents simultaneously — do NOT await one before starting another
- Full parallel dispatch syntax: see [references/assembly-patterns.md](references/assembly-patterns.md) § Parallel Dispatch

### Hermes / Fox / OpenClaw

- **Skills:** `skill_view(name="<skill-name>")` — load then follow
- **Parallel:** `delegate_task(tasks=[...])` — pass ALL context per subagent (no shared memory)
- **Announce** before each capability: "Running: <skill-name>"

---

## Step 5 — Output

```
--- 🍿 Popcorn Harness: [task summary] ---
Platform: [detected]  |  Tier: [1/2/3] — [Quick/Standard/Full] Pop

[Phase 1]
  <skill>: [findings]
  <skill>: [findings]

[Phase 2]
  <skill>: [findings]

--- Summary ---
  Key findings:  [what matters most across all outputs]
  Action items:  [concrete, specific next steps]
  Skipped:       [any failures or pruned capabilities, with reason]
```

**Optional post-execution review:** spawn [agents/popcorn-critic.md](agents/popcorn-critic.md) with the above output + original task to get a quality verdict.

---

## Rules

1. Detect platform (Step 0) before anything else.
2. Never hardcode skill lists — always discover dynamically.
3. Announce platform and assembled harness at Tier 2+.
4. Zero discovery results → halt and report. Do not hallucinate capabilities.
5. Hard cap: 5 capabilities. Prune explicitly with stated reason.
6. Missing capability → report it, continue with what's available.
7. Capability error → log inline, continue with remaining.
8. Auto-execution without confirmation is only allowed at Tier 1.

---

## Anti-Patterns

- Loading all available skills "just in case" — floods context, degrades output quality
- Selecting capabilities by name-match without reading descriptions
- Running all capabilities sequentially when parallel is safe
- Skipping the Summary block when multiple capabilities ran
- Assuming Claude Code environment inside Hermes or OpenClaw
- Swallowing discovery script errors silently
