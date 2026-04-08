<p align="center">
  <img src="assets/banner.svg" alt="popcorn-harness banner" width="100%">
</p>

# popcorn-harness

> Instant on-the-fly harness assembler for Claude Code, Hermes, and OpenClaw.

Given a task, `popcorn-harness` discovers your available skills, agents, and commands — then pops them together into an optimized execution harness. No manual tool selection. No guessing. Works across platforms.

```
User: popcorn — prep this Next.js app for production

Platform detected: Claude Code (project)
Tier: 3 — Full Pop

Assembled harness:
  Phase 1 (parallel): security-review + e2e-testing + seo
  Phase 2 (sequential): deployment-patterns → docker-patterns

Proceed? [y/n/adjust]
```

---

## How It Works

1. **Detects platform** — Claude Code, Hermes, or OpenClaw
2. **Discovers capabilities** — skills, agents, and commands available in your environment
3. **Applies progressive disclosure** based on task complexity:
   - **Quick Pop** — 1 capability, executes immediately
   - **Standard Pop** — 2-3 capabilities, shows plan, confirms
   - **Full Pop** — 4-5 capabilities or ambiguous task, full confirmation flow
4. **Assembles execution graph** — parallel phases where possible, sequential where required
5. **Executes and synthesizes** — structured output with key findings and action items

---

## Platform Support

| Platform | How capabilities are discovered |
|----------|--------------------------------|
| Claude Code | `claude agents` + skill dirs + command dirs |
| Hermes | `available_skills` injected in system prompt |
| OpenClaw | `available_skills` injected in system prompt |

---

## Installation

### Claude Code (plugin)

```bash
# Clone the repo
git clone https://github.com/seilk/popcorn-harness ~/.claude/plugins/popcorn-harness

# Or copy manually
cp -r popcorn-harness ~/.claude/plugins/
```

Then restart Claude Code. The `/popcorn` command and `popcorn-orchestrator` agent will be available automatically.

### Hermes

```bash
cp -r skills/popcorn-harness ~/.hermes/skills/
```

The skill will appear in `available_skills` on the next session.

### OpenClaw

Add the skills directory to `external_dirs` in your Hermes config:

```yaml
# ~/.hermes/config.yaml
skills:
  external_dirs:
    - /path/to/popcorn-harness/skills
```

---

## Usage

### Claude Code

```
/popcorn <task description>
```

Or invoke the orchestrator agent directly from any Claude Code session:

```
Use popcorn-orchestrator to: <task description>
```

### Hermes

```
popcorn — <task description>
```

Or just describe your task and say "use available skills":

```
use your available skills to review my codebase before deployment
```

### OpenClaw

Same as Hermes — the skill is automatically available once installed.

---

## Examples

**Single-domain task (Tier 1 — Quick Pop):**
```
popcorn — run a security review on this repo
→ Pops: security-review (1 capability, executes immediately)
```

**Multi-domain task (Tier 2 — Standard Pop):**
```
popcorn — audit my portfolio and suggest rebalancing
→ Pops: obsidian-finance-vault + tossctl + market-research
→ Shows plan, waits for confirmation
```

**Complex task (Tier 3 — Full Pop):**
```
popcorn — get this app production-ready
→ Pops: security-review + e2e-testing + seo + deployment-patterns + docker-patterns
→ Shows full discovery, proposes phased execution, requires explicit confirmation
```

---

## Design Principles

- **Progressive disclosure** — reveal complexity only when needed
- **Evidence-based selection** — capabilities chosen by description match, not name alone
- **Platform-agnostic** — same skill file works on Claude Code, Hermes, and OpenClaw
- **Budget-bounded** — hard cap of 5 capabilities per harness run to preserve quality
- **Fail-transparent** — missing capabilities are reported, not silently skipped

---

## Compatibility

| Component | Minimum version |
|-----------|----------------|
| Claude Code | Latest (claude CLI with agent support) |
| Hermes | Any version with `available_skills` injection |
| OpenClaw | Any version with `external_dirs` support |
| ECC (optional) | Any version — enhances discovery if installed |

---

## Troubleshooting

**"No capabilities found"**
- Claude Code: run `claude agents` manually to verify agent discovery works
- Hermes: check `skills.external_dirs` in `~/.hermes/config.yaml`
- OpenClaw: verify the skills path is correctly set in config

**"Platform detected incorrectly"**
- Set `OPENCLAW=1` environment variable to force OpenClaw detection
- Ensure `claude` CLI is in PATH for Claude Code detection

**"Harness produced poor results"**
- Try Tier 3: describe the task more broadly to trigger full discovery
- Manually specify capabilities: "popcorn — use security-review and e2e-testing to..."

---

## Contributing

Inspired by and built on patterns from:
- [ECC (Everything Claude Code)](https://github.com/anthropics/everything-claude-code) — `team-builder`, `agent-sort`, `agent-harness-construction`
- [Superpowers plugin](https://github.com/anthropics/claude-plugins-official) — `brainstorming`, `writing-plans`

PRs welcome. Please include examples for any new platform support.

---

## License

MIT
