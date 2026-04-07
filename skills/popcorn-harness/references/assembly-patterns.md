# Harness Assembly Patterns

Reference for SKILL.md Step 3. Load when building execution graphs.

## Execution Graph Patterns

### Pattern A: Full Parallel

All capabilities are independent. Run simultaneously.

```
[capability-A] ─┐
[capability-B] ─┼──► [Synthesis]
[capability-C] ─┘
```

**Use when:** Each capability reads the same inputs (codebase, vault, repo) independently.
**Examples:** security-review + e2e-testing + seo (all read the same project)

### Pattern B: Sequential Pipeline

Each step feeds its output to the next.

```
[capability-A] ──► [capability-B] ──► [capability-C]
```

**Use when:** B requires A's output as its primary input.
**Examples:** research-ops → deployment-patterns (research informs deployment decisions)

### Pattern C: Gather-then-Act (Most Common)

Parallel information gathering, then sequential action.

```
[capability-A] ─┐
[capability-B] ─┼──► [sync point] ──► [capability-C] ──► [capability-D]
[capability-C] ─┘
```

**Use when:** Multiple audit/analysis steps feed into a single action step.
**Examples:** security + tests + seo → deployment → docker

### Pattern D: Fork-Join

One capability fans out to multiple independent follow-ups.

```
                    ┌──► [capability-B]
[capability-A] ─────┤
                    └──► [capability-C]
```

**Use when:** A produces distinct outputs that each need specialized processing.
**Examples:** research-ops → (market-research + obsidian-finance-vault)

## Dependency Detection Rules

Two capabilities are **parallel-safe** when ALL of:
- Neither capability modifies shared files during execution
- Neither capability's output is listed as input in the other's description
- They operate on different domains (security vs. SEO, testing vs. deployment)

Two capabilities are **sequentially dependent** when ANY of:
- Capability B's description mentions needing "prior analysis", "audit results", or "findings"
- Capability A writes files that B reads
- The task description uses "then", "after", "based on results of"

## Capability Role Classification

When assembling the graph, label each capability with its role:

| Role | Description | Typical position |
|------|-------------|------------------|
| `gather` | Reads state, produces findings | Phase 1 (parallel) |
| `analyze` | Interprets gathered data | Phase 1 or 2 |
| `decide` | Makes recommendations from analysis | Phase 2 |
| `act` | Executes changes or produces artifacts | Final phase |
| `verify` | Confirms actions succeeded | After act |

Never put an `act` capability in parallel with a `gather` if they share the same target.

## Parallel Dispatch: Exact Mechanism

### On Claude Code (Agent tool)

```
Spawn simultaneously — do NOT await one before starting another:

  Agent call 1:
    subagent_type: "general-purpose"
    prompt: "[full content of agent-A.md]\n\nTask: [subtask-A description]\n\nContext: [relevant repo/project context]"

  Agent call 2:
    subagent_type: "general-purpose"
    prompt: "[full content of agent-B.md]\n\nTask: [subtask-B description]\n\nContext: [relevant repo/project context]"

Collect BOTH responses before proceeding to next phase.
Do NOT use TeamCreate — that is for agents that must debate each other.
```

### On Hermes / OpenClaw (delegate_task)

```python
delegate_task(tasks=[
  {
    "goal": "[subtask-A full description with all context]",
    "context": "[everything subagent needs — it has NO shared memory]",
    "toolsets": ["terminal", "file"]  # or appropriate toolsets
  },
  {
    "goal": "[subtask-B full description with all context]",
    "context": "[everything subagent needs]",
    "toolsets": ["terminal", "file"]
  }
])
```

Key rule: **subagents have no shared memory.** Pass ALL context explicitly.

## Budget Pruning Strategy

When capability count exceeds 5, prune by this priority:

1. Remove capabilities that overlap in domain (keep the more specific one)
2. Remove capabilities whose description least matches the task's primary goal
3. Remove `verify` role capabilities (can be done manually after)
4. If still > 5: split into two sequential harness runs — present both plans to user

Never silently drop a capability. Always report what was pruned and why.
