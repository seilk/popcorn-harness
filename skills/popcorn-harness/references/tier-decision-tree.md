# Tier Decision Tree

Reference for SKILL.md Step 2. Load this file when you need to resolve an ambiguous tier assignment.

## Primary Decision Flow

```
Start
  │
  ├─ Count capabilities mapped from Step 3b
  │
  ├─ count == 1 AND task is unambiguous?
  │     └─ YES → Tier 1 (Quick Pop)
  │
  ├─ count == 1 AND task has mild ambiguity?
  │     └─ YES → Tier 2 (Standard Pop)
  │
  ├─ count == 2 or 3?
  │     └─ YES → Tier 2 (Standard Pop)
  │
  ├─ count == 4 or 5?
  │     └─ YES → Tier 3 (Full Pop)
  │
  └─ Ambiguity override: any of these → Tier 3
        - Task scope is unclear ("make this better", "fix everything")
        - Two or more capability domains have equal relevance
        - Task mentions a domain with no matching capability (needs reporting)
        - User has previously canceled and is retrying with same prompt
```

## Ambiguity Signals

A task is **unambiguous** when ALL of:
- Exactly one domain is named or strongly implied
- The requested output type is clear (audit, test, deploy, document, etc.)
- No conditionals ("if X then Y") in the task description

A task is **mildly ambiguous** when ANY of:
- Two domains could apply but one is clearly primary
- Output type is implied but not stated
- Task is short (< 5 words) but context is clear

A task is **significantly ambiguous** when ANY of:
- Three or more domains apply equally
- Task scope is open-ended ("review this", "improve this")
- User says "everything", "all of it", "the works"
- No prior context exists for what "this" refers to

## Tier Escalation During Execution

Trigger mid-execution tier escalation when:

| Condition | Action |
|-----------|--------|
| Capability output reveals 1 new required capability | Load silently, log addition |
| Capability output reveals 2-3 new requirements | Pause, report, ask to confirm |
| Capability output reveals 4+ new requirements | Halt, re-run Tier 3 confirmation |
| A capability returns an error AND is the only Phase 1 item | Pause, report, ask how to proceed |
| Budget would exceed 5 with new discoveries | Halt, present pruning options |

## Edge Cases

**Task maps to zero capabilities:**
→ Do not select placeholder capabilities
→ Report: "No matching capabilities found for: [task]"
→ Suggest: install relevant skill, or rephrase task

**Single-word task (e.g. "security"):**
→ Single word with multiple domain interpretations → force Tier 3
→ Ask: "Which aspect of [word]? e.g.: [list 2-3 inferred domains]"
→ Example: "security" → "Network/auth security? Dependency CVE scan? Secret scanning?"
→ Do NOT assume a single interpretation silently

**Large discovery result (200+ skills):**
→ Tier selection still works — use description-match quality, not count
→ Group discovered capabilities by domain before presenting (reduces cognitive load)
→ In Tier 3, show top 10 most-relevant instead of full list; note "X more available"

**Subagent timeout mid-execution:**
→ Log: "[skill-name]: timed out after [N]s"
→ Continue with remaining capabilities
→ Include in Skipped section of output
→ Do NOT re-run the timed-out capability automatically

**0 capabilities remain after pruning:**
→ Do NOT proceed with empty harness
→ Report: "All mapped capabilities were pruned due to budget or overlap. Please narrow the task or specify capabilities directly."
→ Offer to re-run with user-specified capability list

**Task maps to exactly 5 capabilities and all are equally relevant:**
→ Tier 3, present all 5, do not prune without reason
→ Confirm before proceeding (5 is at the budget ceiling)

**User says "quick" or "fast":**
→ Force Tier 1 regardless of capability count
→ Take the single highest-relevance capability
→ Note in output: "Quick mode — used [X] only. Run without 'quick' for full harness."

**User says "full" or "everything":**
→ Force Tier 3 regardless of capability count
→ Show complete discovery, full confirmation flow
