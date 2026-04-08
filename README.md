     1|# popcorn-harness
     2|
     3|> Instant on-the-fly harness assembler for Claude Code, Hermes, and OpenClaw.
     4|
     5|Given a task, `popcorn-harness` discovers your available skills, agents, and commands — then pops them together into an optimized execution harness. No manual tool selection. No guessing. Works across platforms.
     6|
     7|```
     8|User: popcorn — prep this Next.js app for production
     9|
    10|Platform detected: Claude Code (project)
    11|Tier: 3 — Full Pop
    12|
    13|Assembled harness:
    14|  Phase 1 (parallel): security-review + e2e-testing + seo
    15|  Phase 2 (sequential): deployment-patterns → docker-patterns
    16|
    17|Proceed? [y/n/adjust]
    18|```
    19|
    20|---
    21|
    22|## How It Works
    23|
    24|1. **Detects platform** — Claude Code, Hermes, or OpenClaw
    25|2. **Discovers capabilities** — skills, agents, and commands available in your environment
    26|3. **Applies progressive disclosure** based on task complexity:
    27|   - **Quick Pop** — 1 capability, executes immediately
    28|   - **Standard Pop** — 2-3 capabilities, shows plan, confirms
    29|   - **Full Pop** — 4-5 capabilities or ambiguous task, full confirmation flow
    30|4. **Assembles execution graph** — parallel phases where possible, sequential where required
    31|5. **Executes and synthesizes** — structured output with key findings and action items
    32|
    33|---
    34|
    35|## Platform Support
    36|
    37|| Platform | How capabilities are discovered |
    38||----------|--------------------------------|
    39|| Claude Code | `claude agents` + skill dirs + command dirs |
    40|| Hermes | `available_skills` injected in system prompt |
    41|| OpenClaw | `available_skills` injected in system prompt |
    42|
    43|---
    44|
    45|## Installation
    46|
    47|### Claude Code (plugin)
    48|
    49|```bash
    50|# Clone the repo
    51|git clone https://github.com/seilk/popcorn-harness ~/.claude/plugins/popcorn-harness
    52|
    53|# Or copy manually
    54|cp -r popcorn-harness ~/.claude/plugins/
    55|```
    56|
    57|Then restart Claude Code. The `/popcorn` command and `popcorn-orchestrator` agent will be available automatically.
    58|
    59|### Hermes
    60|
    61|```bash
    62|cp -r skills/popcorn-harness ~/.hermes/skills/
    63|```
    64|
    65|The skill will appear in `available_skills` on the next session.
    66|
    67|### OpenClaw
    68|
    69|Add the skills directory to `external_dirs` in your Hermes config:
    70|
    71|```yaml
    72|# ~/.hermes/config.yaml
    73|skills:
    74|  external_dirs:
    75|    - /path/to/popcorn-harness/skills
    76|```
    77|
    78|---
    79|
    80|## Usage
    81|
    82|### Claude Code
    83|
    84|```
    85|/popcorn <task description>
    86|```
    87|
    88|Or invoke the orchestrator agent directly from any Claude Code session:
    89|
    90|```
    91|Use popcorn-orchestrator to: <task description>
    92|```
    93|
    94|### Hermes
    95|
    96|```
    97|popcorn — <task description>
    98|```
    99|
   100|Or just describe your task and say "use available skills":
   101|
   102|```
   103|use your available skills to review my codebase before deployment
   104|```
   105|
   106|### OpenClaw
   107|
   108|Same as Hermes — the skill is automatically available once installed.
   109|
   110|---
   111|
   112|## Examples
   113|
   114|**Single-domain task (Tier 1 — Quick Pop):**
   115|```
   116|popcorn — run a security review on this repo
   117|→ Pops: security-review (1 capability, executes immediately)
   118|```
   119|
   120|**Multi-domain task (Tier 2 — Standard Pop):**
   121|```
   122|popcorn — audit my portfolio and suggest rebalancing
   123|→ Pops: obsidian-finance-vault + tossctl + market-research
   124|→ Shows plan, waits for confirmation
   125|```
   126|
   127|**Complex task (Tier 3 — Full Pop):**
   128|```
   129|popcorn — get this app production-ready
   130|→ Pops: security-review + e2e-testing + seo + deployment-patterns + docker-patterns
   131|→ Shows full discovery, proposes phased execution, requires explicit confirmation
   132|```
   133|
   134|---
   135|
   136|## Design Principles
   137|
   138|- **Progressive disclosure** — reveal complexity only when needed
   139|- **Evidence-based selection** — capabilities chosen by description match, not name alone
   140|- **Platform-agnostic** — same skill file works on Claude Code, Hermes, and OpenClaw
   141|- **Budget-bounded** — hard cap of 5 capabilities per harness run to preserve quality
   142|- **Fail-transparent** — missing capabilities are reported, not silently skipped
   143|
   144|---
   145|
   146|## Compatibility
   147|
   148|| Component | Minimum version |
   149||-----------|----------------|
   150|| Claude Code | Latest (claude CLI with agent support) |
   151|| Hermes | Any version with `available_skills` injection |
   152|| OpenClaw | Any version with `external_dirs` support |
   153|| ECC (optional) | Any version — enhances discovery if installed |
   154|
   155|---
   156|
   157|## Troubleshooting
   158|
   159|**"No capabilities found"**
   160|- Claude Code: run `claude agents` manually to verify agent discovery works
   161|- Hermes: check `skills.external_dirs` in `~/.hermes/config.yaml`
   162|- OpenClaw: verify the skills path is correctly set in config
   163|
   164|**"Platform detected incorrectly"**
   165|- Set `OPENCLAW=1` environment variable to force OpenClaw detection
   166|- Ensure `claude` CLI is in PATH for Claude Code detection
   167|
   168|**"Harness produced poor results"**
   169|- Try Tier 3: describe the task more broadly to trigger full discovery
   170|- Manually specify capabilities: "popcorn — use security-review and e2e-testing to..."
   171|
   172|---
   173|
   174|## Contributing
   175|
   176|Inspired by and built on patterns from:
   177|- [ECC (Everything Claude Code)](https://github.com/anthropics/everything-claude-code) — `team-builder`, `agent-sort`, `agent-harness-construction`
   178|- [Superpowers plugin](https://github.com/anthropics/claude-plugins-official) — `brainstorming`, `writing-plans`
   179|
   180|PRs welcome. Please include examples for any new platform support.
   181|
   182|---
   183|
   184|## License
   185|
   186|MIT
   187|