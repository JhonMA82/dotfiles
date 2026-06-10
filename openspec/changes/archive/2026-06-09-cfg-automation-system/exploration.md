## Exploration: cfg-automation-system

### Current State

**Chezmoi source tree**: Initialized (`~/.local/share/chezmoi/.git` exists, on `master` branch) but **completely empty** — zero commits, no config files imported. The previous change "setup-chezmoi-dotfiles" was archived without ever running `chezmoi add`. Seven domain specs define WHAT to track; the automation system needs to be the HOW.

**Machine identity**: Hostname `cachyos-x8664` (not `laptop` as some specs reference). Acer Aspire R3-431T, Celeron 3205U, 3.7 GiB RAM, CachyOS rolling, Niri Wayland.

**Real configs on disk** (all exist and are valid):
| Domain | File(s) | Lines | Templates needed? | Validate command |
|--------|---------|-------|-------------------|-----------------|
| fish | `~/.config/fish/config.fish` | 12 | No (shared) | `fish -n` ✅ works |
| niri | `~/.config/niri/config.kdl` | 279 | Yes (outputs per machine) | `niri validate` ✅ works |
| niri/dms | 8 auto-generated `.kdl` files | varies | EXCLUDED via `.chezmoiignore` | N/A — DMS auto-generates |
| ghostty | `~/.config/ghostty/config` | 51 | Maybe (font size per DPI) | `ghostty +validate-config` |
| alacritty | `~/.config/alacritty/dank-theme.toml` | 31 | No (shared theme) | None (alacritty has no --validate) |
| yazi | `~/.config/yazi/yazi.toml` + keymap, theme | 62 | No (shared) | None (yazi has no --validate) |
| environment.d | `~/.config/environment.d/90-dms.conf` | 2 | No (shared) | None (just env vars) |
| git | `~/.gitconfig` | 0 | YES (per-machine identity) | `git config --list` |

**Skills ecosystem**: 11 indexed user-level skills in `.atl/skill-registry.md`. No project-level skills exist. SDD skills (`sdd-*`) are excluded from the registry. Skill frontmatter pattern: `name`, `description` (one line, trigger words, ≤250 chars), `license`, `metadata.author`, `metadata.version`. Body sections: Activation Contract, Hard Rules, Decision Gates, Execution Steps, Output Contract, References.

**Existing specs** (7 total, defining WHAT): `chezmoi-core`, `shell-config`, `git-config`, `niri-config`, `terminal-config`, `file-manager-config`, `launcher-config`. Each defines requirements and Given/When/Then scenarios for its domain.

### Affected Areas

- `~/.config/opencode/skills/` — new `cfg` orchestrator skill + `cfg-{domain}` skills (7–8 new skill directories)
- `~/.local/share/chezmoi/` — the chezmoi source tree where configs will be stored and committed
- `.chezmoi.yaml.tmpl` — machine data file (NEEDS CREATION — does not exist yet) that skills must read for hostname-aware template evaluation
- `.chezmoiignore` — ignore rules (NEEDS CREATION) that skills must respect and update
- `openspec/specs/` — 7 existing specs serve as domain knowledge; no spec changes needed (they define requirements, not implementation)
- `.atl/skill-registry.md` — must be regenerated after creating new skills
- `/home/juan/misconfig/AGENTS.md` — may need conventions section if skills are project-level
- `openspec/config.yaml` — detects no test runner (`strict_tdd: false`), validation is manual tool-specific commands

### Approaches

#### 1. Approach A: Inline cfg skill with decision table (SIMPLEST)

Single `cfg` skill loaded into the main agent's context. A decision table maps trigger keywords to domain handlers defined inline. No sub-agents, no separate domain skills.

- **Pros**:
  - Single file, zero delegation overhead, no sub-agent context spawning
  - Fits within 3.7 GiB constraint perfectly (no extra processes)
  - Trigger routing is a simple table lookup — no intent parsing complexity
  - Fastest path from user utterance to `chezmoi re-add`
  - One skill to maintain, one SKILL.md to read
- **Cons**:
  - Becomes a monolith as domains grow (fish, niri, ghostty, alacritty, yazi, git, dms = 7 domains minimum)
  - Adding a new domain requires editing the main skill — no clean separation
  - Validation commands per domain clutter the decision table
  - The `cachyos-troubleshoot` skill demonstrates where monolith skills work (574 lines, 13 subsystems) — but that's mostly diagnostic read-only, not config mutation
  - Violates user's explicit desire for "domain-specific skills"
- **Effort**: Low (1 skill, ~200 lines)

#### 2. Approach B: Orchestrator `cfg` + domain skills `cfg-{domain}` (RECOMMENDED)

`cfg` skill acts as orchestrator: parses natural language intent ("change ghostty theme", "add fzf to fish"), identifies domain, and **delegates to a sub-agent** that loads the matching `cfg-{domain}` SKILL.md. Each domain skill knows its chezmoi source paths, template rules, validation commands, and commit conventions.

Architecture:
```
User says "change ghostty font to JetBrains Mono"
    │
    ▼
cfg skill (orchestrator) — loaded in main agent
    │  Parse: domain=ghostty, action=modify, key=font, value="JetBrains Mono"
    │  Route: delegate to cfg-ghostty sub-agent
    ▼
cfg-ghostty sub-agent (loads cfg-ghostty/SKILL.md)
    │  1. Read current chezmoi source: dot_config/ghostty/config
    │  2. Apply change (edit the file, respecting .chezmoi.yaml.tmpl data if templated)
    │  3. Validate: ghostty +validate-config
    │  4. chezmoi re-add + git commit (conventional)
    │  5. Report diff to orchestrator
    ▼
cfg skill reports result to user
```

- **Pros**:
  - **Modular**: each domain is a self-contained skill — add/remove domains without touching orchestrator
  - **Scalable**: follows the exact same pattern as SDD (orchestrator → domain sub-agents)
  - **Domain skills are small** (50–100 lines each): paths, template rules, validation commands, commit format
  - **Validation isolation**: a broken `fish -n` handler doesn't affect `niri validate` logic
  - **Matches user's explicit design request**: "orchestrator skill route to domain-specific skills"
  - **Skill registry integration**: new skills are registered and discoverable
  - Each domain skill can be unit-tested independently (mock the chezmoi source tree in a tempdir)
- **Cons**:
  - ~8 skills to create and maintain (orchestrator + 7 domains)
  - Sub-agent spawning has overhead (~1–3s per delegation, fresh context each time)
  - For simple one-field changes (e.g., "change ghostty font-size"), sub-agent overhead feels heavy
  - Requires the user's agent platform to support sub-agent delegation (opencode Task tool does)
  - Skill registry must be regenerated after creating skills
  - Initially higher setup cost than Approach A
- **Effort**: Medium (8 skills, ~50–100 lines each = ~600 lines total)

#### 3. Approach C: Sub-agents per domain WITHOUT domain skills (HEAVIER)

Instead of domain skills, the orchestrator crafts a detailed prompt per domain and delegates to general-purpose sub-agents. No `cfg-{domain}` SKILL.md files — domain knowledge is embedded in the orchestrator's prompt-building logic.

- **Pros**:
  - No new skill files to create — just one orchestrator skill
  - Can dynamically adjust domain instructions per-request
- **Cons**:
  - Orchestrator becomes a 500+ line skill with embedded domain knowledge for 7+ domains
  - Every domain change requires editing the orchestrator — defeats modularity
  - Sub-agents have no standardized domain instructions; behavior drifts across sessions
  - Harder to test individual domains
  - Breaks the skill-registry pattern: domain knowledge belongs in SKILL.md, not prompt strings
- **Effort**: Medium (1 skill, ~500 lines)

### Recommendation

**Approach B: Orchestrator `cfg` + domain skills `cfg-{domain}`**, for these reasons:

1. **Architecture fits the existing skill ecosystem**: The SDD pipeline already demonstrates orchestrator → domain sub-agent delegation. The `cfg-{domain}` pattern mirrors this exactly, leveraging the same skill-registry, frontmatter conventions, and delegation primitives.

2. **Domain boundaries align with existing specs**: The 7 specs (`shell-config`, `niri-config`, `terminal-config`, `git-config`, `file-manager-config`, `launcher-config`, `chezmoi-core`) map 1:1 to domain skills. Each spec defines WHAT a domain needs; the corresponding `cfg-{domain}` skill implements HOW to change it.

3. **Multi-machine template handling is domain-specific**: Niri needs hostname-conditional output blocks. Git needs per-machine identity. Ghostty may need font-size per DPI. A monolithic skill would need a complex template dispatch table; domain skills handle their own template logic naturally.

4. **Validation is domain-specific and non-uniform**: `fish -n` works anywhere. `niri validate` needs a running compositor context. `ghostty +validate-config` may fail in TTY. Yazi and alacritty have NO validation commands. Each domain skill encapsulates these differences.

5. **Commit granularity**: Each domain change gets its own conventional commit — `cfg-ghostty` commits as `feat(ghostty): change font to JetBrains Mono`, not a vague `feat: update configs`.

**Scope note**: The orchestrator skill (`cfg`) should NOT attempt full NLU (natural language understanding). A simple keyword + pattern match is sufficient for the initial triggers: "change ghostty theme" → domain=ghostty, "add fzf to fish" → domain=fish, "install a niri plugin" → domain=niri. Complex intent parsing can be added later.

### Risks

- **Sub-agent memory overhead**: Each sub-agent spawns a fresh context. On 3.7 GiB, spawning 3+ sub-agents sequentially for a multi-domain request (e.g., "update both fish and niri") could be tight. Mitigation: the orchestrator finishes one domain fully before spawning the next.
- **`niri validate` context requirement**: Validates against the running compositor's state. If Niri is not running (TTY session), validation may fail or produce misleading errors. Mitigation: check `$WAYLAND_DISPLAY` before validating; skip validation with a warning if no compositor is running.
- **`ghostty +validate-config` availability**: Not tested; may require a display server. If unavailable, fall back to syntax review (diff inspection).
- **No chezmoi source files yet**: All domain skills need to handle the "first add" case where the file doesn't exist in the chezmoi source tree. A common `_shared/cfg-common.md` reference file can provide helpers for this.
- **`.chezmoi.yaml.tmpl` doesn't exist**: The machine data file that drives template rendering must be created before any templated configs can be added. This is a prerequisite task, not a risk — but if skipped, template-based skills (niri, git) will fail.
- **Hostname mismatch between specs and reality**: Specs reference "laptop" and "main-pc"; the real hostname is `cachyos-x8664`. Skills must either normalize hostnames or use a mapping in `.chezmoi.yaml.tmpl`. This is a design decision for the spec phase.
- **DMS auto-generation**: DMS files (`~/.config/niri/dms/*.kdl`) are already in `.chezmoiignore` design. Skills must NOT accidentally track them. The `outputs.kdl` file is currently empty — DMS may populate it after a theme change, so ignore rules must be robust.
- **Skill registry drift**: Every new `cfg-{domain}` skill requires regenerating `.atl/skill-registry.md`. The orchestrator must ensure the registry is updated after skill creation.

### Ready for Proposal

**Yes.** The exploration provides:
- Full inventory of current configs, their sizes, and validation capabilities
- Confirmed that chezmoi is initialized but empty (source tree has only `.git`, no configs imported)
- Hostname discrepancy identified (`cachyos-x8664` vs spec's "laptop")
- Clear approach comparison with tradeoffs
- Recommended architecture (Approach B) aligning with user's explicit design request and existing SDD patterns
- Identified risks and mitigations

The next phase (`sdd-propose`) should scope the 8 skills (orchestrator + 7 domains), define the `_shared/cfg-common.md` reference, and decide the multi-machine hostname normalization strategy.
